const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:3000/ws/test-lobby?role=player');

ws.on('open', () => {
    console.log('Connected!');
    // Send INC
    ws.send(JSON.stringify({ action: 'INC' }));
});

ws.on('message', (data) => {
    console.log('Received:', data.toString());
    // If we get data, it works!
    // We expect initial state, then an update.
    // Close after a brief moment.
    setTimeout(() => {
        ws.close();
        process.exit(0);
    }, 500);
});

ws.on('error', (err) => {
    console.error('Connection Error:', err);
    process.exit(1);
});

ws.on('close', (code, reason) => {
    console.log(`Closed: ${code} ${reason}`);
});
