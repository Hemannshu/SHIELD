# PowerShell script to add Flutter to system PATH permanently
# Run this script as Administrator

$flutterPath = "C:\src\flutter\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -notlike "*$flutterPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$flutterPath", "User")
    Write-Host "Flutter has been added to your user PATH." -ForegroundColor Green
    Write-Host "Please restart your terminal/IDE for changes to take effect." -ForegroundColor Yellow
} else {
    Write-Host "Flutter is already in your PATH." -ForegroundColor Green
}

# Also add to current session
$env:Path += ";$flutterPath"
Write-Host "Flutter added to current session PATH." -ForegroundColor Green


