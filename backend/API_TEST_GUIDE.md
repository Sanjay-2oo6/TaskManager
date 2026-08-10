
# 🧪 API TEST GUIDE

**Base URL:** `http://localhost:5000`  
**Headers:** `Content-Type: application/json`

---

## 📝 TEST SEQUENCE

### PHASE 1: AUTHENTICATION
**Objective:** Test login, user creation, and 7-day session persistence

#### 1.1 Create Test User
```bash
POST /api/v1/auth/create-user
Content-Type: application/json

{
  "name": "TEST_Employee",
  "email": "test_emp_001@ith.com",
  "password": "TestPassword@123",
  "role": "member"
}
```
**Expected:** 201, new user created  
**Verify:** User ID returned, role is "member"

#### 1.2 Login with Test User
```bash
POST /api/v1/auth/login
{
  "email": "test_emp_001@ith.com",
  "password": "TestPassword@123"
}
```
**Expected:** 200, JWT token returned  
**Verify:** Token valid, user has lastLoginTimestamp

#### 1.3 Get User Profile (Session Test)
```bash
GET /api/v1/auth/me
Authorization: Bearer [TOKEN]
```
**Expected:** 200, user profile returned  
**Verify:** Session working, 7-day persistence initialized

---

### PHASE 2: TASK MANAGEMENT
**Objective:** Test task CRUD operations and authorization

#### 2.1 Create Task (Admin Only)
```bash
POST /api/v1/tasks
Authorization: Bearer [ADMIN_TOKEN]

{
  "title": "TEST_Task_001",
  "description": "Test task for validation",
  "assignedTo": ["[USER_ID]"],
  "dueDate": "2026-07-30",
  "priority": "high"
}
```
**Expected:** 201, task created  
**Verify:** Task ID returned, status is "pending"

#### 2.2 Get User's Tasks
```bash
GET /api/v1/tasks/my-tasks?page=1&limit=10
Authorization: Bearer [TOKEN]
```
**Expected:** 200, paginated task list  
**Verify:** Pagination working (page, limit, total, skip)

#### 2.3 Update Task
```bash
PATCH /api/v1/tasks/[TASK_ID]
Authorization: Bearer [ADMIN_TOKEN]

{
  "status": "in-progress",
  "adminNote": "TEST_Note_for_task"
}
```
**Expected:** 200, task updated  
**Verify:** Status changed, history logged

#### 2.4 Unauthorized Task Delete (Non-Admin)
```bash
DELETE /api/v1/tasks/[TASK_ID]
Authorization: Bearer [EMPLOYEE_TOKEN]
```
**Expected:** 403, Forbidden  
**Verify:** Authorization check working ✅ FIX 2.1

---

### PHASE 3: SUBMISSIONS
**Objective:** Test submission lifecycle and comments

#### 3.1 Create Submission
```bash
POST /api/v1/submissions
Authorization: Bearer [EMPLOYEE_TOKEN]
Content-Type: multipart/form-data

{
  "taskId": "[TASK_ID]",
  "description": "TEST_Submission_proof",
  "beforeFiles": [file1],
  "afterFiles": [file2]
}
```
**Expected:** 201, submission created  
**Verify:** Status is "pending", files uploaded to S3

#### 3.2 Add Submission Comment
```bash
POST /api/v1/submissions/[SUBMISSION_ID]/comments
Authorization: Bearer [TOKEN]

{
  "text": "TEST_Comment_from_reviewer"
}
```
**Expected:** 201, comment added  
**Verify:** Comment attached to submission ✅ FIX 1.0

#### 3.3 Get Submission Comments (With Pagination)
```bash
GET /api/v1/submissions/[SUBMISSION_ID]/comments?page=1&limit=20
Authorization: Bearer [TOKEN]
```
**Expected:** 200, paginated comments  
**Verify:** Pagination implemented ✅ FIX 2.0

#### 3.4 Unauthorized Comment Access
```bash
GET /api/v1/submissions/[SUBMISSION_ID]/comments
Authorization: Bearer [OTHER_USER_TOKEN]
```
**Expected:** 403, Forbidden  
**Verify:** Authorization check working ✅ FIX 0.8

---

### PHASE 4: MESSAGES & NOTIFICATIONS
**Objective:** Test messaging, read status, and mark-as-read

#### 4.1 Get Messages for Task
```bash
GET /api/v1/messages/task/[TASK_ID]
Authorization: Bearer [TOKEN]
```
**Expected:** 200, message list  
**Verify:** Only authorized users see messages ✅ FIX 0.8

#### 4.2 Mark Messages as Read
```bash
PATCH /api/v1/messages/task/[TASK_ID]/mark-read
Authorization: Bearer [TOKEN]
```
**Expected:** 200, marked count returned  
**Verify:** No race conditions with concurrent requests ✅ FIX 3.0

#### 4.3 Get Unread Counts
```bash
GET /api/v1/messages/unread-counts
Authorization: Bearer [TOKEN]
```
**Expected:** 200, unread counts by task  
**Verify:** Accurate counts for user's accessible tasks

---

### PHASE 5: SECURITY TESTS
**Objective:** Validate all security implementations

#### 5.1 Input Sanitization
```bash
POST /api/v1/tasks
Authorization: Bearer [ADMIN_TOKEN]

{
  "title": "<script>alert('XSS')</script>",
  "description": "<!-- HTML comment -->Normal text"
}
```
**Expected:** 201, but malicious code sanitized  
**Verify:** Scripts removed, safe HTML only ✅ FIX 0.6

#### 5.2 Password Strength Validation
```bash
POST /api/v1/auth/create-user

{
  "name": "Test",
  "username": "test",
  "password": "weak",
  "role": "employee"
}
```
**Expected:** 400, weak password rejected  
**Verify:** Requires uppercase, number, special char ✅ FIX 0.10

#### 5.3 Rate Limiting
```bash
# Send 20 requests rapidly to any endpoint
GET /api/v1/tasks?page=1
```
**Expected:** 429 after limit exceeded  
**Verify:** Rate limiting active ✅ FIX 0.1

#### 5.4 Circular Dependency Detection
```bash
PATCH /api/v1/tasks/[TASK_A]/dependencies
Authorization: Bearer [ADMIN_TOKEN]

{
  "dependsOn": ["[TASK_B]"]
}
# Where TASK_B already depends on TASK_A
```
**Expected:** 400, circular dependency prevented  
**Verify:** Pre-save validation working ✅ FIX 3.1

---

### PHASE 6: CODE QUALITY TESTS
**Objective:** Verify refactoring and logging improvements

#### 6.1 Structured Logging
Check server logs for:
```
✅ logger.debug() - Audit logs present
✅ logger.security() - Security events logged
✅ logger.error() - Errors properly logged
✅ logger.auth() - Auth events logged
✅ NO console.* statements visible
```
**Verify:** All logging structured ✅ FIX 0.11

#### 6.2 Authorization Helper Usage
Verify in code:
- `isAdminOrAssigner()` used consistently
- No hardcoded role checks remaining
- `getAdminUsers()` used for queries

**Expected:** All auth checks use helpers ✅ REFACTORING

---

## 📊 Test Results Template

```
TEST RESULTS - [DATE]
═══════════════════════════════════════════════════════════════

PHASE 1: AUTHENTICATION
  ✅ User creation
  ✅ Login with session
  ✅ 7-day persistence initialized
  ✅ Get user profile

PHASE 2: TASK MANAGEMENT
  ✅ Create task (admin only)
  ✅ Get tasks with pagination
  ✅ Update task
  ✅ Authorization check (delete blocked)
  ✅ Circular dependency prevented

PHASE 3: SUBMISSIONS
  ✅ Create submission with files
  ✅ Add comments to submission
  ✅ Get comments with pagination
  ✅ Authorization check (comments)

PHASE 4: MESSAGES
  ✅ Get messages for task
  ✅ Mark as read (no race condition)
  ✅ Get unread counts
  ✅ Authorization check (message access)

PHASE 5: SECURITY
  ✅ Input sanitization (XSS blocked)
  ✅ Password strength validation
  ✅ Rate limiting
  ✅ Circular dependency detection

PHASE 6: CODE QUALITY
  ✅ Structured logging verified
  ✅ Authorization helpers used
  ✅ No console statements
  ✅ Syntax validated

OVERALL STATUS: ✅ ALL TESTS PASSED
═══════════════════════════════════════════════════════════════
```

---

## 🧪 Quick Manual Test Commands

### Using cURL
```bash
# Test endpoint health
curl http://localhost:5000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test login with email
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@ith.com","password":"Test123!"}'

# Test task creation
curl -X POST http://localhost:5000/api/v1/tasks \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Test task"}'
```

### Using Postman
1. Set Base URL: `http://localhost:5000`
2. Create variables for TOKEN and USER_ID
3. Import test collection from requests folder
4. Run tests in sequence

---

## ✅ Sign-Off Checklist

Before deploying to team:
- [ ] All authentication tests pass
- [ ] All task management tests pass
- [ ] All submission tests pass
- [ ] All message tests pass
- [ ] All security tests pass
- [ ] All code quality checks pass
- [ ] No console errors in logs
- [ ] Structured logging working
- [ ] Database indexes created
- [ ] S3 uploads working
- [ ] Firebase notifications working
- [ ] Socket.IO real-time updates working

---

**Test Date:** _________  
**Tester:** _________  
**Result:** ☐ PASS ☐ FAIL  
**Notes:** _________________________________

