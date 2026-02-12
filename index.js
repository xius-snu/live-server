require('dotenv').config();
const fastify = require('fastify')({ logger: true });
fastify.register(require('@fastify/cors'), {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE']
});
fastify.register(require('@fastify/websocket'));
const { Pool } = require('pg');
const crypto = require('crypto');

// ============================================
// DATABASE
// ============================================

const DATABASE_URL = process.env.DATABASE_URL;
const pool = new Pool({
    connectionString: DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// ============================================
// MARKETPLACE CONSTANTS
// ============================================

const ITEM_TYPES = [
    { id: 'basic_paint', name: 'Basic Paint Can', category: 'paint', base_price: 1 },
    { id: 'premium_paint', name: 'Premium Paint Can', category: 'paint', base_price: 3 },
    { id: 'neon_paint', name: 'Neon Paint', category: 'paint', base_price: 10 },
    { id: 'glitter_finish', name: 'Glitter Finish', category: 'paint', base_price: 12 },
    { id: 'gold_roller', name: 'Gold Roller Skin', category: 'roller_skin', base_price: 5 },
    { id: 'money_roller', name: 'Money Roller Skin', category: 'roller_skin', base_price: 25 },
    { id: 'diamond_roller', name: 'Diamond Roller Skin', category: 'roller_skin', base_price: 50 },
    { id: 'speed_boost', name: 'Speed Boost (1hr)', category: 'consumable', base_price: 2 },
    { id: 'blueprint_penthouse', name: 'Blueprint: Penthouse', category: 'collectible', base_price: 50 },
    { id: 'painters_crown', name: "Painter's Crown", category: 'collectible', base_price: 100 },
];

// ============================================
// IN-MEMORY: MARKETPLACE WS CLIENTS
// ============================================

const marketplaceClients = new Set(); // Set of WebSocket connections

function broadcastMarketplace(data) {
    const msg = JSON.stringify(data);
    for (const ws of marketplaceClients) {
        if (ws.readyState === 1) {
            ws.send(msg);
        }
    }
}

// ============================================
// HELPERS
// ============================================

function generateId(prefix = 'id') {
    return `${prefix}_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
}

// ============================================
// SERVER SETUP
// ============================================

fastify.register(async function (fastify) {

    // Initialize DB tables
    await pool.query(`
        CREATE TABLE IF NOT EXISTS users (
            user_id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            wins INTEGER DEFAULT 0,
            losses INTEGER DEFAULT 0,
            draws INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS player_progress (
            user_id TEXT PRIMARY KEY REFERENCES users(user_id),
            cash DOUBLE PRECISION DEFAULT 0,
            stars INTEGER DEFAULT 0,
            prestige_level INTEGER DEFAULT 0,
            current_house TEXT DEFAULT 'apartment',
            current_room INTEGER DEFAULT 0,
            upgrades JSONB DEFAULT '{}',
            total_walls_painted INTEGER DEFAULT 0,
            total_cash_earned DOUBLE PRECISION DEFAULT 0,
            last_online_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS player_inventory (
            instance_id TEXT PRIMARY KEY,
            item_type_id TEXT NOT NULL,
            rarity TEXT NOT NULL DEFAULT 'common',
            owner_id TEXT NOT NULL REFERENCES users(user_id),
            minted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_listed BOOLEAN DEFAULT FALSE
        );

        CREATE TABLE IF NOT EXISTS marketplace_listings (
            listing_id TEXT PRIMARY KEY,
            seller_id TEXT NOT NULL REFERENCES users(user_id),
            instance_id TEXT NOT NULL REFERENCES player_inventory(instance_id),
            price_stars INTEGER NOT NULL,
            listing_fee_percent DOUBLE PRECISION DEFAULT 5.0,
            listed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'active'
        );

        CREATE TABLE IF NOT EXISTS marketplace_trades (
            trade_id SERIAL PRIMARY KEY,
            listing_id TEXT NOT NULL REFERENCES marketplace_listings(listing_id),
            buyer_id TEXT NOT NULL REFERENCES users(user_id),
            seller_id TEXT NOT NULL REFERENCES users(user_id),
            instance_id TEXT NOT NULL,
            item_type_id TEXT NOT NULL,
            price_stars INTEGER NOT NULL,
            fee_stars INTEGER NOT NULL,
            traded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS events (
            event_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            start_at TIMESTAMP NOT NULL,
            end_at TIMESTAMP NOT NULL,
            drop_table JSONB DEFAULT '{"common": 0.6, "rare": 0.25, "epic": 0.1, "legendary": 0.05}',
            max_attempts INTEGER DEFAULT 3,
            status TEXT DEFAULT 'scheduled'
        );

        CREATE TABLE IF NOT EXISTS event_participation (
            id SERIAL PRIMARY KEY,
            event_id TEXT NOT NULL REFERENCES events(event_id),
            user_id TEXT NOT NULL REFERENCES users(user_id),
            attempt_number INTEGER NOT NULL,
            coverage_percent DOUBLE PRECISION,
            reward_instance_id TEXT,
            completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(event_id, user_id, attempt_number)
        );
    `);

    // Safe migrations for new columns
    try {
        await pool.query('CREATE INDEX IF NOT EXISTS idx_listings_status ON marketplace_listings(status)');
        await pool.query('CREATE INDEX IF NOT EXISTS idx_inventory_owner ON player_inventory(owner_id)');
        await pool.query('CREATE INDEX IF NOT EXISTS idx_trades_item ON marketplace_trades(item_type_id)');
        console.log('Schema migration complete');
    } catch (e) {
        console.log('Schema migration note:', e.message);
    }

    // ==================
    // REST API: USER
    // ==================

    fastify.post('/api/user', async (req, reply) => {
        const { userId, username } = req.body;
        if (!userId || !username) {
            return reply.code(400).send({ error: 'Missing userId or username' });
        }
        try {
            await pool.query(`
                INSERT INTO users (user_id, username)
                VALUES ($1, $2)
                ON CONFLICT (user_id) DO UPDATE SET username = $2
            `, [userId, username]);
            return { success: true, username };
        } catch (e) {
            fastify.log.error('DB User Error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    fastify.get('/api/user/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query(
                'SELECT username, wins, losses, draws FROM users WHERE user_id = $1',
                [userId]
            );
            if (res.rows.length === 0) {
                return { username: null };
            }
            return res.rows[0];
        } catch (e) {
            fastify.log.error('DB Get Error: ' + e.message);
            return { username: null };
        }
    });

    // ==================
    // REST API: PROGRESS
    // ==================

    fastify.post('/api/progress/save', async (req, reply) => {
        const { userId, cash, stars, prestigeLevel, currentHouse, currentRoom,
                upgrades, totalWallsPainted, totalCashEarned } = req.body;
        if (!userId) return reply.code(400).send({ error: 'Missing userId' });

        try {
            await pool.query(`
                INSERT INTO player_progress
                    (user_id, cash, stars, prestige_level, current_house, current_room,
                     upgrades, total_walls_painted, total_cash_earned, last_online_at, updated_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                ON CONFLICT (user_id) DO UPDATE SET
                    cash = $2, stars = $3, prestige_level = $4,
                    current_house = $5, current_room = $6, upgrades = $7,
                    total_walls_painted = $8, total_cash_earned = $9,
                    last_online_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
            `, [userId, cash || 0, stars || 0, prestigeLevel || 0,
                currentHouse || 'apartment', currentRoom || 0,
                JSON.stringify(upgrades || {}),
                totalWallsPainted || 0, totalCashEarned || 0]);

            return { success: true };
        } catch (e) {
            fastify.log.error('Progress save error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    fastify.get('/api/progress/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query(
                'SELECT * FROM player_progress WHERE user_id = $1',
                [userId]
            );

            if (res.rows.length === 0) {
                return {
                    cash: 0, stars: 0, prestigeLevel: 0,
                    currentHouse: 'apartment', currentRoom: 0,
                    upgrades: {}, totalWallsPainted: 0, totalCashEarned: 0,
                    idleIncome: 0
                };
            }

            const row = res.rows[0];
            const upgrades = row.upgrades || {};

            // Calculate idle income server-side
            const autoPainterLevel = upgrades.autoPainter || 0;
            const starMultiplier = 1.0 + 0.10 * (row.stars || 0);
            const lastOnline = new Date(row.last_online_at);
            const now = new Date();
            let offlineSeconds = Math.floor((now - lastOnline) / 1000);
            offlineSeconds = Math.min(offlineSeconds, 8 * 3600); // Cap at 8 hours
            const idleIncome = autoPainterLevel * 2.0 * offlineSeconds * starMultiplier;

            return {
                cash: (row.cash || 0) + idleIncome,
                stars: row.stars || 0,
                prestigeLevel: row.prestige_level || 0,
                currentHouse: row.current_house || 'apartment',
                currentRoom: row.current_room || 0,
                upgrades: upgrades,
                totalWallsPainted: row.total_walls_painted || 0,
                totalCashEarned: row.total_cash_earned || 0,
                idleIncome: idleIncome,
                lastOnlineAt: row.last_online_at
            };
        } catch (e) {
            fastify.log.error('Progress load error: ' + e.message);
            return { cash: 0, stars: 0, prestigeLevel: 0, currentHouse: 'apartment',
                     currentRoom: 0, upgrades: {}, idleIncome: 0 };
        }
    });

    // ==================
    // REST API: INVENTORY
    // ==================

    fastify.get('/api/inventory/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query(
                `SELECT instance_id, item_type_id, rarity, minted_at, is_listed
                 FROM player_inventory WHERE owner_id = $1
                 ORDER BY minted_at DESC`,
                [userId]
            );
            return { items: res.rows };
        } catch (e) {
            fastify.log.error('Inventory error: ' + e.message);
            return { items: [] };
        }
    });

    // ==================
    // REST API: MARKETPLACE
    // ==================

    fastify.get('/api/marketplace/listings', async (req, reply) => {
        const { category, sort } = req.query;
        try {
            let query = `
                SELECT ml.listing_id, ml.seller_id, ml.instance_id, ml.price_stars,
                       ml.listing_fee_percent, ml.listed_at, ml.status,
                       pi.item_type_id, pi.rarity,
                       u.username as seller_name
                FROM marketplace_listings ml
                JOIN player_inventory pi ON ml.instance_id = pi.instance_id
                JOIN users u ON ml.seller_id = u.user_id
                WHERE ml.status = 'active'
            `;
            const params = [];

            if (category) {
                // Filter by item category would need item_types table or inline check
                // For now, filter by item_type_id pattern
            }

            query += ' ORDER BY ml.listed_at DESC LIMIT 50';

            const res = await pool.query(query, params);
            return { listings: res.rows };
        } catch (e) {
            fastify.log.error('Marketplace listings error: ' + e.message);
            return { listings: [] };
        }
    });

    fastify.get('/api/marketplace/index-prices', async (req, reply) => {
        try {
            const res = await pool.query(`
                SELECT item_type_id,
                       AVG(price_stars) as avg_price,
                       COUNT(*) as trade_count
                FROM (
                    SELECT item_type_id, price_stars,
                           ROW_NUMBER() OVER (PARTITION BY item_type_id ORDER BY traded_at DESC) as rn
                    FROM marketplace_trades
                ) sub
                WHERE rn <= 10
                GROUP BY item_type_id
            `);

            const prices = {};
            for (const row of res.rows) {
                prices[row.item_type_id] = {
                    avgPrice: parseFloat(row.avg_price) || 0,
                    tradeCount: parseInt(row.trade_count) || 0
                };
            }

            // Fill in base prices for items with no trades
            for (const item of ITEM_TYPES) {
                if (!prices[item.id]) {
                    prices[item.id] = {
                        avgPrice: item.base_price,
                        tradeCount: 0
                    };
                }
            }

            return { prices };
        } catch (e) {
            fastify.log.error('Index prices error: ' + e.message);
            return { prices: {} };
        }
    });

    fastify.post('/api/marketplace/list', async (req, reply) => {
        const { userId, instanceId, priceStars, feePercent } = req.body;
        if (!userId || !instanceId || !priceStars) {
            return reply.code(400).send({ error: 'Missing required fields' });
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Verify ownership and not already listed
            const itemRes = await client.query(
                'SELECT * FROM player_inventory WHERE instance_id = $1 AND owner_id = $2 AND is_listed = FALSE',
                [instanceId, userId]
            );
            if (itemRes.rows.length === 0) {
                await client.query('ROLLBACK');
                return reply.code(400).send({ error: 'Item not found or already listed' });
            }

            const listingId = generateId('lst');
            const fee = feePercent || 5.0;

            await client.query(
                `INSERT INTO marketplace_listings (listing_id, seller_id, instance_id, price_stars, listing_fee_percent)
                 VALUES ($1, $2, $3, $4, $5)`,
                [listingId, userId, instanceId, priceStars, fee]
            );

            await client.query(
                'UPDATE player_inventory SET is_listed = TRUE WHERE instance_id = $1',
                [instanceId]
            );

            await client.query('COMMIT');

            broadcastMarketplace({
                type: 'new_listing',
                listingId,
                itemTypeId: itemRes.rows[0].item_type_id,
                priceStars,
                sellerName: userId.substring(0, 8)
            });

            return { success: true, listingId };
        } catch (e) {
            await client.query('ROLLBACK');
            fastify.log.error('Marketplace list error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        } finally {
            client.release();
        }
    });

    fastify.post('/api/marketplace/buy', async (req, reply) => {
        const { userId, listingId } = req.body;
        if (!userId || !listingId) {
            return reply.code(400).send({ error: 'Missing required fields' });
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Get listing
            const listingRes = await client.query(
                `SELECT ml.*, pi.item_type_id, pi.rarity
                 FROM marketplace_listings ml
                 JOIN player_inventory pi ON ml.instance_id = pi.instance_id
                 WHERE ml.listing_id = $1 AND ml.status = 'active'
                 FOR UPDATE`,
                [listingId]
            );
            if (listingRes.rows.length === 0) {
                await client.query('ROLLBACK');
                return reply.code(400).send({ error: 'Listing not found or already sold' });
            }

            const listing = listingRes.rows[0];

            if (listing.seller_id === userId) {
                await client.query('ROLLBACK');
                return reply.code(400).send({ error: 'Cannot buy your own listing' });
            }

            // Check buyer has enough stars
            const buyerRes = await client.query(
                'SELECT stars FROM player_progress WHERE user_id = $1 FOR UPDATE',
                [userId]
            );
            const buyerStars = buyerRes.rows.length > 0 ? buyerRes.rows[0].stars : 0;

            if (buyerStars < listing.price_stars) {
                await client.query('ROLLBACK');
                return reply.code(400).send({ error: 'Not enough stars' });
            }

            // Calculate fee
            const feeStars = Math.ceil(listing.price_stars * listing.listing_fee_percent / 100);
            const sellerReceives = listing.price_stars - feeStars;

            // Deduct stars from buyer
            await client.query(
                'UPDATE player_progress SET stars = stars - $1 WHERE user_id = $2',
                [listing.price_stars, userId]
            );

            // Credit stars to seller (minus fee)
            await client.query(
                `INSERT INTO player_progress (user_id, stars)
                 VALUES ($1, $2)
                 ON CONFLICT (user_id) DO UPDATE SET stars = player_progress.stars + $2`,
                [listing.seller_id, sellerReceives]
            );

            // Transfer item ownership
            await client.query(
                'UPDATE player_inventory SET owner_id = $1, is_listed = FALSE WHERE instance_id = $2',
                [userId, listing.instance_id]
            );

            // Update listing status
            await client.query(
                "UPDATE marketplace_listings SET status = 'sold' WHERE listing_id = $1",
                [listingId]
            );

            // Record trade
            await client.query(
                `INSERT INTO marketplace_trades
                    (listing_id, buyer_id, seller_id, instance_id, item_type_id, price_stars, fee_stars)
                 VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                [listingId, userId, listing.seller_id, listing.instance_id,
                 listing.item_type_id, listing.price_stars, feeStars]
            );

            await client.query('COMMIT');

            broadcastMarketplace({
                type: 'listing_sold',
                listingId,
                itemTypeId: listing.item_type_id,
                priceStars: listing.price_stars
            });

            return {
                success: true,
                starsSpent: listing.price_stars,
                itemReceived: listing.instance_id
            };
        } catch (e) {
            await client.query('ROLLBACK');
            fastify.log.error('Marketplace buy error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        } finally {
            client.release();
        }
    });

    fastify.post('/api/marketplace/cancel', async (req, reply) => {
        const { userId, listingId } = req.body;
        if (!userId || !listingId) {
            return reply.code(400).send({ error: 'Missing required fields' });
        }

        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            const res = await client.query(
                `SELECT * FROM marketplace_listings
                 WHERE listing_id = $1 AND seller_id = $2 AND status = 'active'`,
                [listingId, userId]
            );
            if (res.rows.length === 0) {
                await client.query('ROLLBACK');
                return reply.code(400).send({ error: 'Listing not found' });
            }

            await client.query(
                "UPDATE marketplace_listings SET status = 'cancelled' WHERE listing_id = $1",
                [listingId]
            );

            await client.query(
                'UPDATE player_inventory SET is_listed = FALSE WHERE instance_id = $1',
                [res.rows[0].instance_id]
            );

            await client.query('COMMIT');
            return { success: true };
        } catch (e) {
            await client.query('ROLLBACK');
            fastify.log.error('Marketplace cancel error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        } finally {
            client.release();
        }
    });

    // ==================
    // REST API: EVENTS
    // ==================

    fastify.get('/api/events/active', async (req, reply) => {
        try {
            const res = await pool.query(
                `SELECT * FROM events
                 WHERE status = 'active'
                    OR (status = 'scheduled' AND start_at <= CURRENT_TIMESTAMP AND end_at > CURRENT_TIMESTAMP)
                 ORDER BY start_at DESC`
            );

            // Auto-activate scheduled events that are now in window
            for (const event of res.rows) {
                if (event.status === 'scheduled') {
                    await pool.query(
                        "UPDATE events SET status = 'active' WHERE event_id = $1",
                        [event.event_id]
                    );
                }
            }

            return { events: res.rows };
        } catch (e) {
            fastify.log.error('Events error: ' + e.message);
            return { events: [] };
        }
    });

    fastify.post('/api/events/:eventId/attempt', async (req, reply) => {
        const { eventId } = req.params;
        const { userId, coveragePercent } = req.body;
        if (!userId) return reply.code(400).send({ error: 'Missing userId' });

        try {
            // Get event
            const eventRes = await pool.query(
                "SELECT * FROM events WHERE event_id = $1 AND status = 'active'",
                [eventId]
            );
            if (eventRes.rows.length === 0) {
                return reply.code(400).send({ error: 'Event not active' });
            }

            const event = eventRes.rows[0];

            // Check attempts remaining
            const attemptsRes = await pool.query(
                'SELECT COUNT(*) as cnt FROM event_participation WHERE event_id = $1 AND user_id = $2',
                [eventId, userId]
            );
            const attemptsMade = parseInt(attemptsRes.rows[0].cnt);

            if (attemptsMade >= event.max_attempts) {
                return reply.code(400).send({ error: 'No attempts remaining' });
            }

            // Roll for drop
            const dropTable = event.drop_table || { common: 0.6, rare: 0.25, epic: 0.1, legendary: 0.05 };
            const roll = Math.random();
            let rarity = null;
            let cumulative = 0;

            // Higher coverage = slightly better rates
            const coverageBonus = (coveragePercent || 0) > 0.9 ? 0.05 : 0;

            for (const [r, rate] of [['legendary', dropTable.legendary], ['epic', dropTable.epic],
                                       ['rare', dropTable.rare], ['common', dropTable.common]]) {
                cumulative += (rate || 0) + (r !== 'common' ? coverageBonus : 0);
                if (roll < cumulative) {
                    rarity = r;
                    break;
                }
            }

            if (!rarity) rarity = 'common';

            // Pick a random item of that rarity or higher
            const rarityItems = {
                common: ['basic_paint', 'speed_boost'],
                rare: ['neon_paint', 'glitter_finish'],
                epic: ['money_roller', 'blueprint_penthouse'],
                legendary: ['diamond_roller', 'painters_crown']
            };

            const candidates = rarityItems[rarity] || rarityItems.common;
            const chosenItemType = candidates[Math.floor(Math.random() * candidates.length)];

            // Mint item
            const instanceId = generateId('item');
            await pool.query(
                `INSERT INTO player_inventory (instance_id, item_type_id, rarity, owner_id)
                 VALUES ($1, $2, $3, $4)`,
                [instanceId, chosenItemType, rarity, userId]
            );

            // Record participation
            await pool.query(
                `INSERT INTO event_participation (event_id, user_id, attempt_number, coverage_percent, reward_instance_id)
                 VALUES ($1, $2, $3, $4, $5)`,
                [eventId, userId, attemptsMade + 1, coveragePercent || 0, instanceId]
            );

            return {
                success: true,
                reward: {
                    instanceId,
                    itemTypeId: chosenItemType,
                    rarity,
                },
                attemptsRemaining: event.max_attempts - attemptsMade - 1
            };
        } catch (e) {
            fastify.log.error('Event attempt error: ' + e.message);
            return reply.code(500).send({ error: 'Database error' });
        }
    });

    // ==================
    // HEALTH CHECK
    // ==================

    fastify.get('/', async (req, reply) => {
        reply.type('text/html');
        return '<h1>Paint Roller Server</h1><p>Server is running.</p>';
    });

    // ==================
    // WEBSOCKET: MARKETPLACE
    // ==================

    fastify.get('/ws/marketplace', { websocket: true }, (connection, req) => {
        const socket = connection;
        const { userId } = req.query;

        socket.userId = userId || 'anon';
        marketplaceClients.add(socket);

        socket.on('close', () => {
            marketplaceClients.delete(socket);
        });

        socket.on('message', (message) => {
            // Marketplace WS is primarily for receiving broadcasts
            // Could add ping/pong or subscription filtering here
        });
    });

    // Keep legacy /ws endpoint for backward compatibility
    fastify.get('/ws', { websocket: true }, (connection, req) => {
        const socket = connection;
        socket.on('close', () => {});
    });
});

// ============================================
// START
// ============================================

const start = async () => {
    try {
        const PORT = process.env.PORT || 3000;
        await fastify.listen({ port: PORT, host: '0.0.0.0' });
        console.log(`Paint Roller server started on http://localhost:${PORT}`);
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};
start();
