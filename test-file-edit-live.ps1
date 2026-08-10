$ErrorActionPreference = "Stop"

$baseUrl = "https://task-manager-cagq.onrender.com/api/v1"
$email = "admin@democorp.com"
$password = "Admin123!"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TASK REFERENCE FILE EDIT AUTOMATED TEST" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Login
Write-Host "`n[1/5] Authenticating as Admin ($email)..." -ForegroundColor Yellow
$loginBody = @{ email = $email; password = $password } | ConvertTo-Json
try {
    $loginRes = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
    $token = $loginRes.token
    $userId = $loginRes.user._id
    Write-Host "✅ Logged in successfully. Token acquired." -ForegroundColor Green
} catch {
    Write-Host "❌ Login failed." -ForegroundColor Red
    if ($_.ErrorDetails) { Write-Host $_.ErrorDetails.Message } else { Write-Host $_ }
    exit 1
}

$headers = @{ "Authorization" = "Bearer $token" }

# 2. Create Task with Initial Reference File
Write-Host "`n[2/5] Creating initial Task with 1 Reference File..." -ForegroundColor Yellow

$testFilePath1 = Join-Path $env:TEMP "initial_ref_file.txt"
"Initial Reference File Content - $(Get-Date)" | Out-File -FilePath $testFilePath1 -Encoding UTF8

$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$formFields = @{
    title = "Automated Test Task - Ref File Edit"
    description = "Testing task reference file upload, edit, add, and delete"
    assignedTo = "[`"$userId`"]"
    priority = "high"
    dueDate = (Get-Date).AddDays(5).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

$bodyLines = @()
foreach ($field in $formFields.GetEnumerator()) {
    $bodyLines += "--$boundary"
    $bodyLines += "Content-Disposition: form-data; name=`"$($field.Key)`"$LF"
    $bodyLines += $field.Value
}

$file1Bytes = [System.IO.File]::ReadAllBytes($testFilePath1)
$file1Name = "initial_ref_file.txt"

$bodyLines += "--$boundary"
$bodyLines += "Content-Disposition: form-data; name=`"adminFiles`"; filename=`"$file1Name`""
$bodyLines += "Content-Type: text/plain$LF"

$bodyString = ($bodyLines -join $LF) + $LF
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyString)
$endBoundary = [System.Text.Encoding]::UTF8.GetBytes("$LF--$boundary--$LF")
$fullBody = $bodyBytes + $file1Bytes + $endBoundary

$multipartHeaders = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "multipart/form-data; boundary=$boundary"
}

$createRes = Invoke-RestMethod -Uri "$baseUrl/tasks" -Method Post -Headers $multipartHeaders -Body $fullBody
$taskId = $createRes.data._id
$initialFilesCount = $createRes.data.adminFiles.Count

Write-Host "✅ Task created! ID: $taskId" -ForegroundColor Green
Write-Host "   Files count after creation: $initialFilesCount" -ForegroundColor Gray
Write-Host "   Initial file keys/urls: $($createRes.data.adminFiles -join ', ')" -ForegroundColor Gray

# Get initial file key for deletion test
$initialFileRaw = $createRes.data.adminFiles[0]
$initialFileKey = if ($initialFileRaw -match "references/[^?]+") { $matches[0] } else { $initialFileRaw }
Write-Host "   Extracted S3 Key for future deletion: $initialFileKey" -ForegroundColor Cyan

# 3. Edit Task: Add a NEW Reference File
Write-Host "`n[3/5] Editing Task: Adding a SECOND Reference File..." -ForegroundColor Yellow

$testFilePath2 = Join-Path $env:TEMP "added_ref_file.txt"
"Second Added Reference File Content - $(Get-Date)" | Out-File -FilePath $testFilePath2 -Encoding UTF8

$boundary2 = [System.Guid]::NewGuid().ToString()
$formFields2 = @{
    title = "Automated Test Task - Ref File Edit (Updated Title)"
    description = "Updated description with second reference file"
}

$bodyLines2 = @()
foreach ($field in $formFields2.GetEnumerator()) {
    $bodyLines2 += "--$boundary2"
    $bodyLines2 += "Content-Disposition: form-data; name=`"$($field.Key)`"$LF"
    $bodyLines2 += $field.Value
}

$file2Bytes = [System.IO.File]::ReadAllBytes($testFilePath2)
$file2Name = "added_ref_file.txt"

$bodyLines2 += "--$boundary2"
$bodyLines2 += "Content-Disposition: form-data; name=`"adminFiles`"; filename=`"$file2Name`""
$bodyLines2 += "Content-Type: text/plain$LF"

$bodyString2 = ($bodyLines2 -join $LF) + $LF
$bodyBytes2 = [System.Text.Encoding]::UTF8.GetBytes($bodyString2)
$endBoundary2 = [System.Text.Encoding]::UTF8.GetBytes("$LF--$boundary2--$LF")
$fullBody2 = $bodyBytes2 + $file2Bytes + $endBoundary2

$multipartHeaders2 = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "multipart/form-data; boundary=$boundary2"
}

$updateRes1 = Invoke-RestMethod -Uri "$baseUrl/tasks/$taskId" -Method Put -Headers $multipartHeaders2 -Body $fullBody2
$filesCountAfterAdd = $updateRes1.data.adminFiles.Count

Write-Host "✅ Task updated with second file." -ForegroundColor Green
Write-Host "   Files count after adding: $filesCountAfterAdd" -ForegroundColor Gray
Write-Host "   Files list: $($updateRes1.data.adminFiles -join ', ')" -ForegroundColor Gray

if ($filesCountAfterAdd -ge 2) {
    Write-Host "   RESULT: Adding new reference file during edit PASSED ✅" -ForegroundColor Green
} else {
    Write-Host "   RESULT: Adding new reference file FAILED ❌ (Count is $filesCountAfterAdd)" -ForegroundColor Red
}

# 4. Edit Task: Delete the FIRST Reference File using filesToDelete
Write-Host "`n[4/5] Editing Task: Deleting the FIRST Reference File ($initialFileKey)..." -ForegroundColor Yellow

$boundary3 = [System.Guid]::NewGuid().ToString()
$filesToDeleteJson = "[`"$initialFileKey`"]"

$formFields3 = @{
    filesToDelete = $filesToDeleteJson
}

$bodyLines3 = @()
foreach ($field in $formFields3.GetEnumerator()) {
    $bodyLines3 += "--$boundary3"
    $bodyLines3 += "Content-Disposition: form-data; name=`"$($field.Key)`"$LF"
    $bodyLines3 += $field.Value
}

$bodyString3 = ($bodyLines3 -join $LF) + $LF + "--$boundary3--$LF"
$fullBody3 = [System.Text.Encoding]::UTF8.GetBytes($bodyString3)

$multipartHeaders3 = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "multipart/form-data; boundary=$boundary3"
}

$updateRes2 = Invoke-RestMethod -Uri "$baseUrl/tasks/$taskId" -Method Put -Headers $multipartHeaders3 -Body $fullBody3
$filesCountAfterDelete = $updateRes2.data.adminFiles.Count

Write-Host "✅ Task updated after deletion request." -ForegroundColor Green
Write-Host "   Files count after delete: $filesCountAfterDelete" -ForegroundColor Gray
Write-Host "   Remaining files: $($updateRes2.data.adminFiles -join ', ')" -ForegroundColor Gray

if ($filesCountAfterDelete -lt $filesCountAfterAdd) {
    Write-Host "   RESULT: File deletion during edit PASSED ✅" -ForegroundColor Green
} else {
    Write-Host "   RESULT: File deletion during edit FAILED ❌ (Count remained $filesCountAfterDelete)" -ForegroundColor Red
}

# 5. Fetch fresh task detail to verify persistence
Write-Host "`n[5/5] Verifying fresh GET /tasks/$taskId response..." -ForegroundColor Yellow
$getRes = Invoke-RestMethod -Uri "$baseUrl/tasks/$taskId" -Method Get -Headers $headers
$finalFilesCount = $getRes.data.adminFiles.Count

Write-Host "✅ Final task state fetched." -ForegroundColor Green
Write-Host "   Final Admin Files Count: $finalFilesCount" -ForegroundColor Gray

# Cleanup temp files
Remove-Item $testFilePath1 -ErrorAction SilentlyContinue
Remove-Item $testFilePath2 -ErrorAction SilentlyContinue

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
