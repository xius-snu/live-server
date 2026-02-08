require('dotenv').config();
const fastify = require('fastify')({ logger: true });
fastify.register(require('@fastify/cors'), {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE']
});
fastify.register(require('@fastify/websocket'));
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

// ============================================
// DATABASE
// ============================================

const DATABASE_URL = process.env.DATABASE_URL;
const pool = new Pool({
    connectionString: DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// ============================================
// GAME CONSTANTS
// ============================================

const THEMES = [
    // Animals
    'Cat', 'Dog', 'Fish', 'Bird', 'Frog', 'Turtle', 'Snake', 'Butterfly',
    'Dragon', 'Unicorn', 'Penguin', 'Owl', 'Shark', 'Whale', 'Octopus',
    'Bee', 'Spider', 'Elephant', 'Monkey', 'Rabbit', 'Bear', 'Fox',
    'Bat', 'Crab', 'Jellyfish', 'Snail',
    // Nature
    'Tree', 'Sun', 'Moon', 'Star', 'Flower', 'Mountain', 'Ocean', 'Cloud',
    'Rainbow', 'Mushroom', 'Cactus', 'Volcano', 'Waterfall', 'Sunset',
    'Lightning', 'Tornado', 'Island', 'Forest', 'River', 'Snowflake',
    // Objects
    'House', 'Car', 'Boat', 'Rocket', 'Sword', 'Crown', 'Key', 'Diamond',
    'Guitar', 'Camera', 'Lamp', 'Clock', 'Umbrella', 'Treasure Chest',
    'Telescope', 'Compass', 'Anchor', 'Hourglass', 'Trophy', 'Candle',
    // Food
    'Apple', 'Cake', 'Pizza', 'Ice Cream', 'Cupcake', 'Donut', 'Burger',
    'Taco', 'Sushi', 'Watermelon', 'Pineapple', 'Cherry', 'Cookie',
    // Characters/Things
    'Robot', 'Alien', 'Ghost', 'Skull', 'Wizard', 'Pirate', 'Ninja',
    'Snowman', 'Scarecrow', 'Mermaid', 'Angel', 'Astronaut',
    // Places/Scenes
    'Castle', 'Lighthouse', 'Spaceship', 'Bridge', 'Tent', 'Windmill',
    'Igloo', 'Pyramid', 'Ferris Wheel',
    // Misc
    'Heart', 'Fire', 'Planet', 'Eye', 'Hand', 'Smile', 'Music Note',
    'Balloon', 'Kite', 'Dice', 'Maze', 'Ladder', 'Parachute'
];

const COLOR_PALETTE = [
    '#FF0000', '#FF6B35', '#FFC107', '#FFEB3B', '#4CAF50',
    '#2E7D32', '#00BCD4', '#2196F3', '#1565C0', '#9C27B0',
    '#E91E63', '#F48FB1', '#795548', '#5D4037', '#FF9800',
    '#607D8B', '#9E9E9E', '#424242', '#000000', '#FFFFFF',
    '#FFCDD2', '#C8E6C9', '#BBDEFB', '#FFF9C4', '#D1C4E9'
];

const DRAWING_TIMER = 90; // seconds
const GRID_SIZE = 12;
const COLOR_PICK_ROUNDS = 3;

// ============================================
// IN-MEMORY GAME STATE
// ============================================

const matchQueue = [];       // [{ socket, userId, username }]
const games = {};            // gameId -> game object
const socketToGame = new Map(); // socket -> gameId

// ============================================
// HELPERS
// ============================================

let gameIdCounter = 0;
function generateGameId() {
    return `game_${Date.now()}_${++gameIdCounter}`;
}

function getTwoUniqueThemes() {
    const shuffled = [...THEMES].sort(() => Math.random() - 0.5);
    return [shuffled[0], shuffled[1]];
}

function getRandomColors(count, exclude = []) {
    const available = COLOR_PALETTE.filter(c => !exclude.includes(c));
    const result = [];
    const copy = [...available];
    for (let i = 0; i < count && copy.length > 0; i++) {
        const idx = Math.floor(Math.random() * copy.length);
        result.push(copy.splice(idx, 1)[0]);
    }
    return result;
}

function createEmptyGrid() {
    return Array.from({ length: GRID_SIZE }, () => Array(GRID_SIZE).fill(-1));
}

function sendToSocket(socket, data) {
    if (socket && socket.readyState === 1) {
        socket.send(JSON.stringify(data));
    }
}

function getPlayerIndex(game, socket) {
    return game.players.findIndex(p => p.socket === socket);
}

function getOpponent(game, socket) {
    const idx = getPlayerIndex(game, socket);
    return idx === 0 ? game.players[1] : game.players[0];
}

function cleanupGame(gameId) {
    const game = games[gameId];
    if (!game) return;
    if (game.timer) clearTimeout(game.timer);
    for (const p of game.players) {
        socketToGame.delete(p.socket);
    }
    delete games[gameId];
}

// ============================================
// MATCHMAKING
// ============================================

function handleQueue() {
    while (matchQueue.length >= 2) {
        const p1 = matchQueue.shift();
        const p2 = matchQueue.shift();

        // Verify both sockets still open
        if (p1.socket.readyState !== 1) {
            if (p2.socket.readyState === 1) matchQueue.unshift(p2);
            continue;
        }
        if (p2.socket.readyState !== 1) {
            if (p1.socket.readyState === 1) matchQueue.unshift(p1);
            continue;
        }

        createGame(p1, p2);
    }
}

function createGame(p1, p2) {
    const gameId = generateGameId();
    const [theme1, theme2] = getTwoUniqueThemes();

    const game = {
        id: gameId,
        players: [
            { socket: p1.socket, userId: p1.userId, username: p1.username, colors: [], grid: createEmptyGrid(), submitted: false, theme: theme1, guess: null },
            { socket: p2.socket, userId: p2.userId, username: p2.username, colors: [], grid: createEmptyGrid(), submitted: false, theme: theme2, guess: null }
        ],
        phase: 'color_pick',
        colorPickRound: 0,
        currentColorOptions: [[], []], // per player
        timer: null,
        rematch: [false, false]
    };

    games[gameId] = game;
    socketToGame.set(p1.socket, gameId);
    socketToGame.set(p2.socket, gameId);

    // Notify both players - each gets their OWN theme only
    sendToSocket(p1.socket, { type: 'match_found', gameId, opponent: p2.username, theme: theme1, playerIndex: 0 });
    sendToSocket(p2.socket, { type: 'match_found', gameId, opponent: p1.username, theme: theme2, playerIndex: 1 });

    // Start color pick
    startColorPickRound(gameId);
}

// ============================================
// COLOR PICK PHASE
// ============================================

function startColorPickRound(gameId) {
    const game = games[gameId];
    if (!game) return;

    for (let i = 0; i < 2; i++) {
        const player = game.players[i];
        const options = getRandomColors(3, player.colors);
        game.currentColorOptions[i] = options;
        sendToSocket(player.socket, { type: 'color_options', colors: options, round: game.colorPickRound });
    }
}

function handlePickColor(socket, data) {
    const gameId = socketToGame.get(socket);
    if (!gameId) return;
    const game = games[gameId];
    if (!game || game.phase !== 'color_pick') return;

    const playerIdx = getPlayerIndex(game, socket);
    if (playerIdx === -1) return;

    const { index } = data;
    if (typeof index !== 'number' || index < 0 || index > 2) return;

    const player = game.players[playerIdx];
    // Don't allow picking again if already picked this round
    if (player.colors.length > game.colorPickRound) return;

    const chosenColor = game.currentColorOptions[playerIdx][index];
    if (!chosenColor) return;

    player.colors.push(chosenColor);
    sendToSocket(socket, { type: 'color_picked', round: game.colorPickRound, color: chosenColor });

    // Check if both players picked
    if (game.players.every(p => p.colors.length > game.colorPickRound)) {
        game.colorPickRound++;
        if (game.colorPickRound < COLOR_PICK_ROUNDS) {
            startColorPickRound(gameId);
        } else {
            startDrawingPhase(gameId);
        }
    }
}

// ============================================
// DRAWING PHASE
// ============================================

function startDrawingPhase(gameId) {
    const game = games[gameId];
    if (!game) return;

    game.phase = 'drawing';

    for (const player of game.players) {
        player.submitted = false;
        player.grid = createEmptyGrid();
        sendToSocket(player.socket, { type: 'drawing_start', yourColors: player.colors, timer: DRAWING_TIMER });
    }

    // Server-authoritative timer
    game.timer = setTimeout(() => {
        endDrawingPhase(gameId);
    }, DRAWING_TIMER * 1000);
}

function handleDraw(socket, data) {
    const gameId = socketToGame.get(socket);
    if (!gameId) return;
    const game = games[gameId];
    if (!game || game.phase !== 'drawing') return;

    const playerIdx = getPlayerIndex(game, socket);
    if (playerIdx === -1) return;

    const player = game.players[playerIdx];
    if (player.submitted) return;

    const { x, y, colorIndex } = data;
    if (typeof x !== 'number' || typeof y !== 'number' || typeof colorIndex !== 'number') return;
    if (x < 0 || x >= GRID_SIZE || y < 0 || y >= GRID_SIZE) return;
    if (colorIndex < -1 || colorIndex > 2) return;

    player.grid[y][x] = colorIndex;
}

function handleClearBoard(socket) {
    const gameId = socketToGame.get(socket);
    if (!gameId) return;
    const game = games[gameId];
    if (!game || game.phase !== 'drawing') return;

    const playerIdx = getPlayerIndex(game, socket);
    if (playerIdx === -1) return;

    const player = game.players[playerIdx];
    if (player.submitted) return;

    player.grid = createEmptyGrid();
}

function handleSubmit(socket) {
    const gameId = socketToGame.get(socket);
    if (!gameId) return;
    const game = games[gameId];
    if (!game || game.phase !== 'drawing') return;

    const playerIdx = getPlayerIndex(game, socket);
    if (playerIdx === -1) return;

    const player = game.players[playerIdx];
    if (player.submitted) return;

    player.submitted = true;

    // Notify opponent
    const opponent = getOpponent(game, socket);
    sendToSocket(opponent.socket, { type: 'opponent_submitted' });

    // If both submitted, end early
    if (game.players.every(p => p.submitted)) {
        clearTimeout(game.timer);
        endDrawingPhase(gameId);
    }
}

function endDrawingPhase(gameId) {
    const game = games[gameId];
    if (!game || game.phase !== 'drawing') return;

    if (game.timer) {
        clearTimeout(game.timer);
        game.timer = null;
    }

    startGuessingPhase(gameId);
}

// ============================================
// GUESSING PHASE
// ============================================

function startGuessingPhase(gameId) {
    const game = games[gameId];
    if (!game) return;

    game.phase = 'guessing';

    for (let i = 0; i < 2; i++) {
        const player = game.players[i];
        const opponent = game.players[1 - i];
        player.guess = null;

        // Show opponent's drawing (but NOT their theme - that's what you guess)
        sendToSocket(player.socket, {
            type: 'guessing_start',
            opponentGrid: opponent.grid,
            opponentColors: opponent.colors,
            opponentName: opponent.username,
        });
    }
}

function handleGuess(socket, data) {
    const gameId = socketToGame.get(socket);
    if (!gameId) return;
    const game = games[gameId];
    if (!game || game.phase !== 'guessing') return;

    const playerIdx = getPlayerIndex(game, socket);
    if (playerIdx === -1) return;

    const player = game.players[playerIdx];
    if (player.guess !== null) return;

    const { guess } = data;
    if (typeof guess !== 'string' || guess.trim().length === 0) return;

    player.guess = guess.trim().substring(0, 50); // Cap length

    // Notify opponent that you've guessed
    const opponent = getOpponent(game, socket);
    sendToSocket(opponent.socket, { type: 'opponent_guessed' });

    // If both guessed, resolve
    if (game.players.every(p => p.guess !== null)) {
        resolveGame(gameId);
    }
}

// ============================================
// RESULTS
// ============================================

function isGuessCorrect(guess, actualTheme) {
    return guess.toLowerCase().trim() === actualTheme.toLowerCase().trim();
}

async function resolveGame(gameId) {
    const game = games[gameId];
    if (!game) return;

    game.phase = 'results';

    // Check correctness: player[i] guessed opponent[1-i]'s theme
    const p0GuessedCorrectly = isGuessCorrect(game.players[0].guess, game.players[1].theme);
    const p1GuessedCorrectly = isGuessCorrect(game.players[1].guess, game.players[0].theme);

    // Determine winner: if both correct or both wrong = draw, otherwise the one who guessed right wins
    let winner = -1; // -1 = draw
    if (p0GuessedCorrectly && !p1GuessedCorrectly) winner = 0;
    else if (p1GuessedCorrectly && !p0GuessedCorrectly) winner = 1;
    // else draw (both correct or both wrong)

    // Update database
    try {
        for (let i = 0; i < 2; i++) {
            const player = game.players[i];
            if (winner === -1) {
                await pool.query('UPDATE users SET draws = draws + 1 WHERE user_id = $1', [player.userId]);
            } else if (winner === i) {
                await pool.query('UPDATE users SET wins = wins + 1 WHERE user_id = $1', [player.userId]);
            } else {
                await pool.query('UPDATE users SET losses = losses + 1 WHERE user_id = $1', [player.userId]);
            }
        }

        // Save game history
        await pool.query(
            `INSERT INTO game_history (game_id, player1_id, player2_id, winner_id, theme, player1_grid, player2_grid)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [
                gameId,
                game.players[0].userId,
                game.players[1].userId,
                winner === -1 ? null : game.players[winner].userId,
                game.players[0].theme + ' / ' + game.players[1].theme,
                JSON.stringify(game.players[0].grid),
                JSON.stringify(game.players[1].grid)
            ]
        );
    } catch (e) {
        console.error('DB update error:', e.message);
    }

    // Fetch updated stats and send results
    for (let i = 0; i < 2; i++) {
        const player = game.players[i];
        const opponentIdx = 1 - i;
        const opponent = game.players[opponentIdx];

        let stats = { wins: 0, losses: 0, draws: 0 };
        try {
            const res = await pool.query('SELECT wins, losses, draws FROM users WHERE user_id = $1', [player.userId]);
            if (res.rows.length > 0) stats = res.rows[0];
        } catch (e) {
            console.error('Stats fetch error:', e.message);
        }

        const myGuessCorrect = (i === 0) ? p0GuessedCorrectly : p1GuessedCorrectly;
        const opponentGuessCorrect = (i === 0) ? p1GuessedCorrectly : p0GuessedCorrectly;

        sendToSocket(player.socket, {
            type: 'results',
            winner,
            yourIndex: i,
            // Your drawing info
            yourGrid: player.grid,
            yourColors: player.colors,
            yourTheme: player.theme,
            // Opponent's drawing info
            opponentGrid: opponent.grid,
            opponentColors: opponent.colors,
            opponentTheme: opponent.theme,
            opponentName: opponent.username,
            // Guessing results
            yourGuess: player.guess,
            opponentGuess: opponent.guess,
            yourGuessCorrect: myGuessCorrect,
            opponentGuessCorrect: opponentGuessCorrect,
            stats
        });
    }

    // Reset rematch flags
    game.rematch = [false, false];
}

// ============================================
// REMATCH / EXIT
// ============================================

function handleRematch(socket) {
    const gameId = socketToGame.get(socket);
    if (!gameId) return;
    const game = games[gameId];
    if (!game || game.phase !== 'results') return;

    const playerIdx = getPlayerIndex(game, socket);
    if (playerIdx === -1) return;

    game.rematch[playerIdx] = true;

    // Notify opponent
    const opponent = getOpponent(game, socket);
    sendToSocket(opponent.socket, { type: 'opponent_wants_rematch' });

    // If both want rematch, start new round
    if (game.rematch.every(r => r)) {
        const [theme1, theme2] = getTwoUniqueThemes();
        game.phase = 'color_pick';
        game.colorPickRound = 0;
        game.rematch = [false, false];

        game.players[0].theme = theme1;
        game.players[1].theme = theme2;

        for (let i = 0; i < 2; i++) {
            const p = game.players[i];
            p.colors = [];
            p.grid = createEmptyGrid();
            p.submitted = false;
            p.guess = null;
        }

        sendToSocket(game.players[0].socket, { type: 'rematch_start', theme: theme1 });
        sendToSocket(game.players[1].socket, { type: 'rematch_start', theme: theme2 });

        startColorPickRound(gameId);
    }
}

function handleExit(socket) {
    const gameId = socketToGame.get(socket);
    if (!gameId) return;
    const game = games[gameId];
    if (!game) return;

    const opponent = getOpponent(game, socket);
    sendToSocket(opponent.socket, { type: 'opponent_left' });

    cleanupGame(gameId);
}

// ============================================
// DISCONNECT
// ============================================

async function handleDisconnect(socket) {
    // Remove from queue
    const queueIdx = matchQueue.findIndex(q => q.socket === socket);
    if (queueIdx !== -1) {
        matchQueue.splice(queueIdx, 1);
    }

    // Handle in-game disconnect
    const gameId = socketToGame.get(socket);
    if (!gameId) return;

    const game = games[gameId];
    if (!game) {
        socketToGame.delete(socket);
        return;
    }

    const playerIdx = getPlayerIndex(game, socket);
    if (playerIdx === -1) {
        socketToGame.delete(socket);
        return;
    }

    const opponent = getOpponent(game, socket);

    // If game is active (not results), opponent wins by forfeit
    if (game.phase !== 'results') {
        const opponentIdx = 1 - playerIdx;

        try {
            await pool.query('UPDATE users SET wins = wins + 1 WHERE user_id = $1', [opponent.userId]);
            await pool.query('UPDATE users SET losses = losses + 1 WHERE user_id = $1', [game.players[playerIdx].userId]);
        } catch (e) {
            console.error('Forfeit DB error:', e.message);
        }

        let stats = { wins: 0, losses: 0, draws: 0 };
        try {
            const res = await pool.query('SELECT wins, losses, draws FROM users WHERE user_id = $1', [opponent.userId]);
            if (res.rows.length > 0) stats = res.rows[0];
        } catch (e) {
            console.error('Stats fetch error:', e.message);
        }

        sendToSocket(opponent.socket, {
            type: 'opponent_left',
            forfeit: true,
            stats
        });
    } else {
        sendToSocket(opponent.socket, { type: 'opponent_left' });
    }

    cleanupGame(gameId);
}

// ============================================
// MESSAGE ROUTER
// ============================================

function handleMessage(socket, data) {
    switch (data.action) {
        case 'queue':
            // Prevent duplicate queue entries
            if (matchQueue.some(q => q.socket === socket)) return;
            if (socketToGame.has(socket)) return;
            matchQueue.push({ socket, userId: socket.userId, username: socket.username });
            sendToSocket(socket, { type: 'queued' });
            handleQueue();
            break;

        case 'cancel_queue': {
            const idx = matchQueue.findIndex(q => q.socket === socket);
            if (idx !== -1) matchQueue.splice(idx, 1);
            sendToSocket(socket, { type: 'queue_cancelled' });
            break;
        }

        case 'pick_color':
            handlePickColor(socket, data);
            break;

        case 'draw':
            handleDraw(socket, data);
            break;

        case 'clear_board':
            handleClearBoard(socket);
            break;

        case 'submit':
            handleSubmit(socket);
            break;

        case 'guess':
            handleGuess(socket, data);
            break;

        case 'rematch':
            handleRematch(socket);
            break;

        case 'exit':
            handleExit(socket);
            break;

        default:
            break;
    }
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
        CREATE TABLE IF NOT EXISTS game_history (
            id SERIAL PRIMARY KEY,
            game_id TEXT NOT NULL,
            player1_id TEXT NOT NULL,
            player2_id TEXT NOT NULL,
            winner_id TEXT,
            theme TEXT NOT NULL,
            player1_grid JSONB,
            player2_grid JSONB,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `);

    // Safe migrations for existing users table
    try {
        await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS wins INTEGER DEFAULT 0');
        await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS losses INTEGER DEFAULT 0');
        await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS draws INTEGER DEFAULT 0');
        console.log('Schema migration complete');
    } catch (e) {
        console.log('Schema migration note:', e.message);
    }

    // ==================
    // REST API
    // ==================

    // Upsert user
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

    // Get user with stats
    fastify.get('/api/user/:userId', async (req, reply) => {
        const { userId } = req.params;
        try {
            const res = await pool.query(
                'SELECT username, wins, losses, draws FROM users WHERE user_id = $1',
                [userId]
            );
            if (res.rows.length === 0) {
                return { username: null, wins: 0, losses: 0, draws: 0 };
            }
            return res.rows[0];
        } catch (e) {
            fastify.log.error('DB Get Error: ' + e.message);
            return { username: null, wins: 0, losses: 0, draws: 0 };
        }
    });

    // Serve Client (health check page)
    fastify.get('/', async (req, reply) => {
        reply.type('text/html');
        return '<h1>Pixel Duel Server</h1><p>Server is running.</p>';
    });

    // ==================
    // WEBSOCKET
    // ==================

    fastify.get('/ws', { websocket: true }, (connection, req) => {
        const socket = connection;
        const { userId, username } = req.query;

        socket.userId = userId || 'anon';
        socket.username = username || 'Anonymous';

        socket.on('message', (message) => {
            try {
                const data = JSON.parse(message.toString());
                handleMessage(socket, data);
            } catch (e) {
                fastify.log.error('Message parse error: ' + e.message);
            }
        });

        socket.on('close', () => {
            handleDisconnect(socket);
        });
    });
});

// ============================================
// START
// ============================================

const start = async () => {
    try {
        const PORT = process.env.PORT || 3000;
        await fastify.listen({ port: PORT, host: '0.0.0.0' });
        console.log(`Pixel Duel server started on http://localhost:${PORT}`);
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};
start();
