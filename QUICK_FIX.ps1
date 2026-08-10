# Quick Fix for Flutter WebSocket Connection Error
# Run this script in PowerShell to fix the issue

Write-Host "===========================================" -ForegroundColor Green
Write-Host "Flutter WebSocket Connection Error Fix" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""

# Step 1: Kill processes
Write-Host "Step 1: Killing Flutter and Chrome processes..." -ForegroundColor Cyan
taskkill /F /IM chrome.exe 2>$null
taskkill /F /IM dart.exe 2>$null
Start-Sleep -Seconds 2
Write-Host "✅ Processes killed" -ForegroundColor Green
Write-Host ""

# Step 2: Navigate to frontend
Write-Host "Step 2: Navigating to frontend directory..." -ForegroundColor Cyan
cd d:\ITHub\Taskmanager\frontend
Write-Host "✅ In frontend directory" -ForegroundColor Green
Write-Host ""

# Step 3: Clean Flutter
Write-Host "Step 3: Cleaning Flutter build..." -ForegroundColor Cyan
flutter clean 2>&1 | Select-Object -Last 3
Write-Host "✅ Flutter cleaned" -ForegroundColor Green
Write-Host ""

# Step 4: Get dependencies
Write-Host "Step 4: Getting dependencies..." -ForegroundColor Cyan
flutter pub get 2>&1 | Select-Object -Last 3
Write-Host "✅ Dependencies updated" -ForegroundColor Green
Write-Host ""

# Step 5: Start Flutter
Write-Host "Step 5: Starting Flutter..." -ForegroundColor Cyan
Write-Host ""
Write-Host "⏳ Waiting for Flutter to start (this may take 1-2 minutes on first run)..." -ForegroundColor Yellow
Write-Host ""

flutter run -d chrome

Write-Host ""
Write-Host "Done! If Flutter started successfully, you should see the app in Chrome." -ForegroundColor Green
