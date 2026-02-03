@echo off
echo Starting Backend Server...
start "LiveServer Backend" npm start --prefix ..

echo Starting Flutter Windows App...
flutter run -d windows
pause
