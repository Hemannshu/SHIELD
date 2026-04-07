# Script to remove JAVA_HOME from System Environment Variables
# MUST RUN AS ADMINISTRATOR

Write-Host "=== Removing JAVA_HOME from System Environment ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To run as admin:" -ForegroundColor Yellow
    Write-Host "1. Right-click PowerShell" -ForegroundColor White
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "3. Navigate to this directory" -ForegroundColor White
    Write-Host "4. Run: .\remove_java_home_system.ps1" -ForegroundColor White
    exit 1
}

# Get current system JAVA_HOME
$currentJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
Write-Host "Current System JAVA_HOME: $currentJavaHome" -ForegroundColor Yellow

if ($currentJavaHome) {
    Write-Host ""
    Write-Host "Removing JAVA_HOME from System environment..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $null, "Machine")
    Write-Host "✓ JAVA_HOME removed from System environment" -ForegroundColor Green
    Write-Host ""
    Write-Host "Please restart your terminal/IDE for changes to take effect." -ForegroundColor Cyan
} else {
    Write-Host "JAVA_HOME is not set at system level." -ForegroundColor Green
}

Write-Host ""
Write-Host "After restarting, run: flutter run -d JF89OBS8IRRW69ON" -ForegroundColor Green





