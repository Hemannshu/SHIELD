@echo off
REM Batch script to start the SHEild Flutter app
REM This script sets up the environment and runs the app

echo ========================================
echo    SHEild App - Startup Script
echo ========================================
echo.

REM Add Flutter to PATH for this session
set PATH=%PATH%;C:\src\flutter\bin

REM Navigate to project directory
cd /d "%~dp0"

echo Checking Flutter installation...
flutter --version
echo.

echo Checking available devices...
flutter devices
echo.

echo Starting the app...
echo Press Ctrl+C to stop the app
echo.

REM Run the app (will use the first available device)
flutter run

pause


