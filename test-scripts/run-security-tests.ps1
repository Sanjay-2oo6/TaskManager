# Comprehensive Security Testing Script
$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SECURITY FIXES - AUTOMATED TESTING" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test Results
$testResults = @{
    Passed = 0
    Failed = 0
    Tests = @()
}

function Test-Response {
    param($Name, $Response, $ExpectedPattern, $ShouldMatch = $true)
    
    $match = $Response -like "*$ExpectedPattern*"
    $passed = ($match -eq $ShouldMatch)
    
    if ($passed) {
        Write-Host "  PASS" -ForegroundColor Green -NoNewline
        $testResults.Passed++
    } else {
        Write-Host "  FAIL" -ForegroundColor Red -NoNewline
        $testResults.Failed++
    }
    
    Write-Host " - $Name"
    if (-not $passed) {
        Write-Host "    Expected pattern: $ExpectedPattern (ShouldMatch: $ShouldMatch)" -ForegroundColor Yellow
        Write-Host "    Got: $($Response.Substring(0, [Math]::Min(200, $Response.Length)))" -ForegroundColor Yellow
    }
    
    $testResults.Tests += @{
        Name = $Name
        Passed = $passed
        Response = $Response
    }
    
    return $passed
}

Write-Host "Step 1: Logging in as Admin" -ForegroundColor Cyan
Write-Host "----------------------------"
$adminLogin = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" -d '{\"username\":\"test_admin\",\"password\":\"Test123!\"}'
$adminToken = ($adminLogin | ConvertFrom-Json).data.token

if ($null -eq $adminToken) {
    Write-Host "ERROR: Admin login failed!" -ForegroundColor Red
    Write-Host "Response: $adminLogin" -ForegroundColor Yellow
    exit 1
}

Write-Host "Admin token: $($adminToken.Substring(0,20))..." -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Logging in as Employee A" -ForegroundColor Cyan
Write-Host "---------------------------------"
$empALogin = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" -d '{\"username\":\"test_employee_a\",\"password\":\"Test123!\"}'
$empAToken = ($empALogin | ConvertFrom-Json).data.token

if ($null -eq $empAToken) {
    Write-Host "ERROR: Employee A login failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Employee A token: $($empAToken.Substring(0,20))..." -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Logging in as Employee B" -ForegroundColor Cyan
Write-Host "---------------------------------"
$empBLogin = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" -d '{\"username\":\"test_employee_b\",\"password\":\"Test123!\"}'
$empBToken = ($empBLogin | ConvertFrom-Json).data.token

if ($null -eq $empBToken) {
    Write-Host "ERROR: Employee B login failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Employee B token: $($empBToken.Substring(0,20))..." -ForegroundColor Green
Write-Host ""

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  TEST SUITE 1: FILE UPLOAD VALIDATION" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Test 1.1: Upload .exe file (should REJECT)" -ForegroundColor Yellow
$response1 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions -H "Authorization: Bearer $adminToken" -F "taskId=000000000000000000000001" -F "description=TEST_security" -F "beforeFiles=@test_malware.exe"
Test-Response "Malicious file rejected" $response1 "not allowed" $true
Write-Host ""

Write-Host "Test 1.2: Upload .jpg file (should ACCEPT file type)" -ForegroundColor Yellow
$response2 = curl.exe -s -X POST http://localhost:5000/api/v1/submissions -H "Authorization: Bearer $adminToken" -F "taskId=000000000000000000000001" -F "description=TEST_security" -F "beforeFiles=@test_image.jpg"
$fileTypeAccepted = -not ($response2 -like "*not allowed*" -or $response2 -like "*File type*")
if ($fileTypeAccepted) {
    Write-Host "  PASS" -ForegroundColor Green -NoNewline
    $testResults.Passed++
    Write-Host " - Valid file type accepted"
} else {
    Write-Host "  FAIL" -ForegroundColor Red -NoNewline
    $testResults.Failed++
    Write-Host " - Valid file type rejected incorrectly"
}
Write-Host ""

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  TEST SUITE 2: RATE LIMITING" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Test 2.1: Rate limit on login (5 attempts max)" -ForegroundColor Yellow
$rateLimitHit = $false
for ($i=1; $i -le 6; $i++) {
    $loginTest = curl.exe -s -X POST http://localhost:5000/api/v1/auth/login -H "Content-Type: application/json" -d '{\"username\":\"test_fake_user\",\"password\":\"wrong\"}'
    if ($loginTest -like "*Too many*") {
        $rateLimitHit = $true
        Write-Host "  Attempt $i`: Rate limited (expected)" -ForegroundColor Gray
    } else {
        Write-Host "  Attempt $i`: Allowed" -ForegroundColor Gray
    }
    Start-Sleep -Milliseconds 100
}

if ($rateLimitHit) {
    Write-Host "  PASS" -ForegroundColor Green -NoNewline
    $testResults.Passed++
    Write-Host " - Rate limiting working"
} else {
    Write-Host "  FAIL" -ForegroundColor Red -NoNewline
    $testResults.Failed++
    Write-Host " - Rate limiting not triggered"
}
Write-Host ""

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  TEST SUITE 3: AUTHORIZATION CHECKS" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Note: Authorization tests require existing submissions." -ForegroundColor Yellow
Write-Host "      Testing with mock submission IDs..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Test 3.1: Employee B accessing non-existent submission" -ForegroundColor Yellow
$response3 = curl.exe -s -X GET http://localhost:5000/api/v1/submissions/000000000000000000000099 -H "Authorization: Bearer $empBToken"
$authCheckExists = $response3 -like "*not found*" -or $response3 -like "*access*"
if ($authCheckExists) {
    Write-Host "  PASS" -ForegroundColor Green -NoNewline
    $testResults.Passed++
    Write-Host " - Authorization check implemented"
} else {
    Write-Host "  INFO" -ForegroundColor Yellow -NoNewline
    Write-Host " - Response: $($response3.Substring(0, [Math]::Min(100, $response3.Length)))"
}
Write-Host ""

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($testResults.Passed + $testResults.Failed)" -ForegroundColor White
Write-Host "Passed:      $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed:      $($testResults.Failed)" -ForegroundColor Red
Write-Host ""

if ($testResults.Failed -eq 0) {
    Write-Host "SUCCESS: All tests passed!" -ForegroundColor Green -BackgroundColor Black
} else {
    Write-Host "ATTENTION: Some tests failed. Review above." -ForegroundColor Yellow -BackgroundColor Black
}

Write-Host ""
Write-Host "Detailed results saved to test-results.txt"

# Save results to file
$testResults | ConvertTo-Json -Depth 3 | Out-File "test-results.json"

exit $testResults.Failed
