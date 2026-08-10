# Test Task Creation with File Upload
# This script tests the fixed array encoding and file upload

$baseUrl = "http://localhost:5000/api/v1"

Write-Host "`n=== Task Manager API Test ===" -ForegroundColor Cyan
Write-Host "Testing: Task creation with 1 assignee + file`n" -ForegroundColor Yellow

# Step 1: Login
Write-Host "[1/3] Logging in..." -ForegroundColor Green
$loginBody = @{
    email = "admin@democorp.com"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json"
    
    $token = $loginResponse.token
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($token.Substring(0,20))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ Login failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Get users to get a valid assignee ID
Write-Host "`n[2/3] Fetching users..." -ForegroundColor Green
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    $usersResponse = Invoke-RestMethod -Uri "$baseUrl/auth/users" `
        -Method Get `
        -Headers $headers
    
    $firstUserId = $usersResponse.data[0]._id
    Write-Host "✅ Got users!" -ForegroundColor Green
    Write-Host "Using assignee: $firstUserId" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to get users: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Create task with 1 assignee (JSON-encoded array)
Write-Host "`n[3/3] Creating task with 1 assignee..." -ForegroundColor Green

# Create a test file
$testFilePath = "$PSScriptRoot\test-file.txt"
"Test reference file content" | Out-File -FilePath $testFilePath -Encoding utf8

try {
    # Prepare form data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    # Read file content
    $fileContent = [System.IO.File]::ReadAllBytes($testFilePath)
    
    # Build multipart form data
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"title`"$LF",
        "Test Task from PowerShell",
        "--$boundary",
        "Content-Disposition: form-data; name=`"description`"$LF",
        "Testing task creation with file upload",
        "--$boundary",
        "Content-Disposition: form-data; name=`"assignedTo`"$LF",
        "[`"$firstUserId`"]",  # JSON-encoded array
        "--$boundary",
        "Content-Disposition: form-data; name=`"priority`"$LF",
        "medium",
        "--$boundary",
        "Content-Disposition: form-data; name=`"dueDate`"$LF",
        (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
        "--$boundary",
        "Content-Disposition: form-data; name=`"adminNote`"$LF",
        "Test note from API",
        "--$boundary",
        "Content-Disposition: form-data; name=`"adminFiles`"; filename=`"test-file.txt`"",
        "Content-Type: text/plain$LF"
    )
    
    $bodyString = ($bodyLines -join $LF) + $LF
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyString)
    
    # Combine body and file
    $fullBody = $bodyBytes + $fileContent + [System.Text.Encoding]::UTF8.GetBytes("$LF--$boundary--$LF")
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    $response = Invoke-RestMethod -Uri "$baseUrl/tasks" `
        -Method Post `
        -Headers $headers `
        -Body $fullBody
    
    Write-Host "✅ Task created successfully!" -ForegroundColor Green
    Write-Host "Task ID: $($response.data._id)" -ForegroundColor Gray
    Write-Host "Title: $($response.data.title)" -ForegroundColor Gray
    Write-Host "Assigned To: $($response.data.assignedTo -join ', ')" -ForegroundColor Gray
    Write-Host "Files: $($response.data.adminFiles.Count) file(s)" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Task creation failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    
    # Try to read response body
    if ($_.Exception.Response) {
        $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
} finally {
    # Cleanup
    if (Test-Path $testFilePath) {
        Remove-Item $testFilePath -Force
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
