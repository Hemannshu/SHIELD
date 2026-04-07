# Fix JAVA_HOME for Flutter/Android Development
# This script provides multiple solutions

Write-Host "=== Fixing JAVA_HOME for Flutter/Android ===" -ForegroundColor Cyan
Write-Host ""

# Solution 1: Remove invalid JAVA_HOME and let Gradle use bundled JDK
Write-Host "Solution 1: Removing invalid JAVA_HOME..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("JAVA_HOME", $null, "User")
$env:JAVA_HOME = $null
Write-Host "✓ JAVA_HOME removed" -ForegroundColor Green
Write-Host ""

# Solution 2: Check if we can use system Java
Write-Host "Solution 2: Checking system Java..." -ForegroundColor Yellow
try {
    $javaPath = (Get-Command java -ErrorAction SilentlyContinue).Source
    if ($javaPath) {
        Write-Host "✓ Found Java at: $javaPath" -ForegroundColor Green
        $javaDir = Split-Path (Split-Path $javaPath)
        Write-Host "  Java directory: $javaDir" -ForegroundColor Gray
    } else {
        Write-Host "✗ Java not found in PATH" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Java not found in PATH" -ForegroundColor Red
}
Write-Host ""

# Solution 3: Instructions for manual JDK installation
Write-Host "=== RECOMMENDED: Install Java 17 JDK ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option A: Download from Adoptium (Eclipse Temurin)" -ForegroundColor Yellow
Write-Host "  1. Visit: https://adoptium.net/temurin/releases/?version=17" -ForegroundColor White
Write-Host "  2. Download: Windows x64 JDK 17 (.msi installer)" -ForegroundColor White
Write-Host "  3. Run the installer" -ForegroundColor White
Write-Host "  4. JAVA_HOME will be set automatically" -ForegroundColor White
Write-Host ""
Write-Host "Option B: Use Chocolatey (if installed)" -ForegroundColor Yellow
Write-Host "  choco install temurin17jdk" -ForegroundColor White
Write-Host ""
Write-Host "Option C: Use Scoop (if installed)" -ForegroundColor Yellow
Write-Host "  scoop install temurin17-jdk" -ForegroundColor White
Write-Host ""

# Solution 4: Configure Gradle to use a specific JDK
Write-Host "=== Alternative: Configure Gradle directly ===" -ForegroundColor Cyan
Write-Host "You can set JAVA_HOME in gradle.properties:" -ForegroundColor Yellow
Write-Host "  File: android/gradle.properties" -ForegroundColor White
Write-Host "  Add: org.gradle.java.home=C:/path/to/jdk" -ForegroundColor White
Write-Host ""

Write-Host "=== Current Status ===" -ForegroundColor Cyan
Write-Host "JAVA_HOME: $env:JAVA_HOME" -ForegroundColor $(if ($env:JAVA_HOME) { "Yellow" } else { "Green" })
Write-Host ""
Write-Host "Try running 'flutter run' now. If it still fails, install Java 17 JDK using Option A above." -ForegroundColor Green

