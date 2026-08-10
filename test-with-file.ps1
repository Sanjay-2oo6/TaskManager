# Test Task Creation with File Upload
Write-Host "Testing task creation with 1 assignee + file..." -ForegroundColor Cyan

# Login
$login = Invoke-RestMethod -Uri "http://localhost:5000/api/v1/auth/login" -Method Post -Body '{"email":"testadminorg@ith.com","password":"Test123!"}' -ContentType "application/json"
$token = $login.data.token

# Get users
$users = Invoke-RestMethod -Uri "http://localhost:5000/api/v1/auth/users" -Headers @{"Authorization"="Bearer $token"}
$assigneeId = $users.data[1]._id  # Use member 1
Write-Host "Assignee: $($users.data[1].name) ($assigneeId)"

# Create test file
$testFile = "$env:TEMP\test-ref.txt"
"Test reference file - $(Get-Date)" | Out-File $testFile -Encoding UTF8

# Build multipart form data
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

# Form fields
$fields = @"
--$boundary
Content-Disposition: form-data; name="title"$LF
Task with File Upload Test
--$boundary
Content-Disposition: form-data; name="description"$LF
Testing file upload with 1 assignee
--$boundary
Content-Disposition: form-data; name="assignedTo"$LF
["$assigneeId"]
--$boundary
Content-Disposition: form-data; name="priority"$LF
high
--$boundary
Content-Disposition: form-data; name="dueDate"$LF
$((Get-Date).AddDays(5).ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))
--$boundary
Content-Disposition: form-data; name="adminNote"$LF
Test note with file
"@

# File content
$fileBytes = [System.IO.File]::ReadAllBytes($testFile)
$fileHeader = @"
--$boundary
Content-Disposition: form-data; name="adminFiles"; filename="test-ref.txt"
Content-Type: text/plain$LF
"@

# End boundary
$endBoundary = "$LF--$boundary--$LF"

# Combine all parts
$fieldsBytes = [System.Text.Encoding]::UTF8.GetBytes($fields)
$fileHeaderBytes = [System.Text.Encoding]::UTF8.GetBytes($fileHeader)
$endBytes = [System.Text.Encoding]::UTF8.GetBytes($endBoundary)

$body = $fieldsBytes + $fileHeaderBytes + $fileBytes + $endBytes

# Send request
try {
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    $result = Invoke-RestMethod -Uri "http://localhost:5000/api/v1/tasks" -Method Post -Headers $headers -Body $body
    
    Write-Host "`n✅ SUCCESS! Task with file created:" -ForegroundColor Green
    Write-Host "Task ID: $($result.data._id)"
    Write-Host "Title: $($result.data.title)"
    Write-Host "Assigned To: $($result.data.assignedToNames -join ', ')"
    Write-Host "Files: $($result.data.adminFiles.Count) file(s)"
    Write-Host "File Names: $($result.data.adminFileNames -join ', ')"
    
} catch {
    Write-Host "`n❌ FAILED!" -ForegroundColor Red
    Write-Host "Error: $_"
    if ($_.ErrorDetails) {
        Write-Host "Details: $($_.ErrorDetails.Message)"
    }
} finally {
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
}
