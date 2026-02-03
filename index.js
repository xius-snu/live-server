require('dotenv').config();
const fastify = require('fastify')({ logger: true });
fastify.register(require('@fastify/websocket'));
const fs = require('fs');
const path = require('path');
const EventEmitter = require('events');
const Redis = require('ioredis');
const { Pool } = require('pg');

// CONNECTION
const REDIS_URL = process.env.REDIS_URL;
const DATABASE_URL = process.env.DATABASE_URL;

// Store Configuration
let useRedis = false;
let redis = null;
let subRedis = null;
const localStore = {
    counters: {}, // { lobbyId: number }
    emitter: new EventEmitter()
};

// 1. Setup Postgres (Reliable, for Users)
const pool = new Pool({
    connectionString: DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// 2. Setup Redis (Best Effort, for Counters)
// We attempt to connect. If it's a Render Internal URL running locally, it will fail.
// We'll catch that failure and strictly use local memory storage for counters.
if (REDIS_URL) {
    // Check if we are trying to access a Render internal URL from localhost
    const isRenderInternal = REDIS_URL.includes('render.com') && !process.env.RENDER;

    if (isRenderInternal) {
        console.log('⚠️  Detected Render Internal Redis URL while running locally.');
        console.log('⚠️  Switching to IN-MEMORY storage for counters/lobbies.');
        useRedis = false;
    } else {
        redis = new Redis(REDIS_URL, {
            tls: { rejectUnauthorized: false },
            lazyConnect: true,
            retryStrategy: (times) => {
                if (times > 3) {
                    console.log('❌ Redis connection failed too many times. Disabling Redis.');
                    useRedis = false;
                    return null; // Stop retrying
                }
                return Math.min(times * 100, 2000);
            }
        });

        subRedis = new Redis(REDIS_URL, {
            tls: { rejectUnauthorized: false },
            lazyConnect: true
        });

        redis.connect().then(() => {
            console.log('✅ Redis Connected');
            useRedis = true;
        }).catch(err => {
            console.log('⚠️ Redis Connection Failed (Using In-Memory):', err.message);
            useRedis = false;
        });
    }
}

// HELPER: Counter Abstraction
async function getLobbyValue(id) {
    if (useRedis) {
        const val = await redis.get(`lobby:${id}`);
        return val ? parseInt(val, 10) : 0;
    }
    return localStore.counters[id] || 0;
}

async function updateLobbyValue(id, delta) {
    let newVal;
    if (useRedis) {
        if (delta > 0) newVal = await redis.incr(`lobby:${id}`);
        else newVal = await redis.decr(`lobby:${id}`);
        return newVal;
    }
    // Local
    if (!localStore.counters[id]) localStore.counters[id] = 0;
    localStore.counters[id] += delta;
    return localStore.counters[id];
}

async function publishUpdate(lobbyId, val, count, userLists = null) {
    const payload = JSON.stringify({
        id: lobbyId,
        val,
        type: 'update',
        // If we have lists passed in (from Memory flow), use them. 
        // If Redis flow, the listener rebuilds them from the 'lobbies' object.
        ...userLists
    });

    if (useRedis) {
        await redis.publish('lobby-updates', payload);
    } else {
        localStore.emitter.emit('lobby-updates', payload);
    }
}


const lobbies = {};

fastify.register(async function (fastify) {

    // Initialize DB tables
    await pool.query(`
        CREATE TABLE IF NOT EXISTS users (
            user_id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            friend_code TEXT UNIQUE,
            affinity_tier INTEGER DEFAULT 1,
            profile_shape TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS inventory (
            id SERIAL PRIMARY KEY,
            user_id TEXT NOT NULL REFERENCES users(user_id),
            shape_type TEXT NOT NULL,
            rarity TEXT NOT NULL,
            pending_trade_id TEXT,
            acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS friends (
            id SERIAL PRIMARY KEY,
            user_id_1 TEXT NOT NULL REFERENCES users(user_id),
            user_id_2 TEXT NOT NULL REFERENCES users(user_id),
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id_1, user_id_2)
        );
        CREATE TABLE IF NOT EXISTS trade_requests (
            id TEXT PRIMARY KEY,
            from_user_id TEXT NOT NULL REFERENCES users(user_id),
            to_user_id TEXT NOT NULL REFERENCES users(user_id),
            offer_items JSONB NOT NULL,
            request_items JSONB NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP + INTERVAL '7 days'
        );
    `);

    // Add missing columns to existing tables (safe to run multiple times)
    try {
        await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS friend_code TEXT UNIQUE`);
        await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS affinity_tier INTEGER DEFAULT 1`);
        await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_shape TEXT`);
        await pool.query(`ALTER TABLE inventory ADD COLUMN IF NOT EXISTS pending_trade_id TEXT`);
        console.log('✅ Schema migration complete');
    } catch (e) {
        console.log('Schema migration note:', e.message);
    }

    // User API
    fastify.post('/api/user', async (req, reply) => {
        console.log('👉 API Hit: POST /api/user', req.body); // LOG REQUEST
        const { userId, username } = req.body;
        if (!userId || !username) {
            console.log('❌ Missing Data');
            return reply.code(400).send({ error: 'Missing userId or username' });
        }

        // Upsert user
        try {
            console.log('🔄 Attempting DB Insert for:', userId, username);
            await pool.query(`
                INSERT INTO users (user_id, username)
                VALUES ($1, $2)
                ON CONFLICT (user_id) DO UPDATE SET username = $2
            `, [userId, username]);
            console.log('✅ DB Insert Success');
            return { success: true, username };
        } catch (e) {
            console.error('❌ DB Error:', e.message);
            fastify.log.error('DB User Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    fastify.get('/api/user/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query('SELECT username FROM users WHERE user_id = $1', [userId]);
            return { username: res.rows.length > 0 ? res.rows[0].username : null };
        } catch (e) {
            fastify.log.error('DB Get Error: ' + e.message);
            return { username: null };
        }
    });

    // Inventory API
    fastify.post('/api/inventory/add', async (req, reply) => {
        const { userId, shapeType, rarity } = req.body;
        if (!userId || !shapeType || !rarity) {
            return reply.code(400).send({ error: 'Missing data' });
        }
        try {
            await pool.query(
                'INSERT INTO inventory (user_id, shape_type, rarity) VALUES ($1, $2, $3)',
                [userId, shapeType, rarity]
            );
            return { success: true };
        } catch (e) {
            fastify.log.error('Inventory Add Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    fastify.get('/api/inventory/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query(
                'SELECT id, shape_type, rarity, pending_trade_id, acquired_at FROM inventory WHERE user_id = $1 ORDER BY acquired_at DESC',
                [userId]
            );
            return { inventory: res.rows };
        } catch (e) {
            fastify.log.error('Inventory Get Error: ' + e.message);
            return { inventory: [] };
        }
    });

    // Clear inventory (debug)
    fastify.delete('/api/inventory/clear/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            await pool.query('DELETE FROM inventory WHERE user_id = $1', [userId]);
            return { success: true };
        } catch (e) {
            fastify.log.error('Clear Inventory Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    // Public inventory (for trading - excludes pending items)
    fastify.get('/api/inventory/public/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query(
                'SELECT id, shape_type, rarity FROM inventory WHERE user_id = $1 AND pending_trade_id IS NULL ORDER BY acquired_at DESC',
                [userId]
            );
            return { inventory: res.rows };
        } catch (e) {
            fastify.log.error('Public Inventory Get Error: ' + e.message);
            return { inventory: [] };
        }
    });

    // ============================================
    // USER EXTENSIONS (Friend Code, Profile)
    // ============================================

    fastify.post('/api/user/friend-code', async (req, reply) => {
        const { userId, friendCode } = req.body;
        if (!userId || !friendCode) {
            return reply.code(400).send({ error: 'Missing data' });
        }
        try {
            await pool.query(
                'UPDATE users SET friend_code = $2 WHERE user_id = $1',
                [userId, friendCode]
            );
            return { success: true };
        } catch (e) {
            fastify.log.error('Friend Code Update Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    fastify.get('/api/user/by-code/:code', async (req, reply) => {
        const { code } = req.params;
        try {
            const res = await pool.query(
                'SELECT user_id, username, profile_shape FROM users WHERE friend_code = $1',
                [code.toUpperCase()]
            );
            if (res.rows.length === 0) {
                return reply.code(404).send({ error: 'User not found' });
            }
            return res.rows[0];
        } catch (e) {
            fastify.log.error('User by Code Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    // ============================================
    // FRIENDS API
    // ============================================

    // Get friends list
    fastify.get('/api/friends/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query(`
                SELECT
                    u.user_id, u.username, u.profile_shape, u.friend_code,
                    f.status, f.created_at
                FROM friends f
                JOIN users u ON (
                    (f.user_id_1 = $1 AND f.user_id_2 = u.user_id) OR
                    (f.user_id_2 = $1 AND f.user_id_1 = u.user_id)
                )
                WHERE (f.user_id_1 = $1 OR f.user_id_2 = $1) AND f.status = 'accepted'
                ORDER BY f.created_at DESC
            `, [userId]);
            return { friends: res.rows };
        } catch (e) {
            fastify.log.error('Get Friends Error: ' + e.message);
            return { friends: [] };
        }
    });

    // Get pending friend requests
    fastify.get('/api/friends/requests/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query(`
                SELECT
                    f.id, f.user_id_1 as from_user_id,
                    u.username as from_username, u.profile_shape as from_profile_shape,
                    f.created_at
                FROM friends f
                JOIN users u ON f.user_id_1 = u.user_id
                WHERE f.user_id_2 = $1 AND f.status = 'pending'
                ORDER BY f.created_at DESC
            `, [userId]);
            return { requests: res.rows };
        } catch (e) {
            fastify.log.error('Get Friend Requests Error: ' + e.message);
            return { requests: [] };
        }
    });

    // Send friend request
    fastify.post('/api/friends/request', async (req, reply) => {
        const { fromUserId, targetIdentifier } = req.body;
        if (!fromUserId || !targetIdentifier) {
            return reply.code(400).send({ error: 'Missing data' });
        }
        try {
            // Find target user by username (case-insensitive) or friend code (uppercase)
            console.log('🔍 Searching for friend:', targetIdentifier);
            const targetRes = await pool.query(`
                SELECT user_id FROM users
                WHERE LOWER(username) = LOWER($1) OR friend_code = UPPER($1)
            `, [targetIdentifier]);

            console.log('🔍 Search result:', targetRes.rows);

            if (targetRes.rows.length === 0) {
                return reply.code(404).send({ error: 'User not found' });
            }

            const targetUserId = targetRes.rows[0].user_id;

            if (targetUserId === fromUserId) {
                return reply.code(400).send({ error: 'Cannot add yourself' });
            }

            // Check if already friends or request exists
            const existingRes = await pool.query(`
                SELECT id, status FROM friends
                WHERE (user_id_1 = $1 AND user_id_2 = $2) OR (user_id_1 = $2 AND user_id_2 = $1)
            `, [fromUserId, targetUserId]);

            if (existingRes.rows.length > 0) {
                const existing = existingRes.rows[0];
                if (existing.status === 'accepted') {
                    return reply.code(400).send({ error: 'Already friends' });
                }
                return reply.code(400).send({ error: 'Request already pending' });
            }

            // Create friend request
            await pool.query(`
                INSERT INTO friends (user_id_1, user_id_2, status)
                VALUES ($1, $2, 'pending')
            `, [fromUserId, targetUserId]);

            return { success: true };
        } catch (e) {
            fastify.log.error('Send Friend Request Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    // Accept friend request
    fastify.post('/api/friends/accept', async (req, reply) => {
        const { userId, requestId } = req.body;
        try {
            await pool.query(`
                UPDATE friends SET status = 'accepted'
                WHERE id = $1 AND user_id_2 = $2 AND status = 'pending'
            `, [requestId, userId]);
            return { success: true };
        } catch (e) {
            fastify.log.error('Accept Friend Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    // Decline friend request
    fastify.post('/api/friends/decline', async (req, reply) => {
        const { userId, requestId } = req.body;
        try {
            await pool.query(`
                DELETE FROM friends WHERE id = $1 AND user_id_2 = $2 AND status = 'pending'
            `, [requestId, userId]);
            return { success: true };
        } catch (e) {
            fastify.log.error('Decline Friend Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    // Remove friend
    fastify.delete('/api/friends/remove', async (req, reply) => {
        const { userId, friendUserId } = req.body;
        try {
            await pool.query(`
                DELETE FROM friends
                WHERE (user_id_1 = $1 AND user_id_2 = $2) OR (user_id_1 = $2 AND user_id_2 = $1)
            `, [userId, friendUserId]);
            return { success: true };
        } catch (e) {
            fastify.log.error('Remove Friend Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    // ============================================
    // TRADING API
    // ============================================

    // Get trades for user
    fastify.get('/api/trades/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            // Incoming trades
            const incomingRes = await pool.query(`
                SELECT t.*,
                    u.username as from_username, u.profile_shape as from_profile_shape
                FROM trade_requests t
                JOIN users u ON t.from_user_id = u.user_id
                WHERE t.to_user_id = $1 AND t.status = 'pending'
                ORDER BY t.created_at DESC
            `, [userId]);

            // Outgoing trades
            const outgoingRes = await pool.query(`
                SELECT t.*,
                    u.username as to_username, u.profile_shape as to_profile_shape
                FROM trade_requests t
                JOIN users u ON t.to_user_id = u.user_id
                WHERE t.from_user_id = $1 AND t.status = 'pending'
                ORDER BY t.created_at DESC
            `, [userId]);

            return {
                incoming: incomingRes.rows,
                outgoing: outgoingRes.rows
            };
        } catch (e) {
            fastify.log.error('Get Trades Error: ' + e.message);
            return { incoming: [], outgoing: [] };
        }
    });

    // Create trade request
    fastify.post('/api/trades/create', async (req, reply) => {
        const { fromUserId, toUserId, offerItems, requestItems } = req.body;

        if (!fromUserId || !toUserId || !offerItems?.length || !requestItems?.length) {
            return reply.code(400).send({ error: 'Missing data' });
        }

        if (offerItems.length > 3 || requestItems.length > 3) {
            return reply.code(400).send({ error: 'Maximum 3 items per side' });
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Generate trade ID
            const tradeId = `trade_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            // Lock offered items
            for (const item of offerItems) {
                const lockRes = await client.query(`
                    UPDATE inventory SET pending_trade_id = $1
                    WHERE id = $2 AND user_id = $3 AND pending_trade_id IS NULL
                    RETURNING id
                `, [tradeId, item.inventory_id, fromUserId]);

                if (lockRes.rows.length === 0) {
                    throw new Error('Item not available for trade');
                }
            }

            // Create trade request
            await client.query(`
                INSERT INTO trade_requests (id, from_user_id, to_user_id, offer_items, request_items)
                VALUES ($1, $2, $3, $4, $5)
            `, [tradeId, fromUserId, toUserId, JSON.stringify(offerItems), JSON.stringify(requestItems)]);

            await client.query('COMMIT');

            // TODO: Send push notification to toUserId
            console.log(`[NOTIFICATION STUB] Trade request ${tradeId} sent to ${toUserId}`);

            return { success: true, tradeId };
        } catch (e) {
            await client.query('ROLLBACK');
            fastify.log.error('Create Trade Error: ' + e.message);
            return reply.code(500).send({ error: e.message || 'Database error' });
        } finally {
            client.release();
        }
    });

    // Accept trade (atomic swap)
    fastify.post('/api/trades/accept', async (req, reply) => {
        const { userId, tradeId } = req.body;

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Get trade details
            const tradeRes = await client.query(`
                SELECT * FROM trade_requests WHERE id = $1 AND to_user_id = $2 AND status = 'pending'
            `, [tradeId, userId]);

            if (tradeRes.rows.length === 0) {
                throw new Error('Trade not found or already processed');
            }

            const trade = tradeRes.rows[0];
            const offerItems = trade.offer_items;
            const requestItems = trade.request_items;

            // Check expiration
            if (new Date(trade.expires_at) < new Date()) {
                await client.query(`UPDATE trade_requests SET status = 'expired' WHERE id = $1`, [tradeId]);
                throw new Error('Trade has expired');
            }

            // Verify all items still exist and are locked correctly
            for (const item of offerItems) {
                const checkRes = await client.query(`
                    SELECT id FROM inventory WHERE id = $1 AND user_id = $2 AND pending_trade_id = $3
                `, [item.inventory_id, trade.from_user_id, tradeId]);
                if (checkRes.rows.length === 0) {
                    throw new Error('Offered item no longer available');
                }
            }

            for (const item of requestItems) {
                const checkRes = await client.query(`
                    SELECT id FROM inventory WHERE id = $1 AND user_id = $2 AND pending_trade_id IS NULL
                `, [item.inventory_id, userId]);
                if (checkRes.rows.length === 0) {
                    throw new Error('Requested item no longer available');
                }
            }

            // Perform the swap
            // Transfer offered items to receiver (userId)
            for (const item of offerItems) {
                await client.query(`
                    UPDATE inventory SET user_id = $1, pending_trade_id = NULL
                    WHERE id = $2
                `, [userId, item.inventory_id]);
            }

            // Transfer requested items to sender (from_user_id)
            for (const item of requestItems) {
                await client.query(`
                    UPDATE inventory SET user_id = $1
                    WHERE id = $2
                `, [trade.from_user_id, item.inventory_id]);
            }

            // Update trade status
            await client.query(`UPDATE trade_requests SET status = 'accepted' WHERE id = $1`, [tradeId]);

            await client.query('COMMIT');

            // TODO: Send push notification to from_user_id
            console.log(`[NOTIFICATION STUB] Trade ${tradeId} accepted by ${userId}`);

            // Return received items for local update
            const receivedRes = await pool.query(`
                SELECT id, shape_type, rarity, acquired_at FROM inventory WHERE id = ANY($1::int[])
            `, [offerItems.map(i => i.inventory_id)]);

            return { success: true, receivedItems: receivedRes.rows };
        } catch (e) {
            await client.query('ROLLBACK');
            fastify.log.error('Accept Trade Error: ' + e.message);
            return reply.code(500).send({ error: e.message || 'Database error' });
        } finally {
            client.release();
        }
    });

    // Decline trade
    fastify.post('/api/trades/decline', async (req, reply) => {
        const { userId, tradeId } = req.body;

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Get trade to find locked items
            const tradeRes = await client.query(`
                SELECT from_user_id, offer_items FROM trade_requests
                WHERE id = $1 AND to_user_id = $2 AND status = 'pending'
            `, [tradeId, userId]);

            if (tradeRes.rows.length === 0) {
                throw new Error('Trade not found');
            }

            const trade = tradeRes.rows[0];

            // Unlock offered items
            await client.query(`
                UPDATE inventory SET pending_trade_id = NULL WHERE pending_trade_id = $1
            `, [tradeId]);

            // Update trade status
            await client.query(`UPDATE trade_requests SET status = 'declined' WHERE id = $1`, [tradeId]);

            await client.query('COMMIT');

            // TODO: Send push notification to from_user_id
            console.log(`[NOTIFICATION STUB] Trade ${tradeId} declined by ${userId}`);

            return { success: true };
        } catch (e) {
            await client.query('ROLLBACK');
            fastify.log.error('Decline Trade Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        } finally {
            client.release();
        }
    });

    // Cancel trade (by sender)
    fastify.post('/api/trades/cancel', async (req, reply) => {
        const { userId, tradeId } = req.body;

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Verify trade belongs to user
            const tradeRes = await client.query(`
                SELECT id FROM trade_requests WHERE id = $1 AND from_user_id = $2 AND status = 'pending'
            `, [tradeId, userId]);

            if (tradeRes.rows.length === 0) {
                throw new Error('Trade not found');
            }

            // Unlock items
            await client.query(`
                UPDATE inventory SET pending_trade_id = NULL WHERE pending_trade_id = $1
            `, [tradeId]);

            // Update trade status
            await client.query(`UPDATE trade_requests SET status = 'cancelled' WHERE id = $1`, [tradeId]);

            await client.query('COMMIT');
            return { success: true };
        } catch (e) {
            await client.query('ROLLBACK');
            fastify.log.error('Cancel Trade Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        } finally {
            client.release();
        }
    });

    // ============================================
    // NOTIFICATION STUB
    // ============================================

    fastify.post('/api/notify', async (req, reply) => {
        const { toUserId, title, body, data } = req.body;

        // STUB: Log notification payload
        console.log('[NOTIFICATION STUB] Would send push notification:');
        console.log(`  To: ${toUserId}`);
        console.log(`  Title: ${title}`);
        console.log(`  Body: ${body}`);
        console.log(`  Data: ${JSON.stringify(data)}`);

        // TODO: Implement with Firebase Cloud Messaging
        // 1. Get device token from database for toUserId
        // 2. Send FCM request

        return { success: true, stub: true };
    });

    // Serve Client
    fastify.get('/', async (req, reply) => {
        reply.type('text/html');
        return fs.createReadStream(path.join(__dirname, 'public', 'index.html'));
    });

    // LISTENER: Handle Updates (Redis or Local)
    const handleUpdate = (message) => {
        try {
            const data = typeof message === 'string' ? JSON.parse(message) : message;
            // Support both direct payload match (Local) or wrapped (Redis might send raw string)
            const { id, val } = data;

            const lobby = lobbies[id];
            if (!lobby) return;

            // Gather Data
            const viewersList = Array.from(lobby.viewers).map(s => ({ id: s.userId, name: s.username }));
            const playersList = Array.from(lobby.players).map(s => ({ id: s.userId, name: s.username }));
            const count = lobby.viewers.size + lobby.players.size;

            const payload = JSON.stringify({
                v: val,
                c: count,
                viewers: viewersList,
                players: playersList
            });

            for (const client of lobby.viewers) if (client.readyState === 1) client.send(payload);
            for (const client of lobby.players) if (client.readyState === 1) client.send(payload);
        } catch (e) {
            fastify.log.error('PubSub Error: ' + e.message);
        }
    };

    if (useRedis && subRedis) {
        subRedis.subscribe('lobby-updates', (err) => {
            if (!err) fastify.log.info('Subscribed to lobby-updates (Redis)');
        });
        subRedis.on('message', (channel, message) => handleUpdate(message));
    }
    // Always listen to local emitter as fallback or PRIMARY if Redis disabled
    localStore.emitter.on('lobby-updates', (msg) => handleUpdate(msg));


    // WebSocket Endpoint
    fastify.get('/ws/:lobbyId', { websocket: true }, (connection, req) => {
        const socket = connection;
        (async () => {
            try {
                const { lobbyId } = req.params;
                const { role, userId, username } = req.query;

                if (!lobbies[lobbyId]) lobbies[lobbyId] = { viewers: new Set(), players: new Set() };
                const lobby = lobbies[lobbyId];

                socket.role = role;
                socket.userId = userId || 'anon';
                socket.username = username || 'Anonymous';

                // Initial State
                const currentVal = await getLobbyValue(lobbyId);

                // Add to sets
                if (role === 'player') {
                    if (lobby.players.size >= 2) {
                        socket.close(1008, 'Lobby full');
                        return;
                    }
                    lobby.players.add(socket);
                } else {
                    lobby.viewers.add(socket);
                }

                // Broadcast Join
                await publishUpdate(lobbyId, currentVal, 0);

                socket.on('message', async message => {
                    try {
                        if (role === 'player') {
                            const str = message.toString();
                            let action = str;
                            if (str.startsWith('{')) {
                                const json = JSON.parse(str);
                                action = json.action;
                            }

                            let delta = 0;
                            if (action === 'INC') delta = 1;
                            if (action === 'DEC') delta = -1;

                            if (delta !== 0) {
                                const newVal = await updateLobbyValue(lobbyId, delta);
                                await publishUpdate(lobbyId, newVal, 0);
                            }
                        }
                    } catch (e) {
                        fastify.log.error('Handler Error: ' + e.message);
                    }
                });

                socket.on('close', async () => {
                    if (role === 'player') lobby.players.delete(socket);
                    else lobby.viewers.delete(socket);

                    const currentVal = await getLobbyValue(lobbyId);
                    await publishUpdate(lobbyId, currentVal, 0);
                });
            } catch (err) {
                fastify.log.error('WebSocket error: ' + err.message);
                if (socket) socket.close(1011, 'Internal Error');
            }
        })();
    });

    fastify.get('/api/lobbies', async () => {
        return Object.keys(lobbies).map(id => ({
            id,
            count: lobbies[id].viewers.size + lobbies[id].players.size
        }));
    });
});

const start = async () => {
    try {
        const PORT = process.env.PORT || 3000;
        await fastify.listen({ port: PORT, host: '0.0.0.0' });
        console.log(`Server started on http://localhost:${PORT}`);
        if (!useRedis) console.log('👉 [NOTICE] Running with IN-MEMORY counters (Redis disabled/unavailable)');
        else console.log('👉 [NOTICE] Running with REDIS counters');
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};
start();
