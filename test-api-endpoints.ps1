# Complete API Endpoint Test
# Tests the critical task creation flow with authentication

$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:5000/api/v1"

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   TASK MANAGER API INTEGRATION TEST       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Test credentials
$testEmail = "admin@democorp.com"
$testPassword = "Admin123!"

# ============================================================================
# TEST 1: Health Check
# ============================================================================
Write-Host "[1/6] Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get -ErrorAction Stop
    Write-Host "✅ PASS - Server is healthy" -ForegroundColor Green
    Write-Host "   Response: $($health.message)`n" -ForegroundColor Gray
} catch {
    Write-Host "❌ FAIL - Server not responding" -ForegroundColor Red
    Write-Host "   Error: $_`n" -ForegroundColor Red
    exit 1
}

# ============================================================================
# TEST 2: Login
# ============================================================================
Write-Host "[2/6] Testing Login..." -ForegroundColor Yellow
$loginBody = @{
    email = $testEmail
    password = $testPassword
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    $token = $loginResponse.token
    $userId = $loginResponse.user._id
    $userName = $loginResponse.user.name
    
    Write-Host "✅ PASS - Login successful" -ForegroundColor Green
    Write-Host "   User: $userName" -ForegroundColor Gray
    Write-Host "   User ID: $userId" -ForegroundColor Gray
    Write-Host "   Token: $($token.Substring(0,30))...`n" -ForegroundColor Gray
} catch {
    Write-Host "❌ FAIL - Login failed" -ForegroundColor Red
    Write-Host "   Error: $_`n" -ForegroundColor Red
    exit 1
}

# Headers for authenticated requests
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# ============================================================================
# TEST 3: Get Users
# ============================================================================
Write-Host "[3/6] Testing Get Users..." -ForegroundColor Yellow
try {
    $usersResponse = Invoke-RestMethod -Uri "$baseUrl/auth/users" `
        -Method Get `
        -Headers $headers `
        -ErrorAction Stop
    
    $users = $usersResponse.data
    Write-Host "✅ PASS - Retrieved users" -ForegroundColor Green
    Write-Host "   Total users: $($users.Count)" -ForegroundColor Gray
    
    # Pick first user as assignee
    $assigneeId = $users[0]._id
    $assigneeName = $users[0].name
    Write-Host "   Will assign task to: $assigneeName ($assigneeId)`n" -ForegroundColor Gray
} catch {
    Write-Host "❌ FAIL - Failed to get users" -ForegroundColor Red
    Write-Host "   Error: $_`n" -ForegroundColor Red
    exit 1
}

# ============================================================================
# TEST 4: Get Tasks
# ============================================================================
Write-Host "[4/6] Testing Get Tasks..." -ForegroundColor Yellow
try {
    $tasksResponse = Invoke-RestMethod -Uri "$baseUrl/tasks" `
        -Method Get `
        -Headers $headers `
        -ErrorAction Stop
    
    $existingTaskCount = $tasksResponse.data.Count
    Write-Host "✅ PASS - Retrieved tasks" -ForegroundColor Green
    Write-Host "   Existing tasks: $existingTaskCount`n" -ForegroundColor Gray
} catch {
    Write-Host "❌ FAIL - Failed to get tasks" -ForegroundColor Red
    Write-Host "   Error: $_`n" -ForegroundColor Red
    exit 1
}

# ============================================================================
# TEST 5: Create Task (WITHOUT file) - JSON only
# ============================================================================
Write-Host "[5/6] Testing Create Task (No File)..." -ForegroundColor Yellow

$taskData = @{
    title = "API Test Task - No File"
    description = "Testing task creation without file upload"
    assignedTo = @($assigneeId)  # Array with 1 ID
    priority = "medium"
    dueDate = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    adminNote = "Created via PowerShell API test"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/tasks" `
        -Method Post `
        -Headers $headers `
        -Body $taskData `
        -ErrorAction Stop
    
    $createdTask = $createResponse.data
    Write-Host "✅ PASS - Task created successfully" -ForegroundColor Green
    Write-Host "   Task ID: $($createdTask._id)" -ForegroundColor Gray
    Write-Host "   Title: $($createdTask.title)" -ForegroundColor Gray
    Write-Host "   Assigned To: $($createdTask.assignedToNames -join ', ')" -ForegroundColor Gray
    Write-Host "   Status: $($createdTask.status)" -ForegroundColor Gray
    Write-Host "   Priority: $($createdTask.priority)`n" -ForegroundColor Gray
    
    $testTaskId = $createdTask._id
} catch {
    Write-Host "❌ FAIL - Task creation failed" -ForegroundColor Red
    $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "   Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "   Error: $($errorDetails.message)`n" -ForegroundColor Red
    exit 1
}

# ============================================================================
# TEST 6: Create Task (WITH file) - Multipart FormData
# ============================================================================
Write-Host "[6/6] Testing Create Task (With File)..." -ForegroundColor Yellow
Write-Host "   NOTE: This tests the FIXED array encoding issue" -ForegroundColor Cyan

# Create a temporary test file
$testFilePath = Join-Path $env:TEMP "test-reference.txt"
"This is a test reference file created by API test script.`nTimestamp: $(Get-Date)" | Out-File -FilePath $testFilePath -Encoding UTF8

try {
    # Prepare multipart form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    # Build form fields
    $formFields = @{
        title = "API Test Task - With File"
        description = "Testing task creation WITH file upload"
        assignedTo = "[$([char]34)$assigneeId$([char]34)]"  # JSON-encoded: ["id"]
        priority = "high"
        dueDate = (Get-Date).AddDays(3).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        adminNote = "This task includes a file attachment"
    }
    
    # Build multipart body
    $bodyLines = @()
    foreach ($field in $formFields.GetEnumerator()) {
        $bodyLines += "--$boundary"
        $bodyLines += "Content-Disposition: form-data; name=`"$($field.Key)`"$LF"
        $bodyLines += $field.Value
    }
    
    # Add file
    $fileContent = [System.IO.File]::ReadAllBytes($testFilePath)
    $fileName = [System.IO.Path]::GetFileName($testFilePath)
    
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"adminFiles`"; filename=`"$fileName`""
    $bodyLines += "Content-Type: text/plain$LF"
    
    # Convert text parts to bytes
    $bodyString = ($bodyLines -join $LF) + $LF
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyString)
    
    # Combine text and file
    $endBoundary = [System.Text.Encoding]::UTF8.GetBytes("$LF--$boundary--$LF")
    $fullBody = $bodyBytes + $fileContent + $endBoundary
    
    # Update headers for multipart
    $multipartHeaders = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    $createFileResponse = Invoke-RestMethod -Uri "$baseUrl/tasks" `
        -Method Post `
        -Headers $multipartHeaders `
        -Body $fullBody `
        -ErrorAction Stop
    
    $createdFileTask = $createFileResponse.data
    Write-Host "✅ PASS - Task with file created successfully" -ForegroundColor Green
    Write-Host "   Task ID: $($createdFileTask._id)" -ForegroundColor Gray
    Write-Host "   Title: $($createdFileTask.title)" -ForegroundColor Gray
    Write-Host "   Assigned To: $($createdFileTask.assignedToNames -join ', ')" -ForegroundColor Gray
    Write-Host "   Files Attached: $($createdFileTask.adminFiles.Count)" -ForegroundColor Gray
    if ($createdFileTask.adminFiles.Count -gt 0) {
        Write-Host "   File Names: $($createdFileTask.adminFileNames -join ', ')" -ForegroundColor Gray
    }
    Write-Host "`n" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ FAIL - Task with file creation failed" -ForegroundColor Red
    Write-Host "   Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    
    try {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "   Error: $($errorDetails.message)" -ForegroundColor Red
    } catch {
        Write-Host "   Raw Error: $_" -ForegroundColor Red
    }
    Write-Host "`n" -ForegroundColor Gray
} finally {
    # Cleanup temp file
    if (Test-Path $testFilePath) {
        Remove-Item $testFilePath -Force
    }
}

# ============================================================================
# TEST SUMMARY
# ============================================================================
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           TEST SUMMARY                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "✅ Health Check:        PASS" -ForegroundColor Green
Write-Host "✅ Login:               PASS" -ForegroundColor Green
Write-Host "✅ Get Users:           PASS" -ForegroundColor Green
Write-Host "✅ Get Tasks:           PASS" -ForegroundColor Green
Write-Host "✅ Create Task (No File): PASS" -ForegroundColor Green

if ($createdFileTask) {
    Write-Host "✅ Create Task (With File): PASS" -ForegroundColor Green
    Write-Host "`n🎉 ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "`n✨ The array encoding fix is working correctly!" -ForegroundColor Cyan
} else {
    Write-Host "❌ Create Task (With File): FAIL" -ForegroundColor Red
    Write-Host "`n⚠️  Most tests passed, but file upload needs investigation" -ForegroundColor Yellow
}

Write-Host "`n════════════════════════════════════════════`n" -ForegroundColor Cyan
