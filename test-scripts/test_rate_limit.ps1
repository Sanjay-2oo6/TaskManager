Write-Host "🧪 Testing Login Rate Limiting (5 attempts per 15 min)"
Write-Host "================================================"
Write-Host ""

for ($i=1; $i -le 6; $i++) {
    Write-Host "Attempt $i..." -NoNewline
    $response = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" --data "@test_login_payload.json"
    
    if ($response -like "*Too many*") {
        Write-Host " ❌ RATE LIMITED!" -ForegroundColor Red
        Write-Host "Response: $response" -ForegroundColor Yellow
    } elseif ($response -like "*Invalid credentials*") {
        Write-Host " ✅ Request allowed (wrong password)" -ForegroundColor Green
    } else {
        Write-Host " Response: $response"
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "✅ Test complete! Attempt 6 should be rate limited."
