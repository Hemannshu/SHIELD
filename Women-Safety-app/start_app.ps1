# PowerShell script to start the SHEild Flutter app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   SHEild App - Startup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Add Flutter to PATH for this session
$env:Path += ";C:\src\flutter\bin"

# Navigate to script directory
Set-Location $PSScriptRoot

Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
Write-Host ""

Write-Host "Checking available devices..." -ForegroundColor Yellow
flutter devices
Write-Host ""

Write-Host "Starting the app..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the app" -ForegroundColor Yellow
Write-Host ""

# Run the app (will use the first available device)
flutter run


