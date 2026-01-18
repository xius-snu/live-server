require('dotenv').config();
const fastify = require('fastify')({ logger: true });
fastify.register(require('@fastify/websocket'));
const fs = require('fs');
const path = require('path');
const Redis = require('ioredis');

// CONNECTION
// Use environment variable for Redis URL
const REDIS_URL = process.env.REDIS_URL;

if (!REDIS_URL) {
    console.error('Missing REDIS_URL environment variable');
    process.exit(1);
}

const redis = new Redis(REDIS_URL, {
    tls: { rejectUnauthorized: false }
});

redis.on('error', (err) => {
    fastify.log.error('Redis Client Error: ' + err.message);
});

redis.on('connect', () => {
    fastify.log.info('Redis Client Connected');
});

const subRedis = new Redis(REDIS_URL, {
    tls: { rejectUnauthorized: false }
});

subRedis.on('error', (err) => {
    fastify.log.error('Redis Subscriber Error: ' + err.message);
});

const lobbies = {};

fastify.register(async function (fastify) {

    // Serve Client
    fastify.get('/', async (req, reply) => {
        reply.type('text/html');
        return fs.createReadStream(path.join(__dirname, 'public', 'index.html'));
    });

    // Subscribe to global updates
    subRedis.subscribe('lobby-updates', (err, count) => {
        if (err) fastify.log.error('Failed to subscribe: ' + err.message);
        else fastify.log.info('Subscribed to lobby-updates');
    });

    subRedis.on('message', (channel, message) => {
        try {
            const { id, val } = JSON.parse(message);
            const lobby = lobbies[id];
            if (!lobby) return;

            const count = lobby.viewers.size + lobby.players.size;
            const payload = JSON.stringify({ v: val, c: count });

            for (const client of lobby.viewers) {
                if (client.readyState === 1) client.send(payload);
            }
            for (const client of lobby.players) {
                if (client.readyState === 1) client.send(payload);
            }
        } catch (e) {
            fastify.log.error('PubSub Error: ' + e.message);
        }
    });

    // WebSocket Endpoint
    // IMPORTANT: Do NOT make this function async. Fastify-websocket (v10+)
    // connection is the actual WebSocket (or SocketStream depending on config).
    // Based on debug logs: connection constructor is WebSocket.
    fastify.get('/ws/:lobbyId', { websocket: true }, (connection, req) => {
        const socket = connection; // In this version/config, usage shows connection IS the socket

        /*
          NOTE:
          If using fastify-websocket v10/v11, typically the first argument is a `SocketStream` 
          which has a `.socket` property. However, debug logs showed keys like:
          _events, _readyState, _socket, ... and constructor: WebSocket.
          This implies 'connection' IS the raw WebSocket instance, OR we are misinterpreting the object.
          Wait, the debug log said keys include "_socket".
          But previously the code said `!connection.socket` failed?
          Ah, looking at the logs:
          keys: ..., _socket, ...
          So there IS a _socket property (internal), but maybe not 'socket'.
          
          If the constructor is WebSocket, then `connection` IS the websocket instance.
          So we should use `connection` directly as the socket.
        */

        (async () => {
            try {
                const { lobbyId } = req.params;
                const { role } = req.query;

                if (!lobbies[lobbyId]) {
                    lobbies[lobbyId] = { viewers: new Set(), players: new Set() };
                }
                const lobby = lobbies[lobbyId];
                socket.role = role;

                // Get current value from Redis immediately upon join
                let initialVal = 0;
                try {
                    const currentVal = await redis.get(`lobby:${lobbyId}`);
                    initialVal = currentVal ? parseInt(currentVal, 10) : 0;
                } catch (redisErr) {
                    fastify.log.error('Redis GET failed in handshake: ' + redisErr.message);
                }

                // Send initial state if still open
                if (socket.readyState === 1) {
                    socket.send(JSON.stringify({
                        v: initialVal,
                        c: lobby.viewers.size + lobby.players.size
                    }));
                }

                if (role === 'player') {
                    if (lobby.players.size >= 2) {
                        socket.close(1008, 'Lobby full');
                        return;
                    }
                    lobby.players.add(socket);
                    fastify.log.info(`Player joined lobby ${lobbyId}`);
                } else {
                    lobby.viewers.add(socket);
                }

                socket.on('message', async message => {
                    try {
                        if (role === 'player') {
                            const str = message.toString();
                            let action = str;
                            if (str.startsWith('{')) {
                                const json = JSON.parse(str);
                                action = json.action;
                            }

                            let newVal;
                            if (action === 'INC') newVal = await redis.incr(`lobby:${lobbyId}`);
                            if (action === 'DEC') newVal = await redis.decr(`lobby:${lobbyId}`);

                            if (newVal !== undefined) {
                                await redis.publish('lobby-updates', JSON.stringify({ id: lobbyId, val: newVal }));
                            }
                        }
                    } catch (e) {
                        fastify.log.error('Handler Error: ' + e.message);
                    }
                });

                socket.on('close', () => {
                    if (role === 'player') lobby.players.delete(socket);
                    else lobby.viewers.delete(socket);
                });
            } catch (err) {
                fastify.log.error('WebSocket logic error: ' + err.message);
                if (socket) socket.close(1011, 'Internal Error');
            }
        })();
    });

    // API List
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
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};
start();
