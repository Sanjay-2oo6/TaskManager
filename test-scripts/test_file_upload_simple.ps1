# Test File Upload Security
Write-Host "Testing File Upload Validation"
Write-Host "==============================="
Write-Host ""

# Create test files
Write-Host "1. Creating test files..."
"fake malware executable" | Out-File -FilePath "test_malware.exe" -Encoding ASCII
"valid image content" | Out-File -FilePath "test_image.jpg" -Encoding ASCII
Write-Host "   Done"

# Login to get token
Write-Host "2. Logging in to get auth token..."
$loginPayload = '{"username":"admin","password":"admin123"}' | Out-File -FilePath "temp_login.json" -Encoding ASCII
$loginResponse = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" --data "@temp_login.json"
$loginData = $loginResponse | ConvertFrom-Json
$token = $loginData.data.token

if ($null -eq $token) {
    Write-Host "   ERROR: Login failed!"
    Write-Host "   Response: $loginResponse"
    Write-Host ""
    Write-Host "   Note: Make sure you have an admin account with username 'admin' and password 'admin123'"
    exit 1
}
Write-Host "   Token received: $($token.Substring(0,20))..."

Write-Host ""
Write-Host "3. Testing file uploads..."
Write-Host ""

# Test 1: Upload .exe file (should FAIL)
Write-Host "   Test 1: Uploading .exe file (should reject)..."
$response1 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions -H "Authorization: Bearer $token" -F "taskId=000000000000000000000001" -F "description=Test malicious file" -F "beforeFiles=@test_malware.exe"

if ($response1 -like "*not allowed*" -or $response1 -like "*File type*") {
    Write-Host "   PASS: File was rejected"
} else {
    Write-Host "   FAIL: File was accepted"
    Write-Host "   Response: $response1"
}

# Test 2: Upload valid image
Write-Host ""
Write-Host "   Test 2: Uploading .jpg file..."
$response2 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions -H "Authorization: Bearer $token" -F "taskId=000000000000000000000001" -F "description=Test valid file" -F "beforeFiles=@test_image.jpg"

if ($response2 -like "*not allowed*" -or $response2 -like "*File type*") {
    Write-Host "   FAIL: Valid file type was rejected"
    Write-Host "   Response: $response2"
} else {
    Write-Host "   PASS: File type validation passed"
    Write-Host "   Note: May still fail due to invalid task ID, but file validation worked"
}

# Cleanup
Write-Host ""
Write-Host "4. Cleaning up..."
Remove-Item "test_malware.exe" -ErrorAction SilentlyContinue
Remove-Item "test_image.jpg" -ErrorAction SilentlyContinue
Remove-Item "temp_login.json" -ErrorAction SilentlyContinue
Write-Host "   Done"

Write-Host ""
Write-Host "Test complete!"
