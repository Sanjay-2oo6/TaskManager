# Test File Upload Security
Write-Host "🧪 Testing File Upload Validation" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Create test files
Write-Host "1. Creating test files..." -NoNewline
"fake malware executable" | Out-File -FilePath "test_malware.exe" -Encoding ASCII
"valid image content" | Out-File -FilePath "test_image.jpg" -Encoding ASCII
"../../../etc/passwd" | Out-File -FilePath "..\..\..\..\etc\passwd.txt" -Encoding ASCII
Write-Host " ✅" -ForegroundColor Green

# Login to get token
Write-Host "2. Logging in to get auth token..." -NoNewline
$loginPayload = '{"username":"admin","password":"admin123"}' | Out-File -FilePath "temp_login.json" -Encoding ASCII
$loginResponse = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" --data "@temp_login.json"
$token = ($loginResponse | ConvertFrom-Json).data.token

if ($null -eq $token) {
    Write-Host " ❌ Login failed!" -ForegroundColor Red
    Write-Host "Response: $loginResponse"
    Write-Host ""
    Write-Host "ℹ️  Note: Make sure you have an admin account with username 'admin' and password 'admin123'" -ForegroundColor Yellow
    Write-Host "   Or manually create a user and update this script with correct credentials" -ForegroundColor Yellow
    exit 1
}
Write-Host " ✅ Token received" -ForegroundColor Green

Write-Host ""
Write-Host "3. Testing file uploads..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Upload .exe file (should FAIL)
Write-Host "   Test 1: Uploading .exe file (should reject)..." -NoNewline
$response1 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions `
    -H "Authorization: Bearer $token" `
    -F "taskId=000000000000000000000001" `
    -F "description=Test malicious file" `
    -F "beforeFiles=@test_malware.exe"

if ($response1 -like "*not allowed*" -or $response1 -like "*File type*") {
    Write-Host " ✅ REJECTED (PASS)" -ForegroundColor Green
} else {
    Write-Host " ❌ ACCEPTED (FAIL)" -ForegroundColor Red
    Write-Host "   Response: $response1" -ForegroundColor Yellow
}

# Test 2: Upload valid image (should SUCCEED or fail with different error)
Write-Host "   Test 2: Uploading .jpg file (should accept or fail with non-file-type error)..." -NoNewline
$response2 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions `
    -H "Authorization: Bearer $token" `
    -F "taskId=000000000000000000000001" `
    -F "description=Test valid file" `
    -F "beforeFiles=@test_image.jpg"

if ($response2 -like "*not allowed*" -or $response2 -like "*File type*") {
    Write-Host " ❌ FILE TYPE REJECTED (FAIL)" -ForegroundColor Red
    Write-Host "   Response: $response2" -ForegroundColor Yellow
} else {
    Write-Host " ✅ FILE TYPE ACCEPTED (PASS)" -ForegroundColor Green
    Write-Host "   Note: May still fail due to task not found, but file validation passed" -ForegroundColor Gray
}

# Test 3: Path traversal (should FAIL)
Write-Host "   Test 3: Uploading file with path traversal name..." -NoNewline
$response3 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions `
    -H "Authorization: Bearer $token" `
    -F "taskId=000000000000000000000001" `
    -F "description=Test path traversal" `
    -F "beforeFiles=@..\..\..\..\etc\passwd.txt"

if ($response3 -like "*Invalid filename*" -or $response3 -like "*path traversal*") {
    Write-Host " ✅ BLOCKED (PASS)" -ForegroundColor Green
} elseif ($response3 -like "*not allowed*" -or $response3 -like "*File type*") {
    Write-Host " ✅ BLOCKED BY FILE TYPE (PASS)" -ForegroundColor Green
} else {
    Write-Host " ❌ ACCEPTED (FAIL)" -ForegroundColor Red
    Write-Host "   Response: $response3" -ForegroundColor Yellow
}

# Cleanup
Write-Host ""
Write-Host "4. Cleaning up test files..." -NoNewline
Remove-Item "test_malware.exe" -ErrorAction SilentlyContinue
Remove-Item "test_image.jpg" -ErrorAction SilentlyContinue
Remove-Item "..\..\..\..\etc\passwd.txt" -ErrorAction SilentlyContinue
Remove-Item "temp_login.json" -ErrorAction SilentlyContinue
Write-Host " ✅" -ForegroundColor Green

Write-Host ""
Write-Host "✅ File upload validation test complete!" -ForegroundColor Cyan
