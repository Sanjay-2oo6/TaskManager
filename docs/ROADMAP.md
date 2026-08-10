# Task Manager: Phase 3 Enterprise Roadmap

This document serves as the technical specification and execution roadmap for Phase 3. 

## 🛡️ Development & Safety Protocols
**CRITICAL**: The application is currently LIVE with real users, tasks, and submissions. These rules must be followed during implementation:

1.  **Iterative Development**: We will implement features **one by one**. Each feature must be tested and verified before moving to the next.
2.  **Data Identification (Prefixing)**: All data created for testing (Users, Tasks, Messages) must be prefixed with **`TEST_`** (e.g., Task Title: `TEST_Pipeline Verification`). This allows for safe bulk-deletion of test junk later.
3.  **No Mutation of Live Data**: Never edit or delete existing production data.
4.  **Backend Backward Compatibility**: Any change to schemas must not break existing records already in the database.
5.  **State Verification**: After each change, we will confirm that the core login and task list functionality still works for the current live users.

---

## 🚨 PHASE 0: SECURITY HARDENING (CRITICAL - DO FIRST)
**Objective: Fix critical vulnerabilities before ANY new features. DO NOT PROCEED TO PHASE 1 UNTIL COMPLETE.**

**Status**: BLOCKING - Must be completed before feature development

### Security Issues to Fix (From Professional Audit)

**CRITICAL (5 issues - Fix in 24-48 hours):**

#### 0.1 Rotate All Production Secrets
- **Issue**: MongoDB, AWS, JWT, Firebase credentials exposed in `.env` file in Git
- **Action**:
  1. MongoDB Atlas: Delete exposed user, create new admin with strong password
  2. AWS: Revoke exposed access keys, generate new pair
  3. Firebase: Generate new service account private key
  4. JWT: Generate new random secret (use: `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`)
- **Timeline**: 2 hours
- **Verification**: Test all new credentials in development environment

#### 0.2 Remove Secrets from Git History
- **Issue**: `.env` file committed to Git history is permanently accessible
- **Action**:
  1. Use `git-filter-repo` to remove `.env` from all commits
  2. Force push to repository
  3. Verify secrets are gone: `git log --all --full-history -- server/.env`
- **Timeline**: 2 hours
- **Verification**: No secrets visible in Git history

#### 0.3 Implement File Upload Validation
- **Issue**: No file type validation - RCE via malicious file upload
- **File**: `server/utils/upload.js`
- **Action**:
  1. Add MIME type whitelist (JPEG, PNG, PDF only)
  2. Verify file extension matches MIME type
  3. Check magic numbers to prevent spoofed files
  4. Sanitize filenames to prevent path traversal
- **Timeline**: 1.5 hours
- **Testing**: Attempt to upload `.exe`, `.sh`, `.php` files - all should be rejected
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #1

#### 0.4 Add Rate Limiting on Auth Endpoints
- **Issue**: No brute force protection on login
- **File**: `server/app.js`, `server/routes/authRoutes.js`
- **Action**:
  1. Install `express-rate-limit`
  2. Add 5 attempts per 15 minutes on `/auth/login`
  3. Add 10 accounts per hour on `/auth/users` (create user)
  4. General API limit: 100 requests per minute
- **Timeline**: 1.5 hours
- **Testing**: Call login endpoint 6 times rapidly - 6th should get 429 Too Many Requests
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #2

#### 0.5 Fix Authorization Bypass on Submissions
- **Issue**: Any authenticated user can approve/reject submissions
- **File**: `server/controllers/submissionController.js`
- **Action**:
  1. Add authorization check on `getSubmission()` - only admin/assigner or employee who submitted
  2. Add authorization check on `getSubmissionsByTaskId()` - only admin or assigned employees
  3. Verify role on `updateSubmissionStatus()` - only admin/assigner can approve/reject
- **Timeline**: 1 hour
- **Testing**: Login as employee, try to access/approve another employee's submission - should get 403 Forbidden
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #3

**HIGH (6 issues - Fix in 1 week):**

#### 0.6 Add Input Sanitization
- **Issue**: XSS via notification bodies
- **Files**: `server/services/notificationService.js`, `server/controllers/submissionController.js`
- **Action**:
  1. Install `sanitize-html`
  2. Sanitize all user input before sending notifications
  3. Remove HTML tags from task titles, names, messages
- **Timeline**: 2 hours
- **Testing**: Add `<script>alert('xss')</script>` in task title - should be stripped
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #4

#### 0.7 Implement Pagination
- **Issue**: No pagination - memory exhaustion DoS on large data sets
- **Files**: `server/controllers/taskController.js`, `server/controllers/submissionController.js`
- **Action**:
  1. Add `page` and `limit` query parameters to all list endpoints
  2. Default limit: 20, max limit: 100
  3. Return pagination metadata: `{ current_page, page_size, total_items, total_pages, has_next, has_prev }`
- **Timeline**: 3 hours
- **Testing**: Fetch `/api/v1/tasks?page=1&limit=20` - should return pagination metadata
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #5

#### 0.8 Fix Message Access Control
- **Issue**: Employees can read messages from tasks they're not assigned to
- **File**: `server/controllers/messageController.js`
- **Action**:
  1. Verify user is assigned to task before returning messages
  2. Return 403 if user doesn't have access
  3. Add to `getMessagesByTask()` function
- **Timeline**: 1 hour
- **Testing**: Login as employee A, try to read messages from task only assigned to employee B - should get 403 Forbidden
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #6

#### 0.9 Add HTTPS Certificate Pinning (Flutter)
- **Issue**: MITM attacks on public WiFi
- **File**: `lib/data/services/api_client.dart`
- **Action**:
  1. Extract server certificate public key
  2. Implement certificate pinning in Dio HTTP client
  3. Fail if certificate doesn't match pinned key
- **Timeline**: 4 hours
- **Testing**: Attempt MITM with self-signed cert - should be rejected
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #3

#### 0.10 Improve Password Requirements
- **Issue**: 6-character password is too weak
- **File**: `server/controllers/authController.js`
- **Action**:
  1. Require minimum 12 characters
  2. Require uppercase, lowercase, numbers, symbols
  3. Use `password-validator` library
- **Timeline**: 1.5 hours
- **Testing**: Try password "test123" - should be rejected; try "Test@1234567" - should be accepted
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #8

**MEDIUM (7 issues - Fix in 2 weeks):**

#### 0.11 Setup Structured Logging
- **Issue**: No observability - no logs for security events
- **Files**: All backend files
- **Action**:
  1. Install `winston` or `pino`
  2. Log security events: failed logins, authorization failures, unusual patterns
  3. Log all admin actions with timestamps and user IDs
  4. Store logs in files/cloud (not just console)
- **Timeline**: 4 hours
- **Testing**: Check logs after failed login attempt, submission approval - should see entries
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #10

#### 0.12 Add S3 Security Hardening
- **Issue**: S3 uploads not encrypted, no integrity checks
- **File**: `server/services/s3Service.js`
- **Action**:
  1. Enable server-side encryption (AES256)
  2. Add file hash metadata
  3. Force `Content-Disposition: attachment` to prevent inline execution
- **Timeline**: 2 hours
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #7

#### 0.13 Environment-Specific Configuration
- **Issue**: Development settings used in production
- **File**: `server/app.js`
- **Action**:
  1. Validate required environment variables on startup
  2. Use strict CORS only in production
  3. Disable morgan logging in production
  4. Add strict security headers (HSTS, CSP)
- **Timeline**: 2 hours
- **Reference**: See `CODE_FIXES_READY_TO_APPLY.md` - FIX #9

#### 0.14 Add Request Validation Middleware
- **Issue**: No validation of query/body parameters
- **File**: Create `server/middleware/validationMiddleware.js`
- **Action**:
  1. Install `joi` or `express-validator`
  2. Validate all incoming requests
  3. Reject invalid data early
- **Timeline**: 3 hours

#### 0.15 Database Security Hardening
- **Issue**: No indices on username (timing attack enumeration)
- **File**: `server/models/User.js`
- **Action**:
  1. Ensure username has unique index
  2. Add indices on frequently queried fields
- **Timeline**: 1 hour

#### 0.16 Implement Request Signing (Optional but Recommended)
- **Issue**: No HMAC verification on API requests
- **Action**:
  1. Add HMAC-SHA256 signing on sensitive requests
  2. Verify signature on backend
- **Timeline**: 4 hours
- **Priority**: Medium (implement if resources available)

**LOW (2 issues - Fix in 3 weeks):**

#### 0.17 Add Monitoring & Alerting
- **Issue**: No real-time alerts for security issues
- **Action**:
  1. Setup Prometheus metrics
  2. Configure alerting for failed logins, 5xx errors, rate limit hits
- **Timeline**: 6 hours

#### 0.18 Comprehensive Error Handling
- **Issue**: Stack traces leaked in production errors
- **File**: `server/app.js`
- **Action**:
  1. Never expose stack traces to clients
  2. Log full error details server-side only
  3. Return generic "Internal server error" to clients
- **Timeline**: 2 hours

---

### Phase 0 Completion Checklist

**Before moving to Phase 1, ALL of these must be complete:**

- [ ] All secrets rotated and verified working
- [ ] Secrets removed from Git history
- [ ] File upload validation implemented and tested
- [ ] Rate limiting enabled on auth endpoints
- [ ] Authorization checks added to all sensitive endpoints
- [ ] Input sanitization added to notifications
- [ ] Pagination implemented on all list endpoints
- [ ] Message access control fixed
- [ ] HTTPS certificate pinning implemented
- [ ] Password requirements strengthened
- [ ] Structured logging configured
- [ ] S3 encryption enabled
- [ ] Environment-specific configuration implemented
- [ ] Request validation middleware added
- [ ] Database indices optimized
- [ ] Error handling improved
- [ ] Monitoring/alerting setup (optional but recommended)
- [ ] All tests passing
- [ ] No security warnings in build
- [ ] Code review completed by security team

**Estimated Total Time**: 2.5 weeks (106 hours)
**Team Size**: 2-3 developers recommended
**Security Sign-off Required**: YES - Cannot proceed to Phase 1 without security team approval

---

---


## 🏗️ Phase 1: Foundation, UX & Security
*Objective: Solidify the platform’s core stability and session management.*

### 1. Persistent Session Mastery (Lazy 7-Day Expiry)
*   **Detail**: Move from "Memory-only" sessions to "Secure Persistent" sessions with a 7-day "Check-on-Launch" policy.
*   **Implementation**:
    - Use `shared_preferences` to cache the JWT and the `lastLoginTimestamp`.
    - **Startup logic**: App shows Splash Screen -> Checks Cache.
    - **The 7-Day Rule**: If `currentTime - lastLoginTimestamp > 7 Days`, clear cache and force Login.
*   **"Usage Extension" Logic**: 
    - If the user is actively using the app when the 7-day mark hits, the app **will NOT kick them out**.
    - The expiration check only happens when the app is restarted. This ensures work is never interrupted mid-session.
*   **Edge Cases**:
    - **Server-Side Revoke**: If the admin deletes the user's account while they are logged in, the standard 401 Interceptor will still handle the logout for security.

### 2. Intelligent Back-Button / Swipe Protection
*   **Implementation**: Use `PopScope` (Flutter 3.16+) or `WillPopScope`.
*   **Logic**:
    - If on `HomeScreen` index 0 (Dashboard), first back-press shows a `SnackBar`: *"Press back again to exit"*.
    - If pressed again within 2 seconds, exit.
*   **Edge Case**:
    - **Platform Difference**: Ensure this doesn't block "Forward" navigation or standard "Pop" from sub-pages (like Task Details).

### 3. [ADMIN ONLY] Secure Task Deletion
*   **Implementation**: 
    - Backend: `DELETE /api/v1/tasks/:id`.
    - Authorization: Ensure only `admin` or `master` can call this. 
*   **Edge Cases & Handling**:
    - **Dependencies**: If Task B depends on Task A (Sequential), deleting A must either (a) Delete B or (b) Unblock B with a warning.
    - **Orphan Submissions**: Deleting a task must also clean up (or archive) its S3 file references to save costs.

---

## 💬 Phase 2: Collaboration & Feedback
*Objective: Bridging the communication gap between Managers and Operators.*

### 4. Task-Specific Live Chat
*   **Detail**: Real-time Socket.io communication.
*   **Implementation**:
    - Backend: `Message` schema: `{ taskId, senderId, text, timestamp }`.
    - Socket Rooms: `socket.join('task_${taskId}')`.
*   **Alerting logic**: When a message arrives, checked if the user is *currently* looking at that chat. If not, trigger a **local local-style notification**.
*   **Edge Cases**:
    - **Offline Sync**: If a user sends a message while offline, it must be queued in the "Hive Sync Queue" and sent when the internet returns.
    - **Large History**: Only load the last 50 messages; use "Scroll to load more" to prevent memory crashes on old tasks.

### 5. Submission-Specific Comments
*   **Detail**: A thread attached specifically to the "Proof of Work".
*   **Logic**: Unlike the Task Chat (general questions), these are "Review Comments".
*   **Edge Case**:
    - **Closure**: Once a task is "Completed", comments should become read-only to prevent historical revisionism.

---

## 🛠️ Phase 3: Advanced Pipeline Logic
*Objective: Dynamic workflows, task editing, and sequential triggers.*

### 6. [ADMIN ONLY] Dynamic Task Editing
*   **Implementation**: Toggle "Read-only" mode in `TaskDetailScreen` to "Edit Mode".
*   **Edge Case**:
    - **Concurrent Edits**: If two admins edit the same task, use a "Success" or "Refetch" logic so the last one doesn't overwrite without awareness.
    - **Editing Active Tasks**: Changing priority on an active task should trigger an immediate notification to all assignees.

### 7. [ADMIN ONLY] Sequential Workflows (Pipelines)
*   **Implementation**: `dependsOn` field in the Task model.
*   **Behavior**:
    - Task B is created with `status: "waiting"`.
    - Person B sees the task but cannot click "Submit Proof". The UI shows: *"Waiting for Task A completion"*.
*   **Automation**: When Task A is "Authorized" (Approved) -> Code triggers a search for any tasks where `dependsOn == taskA.id` -> Sets them to `pending` -> Blasts a notification to the next person.
*   **Edge Case**:
    - **Rejection Cascade**: If Task A is approved, then Task B starts, but then Task A's approval is *revoked* (if allowed), Task B must be re-blocked.

### 8. [ADMIN ONLY] Rejection Reasoning & Recovery
*   **Implementation**: Mandatory text field on Rejection.
*   **Feature**: "Reassign on Reject". A checkbox to either keep the person or pick someone else.
*   **Edge Case**:
    - Ensure the previous worker can see the "Reason" in their archive so they understand why they failed.

### 8.5. Employee Reference File Viewing
*   **Implementation**: Show Admin-uploaded reference files directly within the `ProofUploadScreen`.
*   **Benefit**: Ensures employees have necessary context/resources while actively submitting their proof.

---

## 🎨 Phase 4: Enterprise Audit & Distribution
*Objective: Transparency and remote updates.*

### 9. Admin Action Audit Trail
*   **Implementation**: Log metadata on every status change.
    - `lastModifiedBy: "Admin Sanjay"`, `modifiedAt: [Date]`.
*   **Visibility**: Dedicated "History" log in Task Detail visible to all admins.

### 10. In-App Updates (OTA - Over The Air)
*   **Simple Implementation**: 
    - Server hosts a `version.json` (e.g., `{"version": "1.0.5", "url": "..."}`).
    - App compares its internal version. If lower, shows a non-dismissible (or optional) update banner.
*   **Edge Case**:
    - **Breaking Changes**: If Version 2.0 changes the DB schema, force the update so the app doesn't crash on old logic.

---

## 📊 Global Constraints & Missed Details
*   **File Size Limits**: Backend must limit S3 uploads (e.g., max 20MB per file) to prevent server timeouts.
*   **Empty States**: Clear "No messages yet" or "Waiting for tasks" drawings instead of blank screens.
*   **Deep linking**: Clicking a "New Message" notification should take the user directly to THAT task's chat tab, not just the home screen.

---

## 📋 COMPLETE DEVELOPMENT TIMELINE

```
Phase 0: SECURITY HARDENING (2.5 weeks - 106 hours)
├─ CRITICAL fixes: 24-48 hours
├─ HIGH fixes: 1 week
├─ MEDIUM fixes: 2 weeks
└─ Testing & sign-off: 3 days

Phase 1: Foundation, UX & Security (2 weeks)
├─ Persistent Sessions: 1 week
├─ Back-button Protection: 2 days
└─ Secure Task Deletion: 3 days

Phase 2: Collaboration & Feedback (1 week)
├─ Live Task Chat: 3 days
└─ Submission Comments: 2 days















Phase 3: Advanced Pipeline Logic (2 weeks)
├─ Dynamic Task Editing: 2 days
├─ Sequential Workflows: 1 week
├─ Rejection Reasoning: 2 days
└─ Reference File Viewing: 1 day

Phase 4: Enterprise Audit & Distribution (1 week)
├─ Admin Audit Trail: 2 days
└─ In-App Updates (OTA): 3 days

Testing & QA: 2 weeks

TOTAL TIMELINE: 11 weeks to production-ready
```

---

## ⚠️ CRITICAL REMINDERS

1. **DO NOT SKIP PHASE 0** - Security issues MUST be fixed before any feature development
2. **Get Security Sign-off** before proceeding to Phase 1
3. **Test with live users** - Use TEST_ prefix for all test data
4. **One feature at a time** - Verify and test before moving to next feature
5. **Document changes** - Update this roadmap as you progress
6. **Backup frequently** - Database and Git history

---

## 📚 REFERENCE DOCUMENTS

- `PROFESSIONAL_SECURITY_AUDIT_REPORT.md` - Complete audit with all 20 findings
- `REMEDIATION_QUICK_START.md` - Step-by-step fix instructions
- `CODE_FIXES_READY_TO_APPLY.md` - Copy-paste ready code implementations
- `AUDIT_EXECUTIVE_SUMMARY.md` - High-level overview for stakeholders

---

**Last Updated**: 2026-07-04  
**Status**: COMPLETE AND READY FOR IMPLEMENTATION  
**Next Action**: Begin Phase 0 Security Hardening
