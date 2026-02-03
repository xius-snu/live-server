@echo off
echo Starting Node.js Server in a new window...
start "LiveServer Backend" npm start

echo Starting Flutter App...
cd flutter_app
flutter run -d windows
pause
