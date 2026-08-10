@echo off
REM Start Flutter on Chrome with clean build
cd /d D:\ITHub\Taskmanager\frontend

echo.
echo ========================================
echo Starting Flutter on Chrome...
echo ========================================
echo.

REM Kill any existing processes
taskkill /F /IM chrome.exe 2>nul
taskkill /F /IM dart.exe 2>nul

REM Wait a moment
timeout /t 2 /nobreak

REM Start fresh
echo Cleaning build files...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo Starting Flutter app on Chrome...
flutter run -d chrome

echo.
echo If you see "Failed to establish connection" error:
echo 1. Press Ctrl+C to stop
echo 2. Close all Chrome windows
echo 3. Run this script again
echo.
pause
