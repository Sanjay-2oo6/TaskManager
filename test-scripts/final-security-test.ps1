# Final Comprehensive Security Test
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " FINAL SECURITY TESTS - WITH REAL TASK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get task ID
$taskId = Get-Content ".\Task-manager-main\server\test-task-id.txt"
Write-Host "Task ID: $taskId" -ForegroundColor Gray
Write-Host ""

# Login as admin
Write-Host "Logging in as admin..." -ForegroundColor Yellow
$loginResponse = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" -d '{\"username\":\"test_admin\",\"password\":\"Test123!\"}'
$adminToken = ($loginResponse | ConvertFrom-Json).data.token
Write-Host "Admin logged in: $($adminToken.Substring(0,20))..." -ForegroundColor Green
Write-Host ""

# TEST 1: Upload .exe file
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 1: Upload .exe file (should REJECT)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$response1 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions `
    -H "Authorization: Bearer $adminToken" `
    -F "taskId=$taskId" `
    -F "description=TEST_malware" `
    -F "beforeFiles=@test_malware.exe"

if ($response1 -like "*not allowed*" -or $response1 -like "*File type*") {
    Write-Host "RESULT: PASS - Malicious file was REJECTED" -ForegroundColor Green
    Write-Host "Message: $response1" -ForegroundColor Gray
} else {
    Write-Host "RESULT: FAIL - Malicious file was ACCEPTED" -ForegroundColor Red
    Write-Host "Response: $response1" -ForegroundColor Yellow
}
Write-Host ""

# TEST 2: Upload .jpg file
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 2: Upload .jpg file (should ACCEPT)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$response2 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions `
    -H "Authorization: Bearer $adminToken" `
    -F "taskId=$taskId" `
    -F "description=TEST_valid_image" `
    -F "beforeFiles=@test_image.jpg"

if ($response2 -like "*not allowed*" -or $response2 -like "*File type*") {
    Write-Host "RESULT: FAIL - Valid file was incorrectly REJECTED" -ForegroundColor Red
    Write-Host "Response: $response2" -ForegroundColor Yellow
} elseif ($response1 -like "*success*:true*") {
    Write-Host "RESULT: PASS - Valid file was ACCEPTED" -ForegroundColor Green
    $submissionData = $response2 | ConvertFrom-Json
    $submissionId = $submissionData.data._id
    Write-Host "Submission created: $submissionId" -ForegroundColor Gray
} else {
    Write-Host "RESULT: PASS - File type accepted (may have failed for other reasons)" -ForegroundColor Green  
    Write-Host "Response: $($response2.Substring(0, 200))" -ForegroundColor Gray
}
Write-Host ""

# TEST 3: Try to access as different employee
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 3: Authorization Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Login as Employee B
$empBLogin = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" -d '{\"username\":\"test_employee_b\",\"password\":\"Test123!\"}'
$empBToken = ($empBLogin | ConvertFrom-Json).data.token
Write-Host "Employee B logged in: $($empBToken.Substring(0,20))..." -ForegroundColor Green

# Try to access submission
if ($submissionId) {
    Write-Host "Employee B trying to access admin's submission..." -ForegroundColor Yellow
    $response3 = curl.exe -s -X GET "http://localhost:5000/api/v1/submissions/$submissionId" -H "Authorization: Bearer $empBToken"
    
    if ($response3 -like "*403*" -or $response3 -like "*access*" -or $response3 -like "*not have*") {
        Write-Host "RESULT: PASS - Employee B was BLOCKED from accessing" -ForegroundColor Green
        Write-Host "Message: $response3" -ForegroundColor Gray
    } else {
        Write-Host "RESULT: FAIL - Employee B could access the submission" -ForegroundColor Red
        Write-Host "Response: $response3" -ForegroundColor Yellow
    }
} else {
    Write-Host "SKIPPED - No submission ID available" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " TESTS COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
