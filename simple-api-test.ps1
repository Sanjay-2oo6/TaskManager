# Simple API Test - Testing Critical Endpoints
$baseUrl = "http://localhost:5000/api/v1"

Write-Host "`n=== TASK MANAGER API TEST ===" -ForegroundColor Cyan

# Test 1: Health
Write-Host "`n[1/5] Health Check..." -ForegroundColor Yellow
$health = Invoke-RestMethod -Uri "http://localhost:5000/health"
Write-Host "Status: $($health.message)" -ForegroundColor Green

# Test 2: Login
Write-Host "`n[2/5] Login..." -ForegroundColor Yellow
$loginBody = @{
    email = "testadminorg@ith.com"
    password = "Test123!"
} | ConvertTo-Json

$login = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $login.token
Write-Host "User: $($login.user.name)" -ForegroundColor Green
Write-Host "Token: $($token.Substring(0,20))..." -ForegroundColor Gray

# Test 3: Get Users
Write-Host "`n[3/5] Get Users..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $token"
}
$users = Invoke-RestMethod -Uri "$baseUrl/auth/users" -Headers $headers
Write-Host "Found $($users.data.Count) users" -ForegroundColor Green
$assigneeId = $users.data[0]._id
Write-Host "Will use assignee: $($users.data[0].name) ($assigneeId)" -ForegroundColor Gray

# Test 4: Get Tasks
Write-Host "`n[4/5] Get Tasks..." -ForegroundColor Yellow
$tasks = Invoke-RestMethod -Uri "$baseUrl/tasks" -Headers $headers
Write-Host "Found $($tasks.data.Count) existing tasks" -ForegroundColor Green

# Test 5: Create Task (No File) - JSON
Write-Host "`n[5/5] Create Task (JSON only)..." -ForegroundColor Yellow
$taskBody = @{
    title = "PowerShell Test Task"
    description = "Testing from PowerShell"
    assignedTo = @($assigneeId)
    priority = "medium"
    dueDate = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    adminNote = "API test"
} | ConvertTo-Json

$headers["Content-Type"] = "application/json"
try {
    $newTask = Invoke-RestMethod -Uri "$baseUrl/tasks" -Method Post -Headers $headers -Body $taskBody
    Write-Host "SUCCESS! Task created: $($newTask.data.title)" -ForegroundColor Green
    Write-Host "Task ID: $($newTask.data._id)" -ForegroundColor Gray
    Write-Host "Assigned to: $($newTask.data.assignedToNames -join ', ')" -ForegroundColor Gray
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Cyan
