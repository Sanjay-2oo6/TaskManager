# Phase 2 - Test Cases

## Unit Tests

### Backend - Task Controller
```bash
# Test dependency validation
npm test -- taskController.createTask --grep "circular dependency"
npm test -- taskController.createTask --grep "dependency validation"

# Test org validation
npm test -- taskController --grep "organization access"
```

### Backend - Submission Controller
```bash
# Test resubmission
npm test -- submissionController.createSubmission --grep "resubmission after rejection"
npm test -- submissionController.updateSubmissionStatus --grep "rejection feedback"
```

### Backend - Message Controller
```bash
# Test org filtering
npm test -- messageController --grep "organization filter"
npm test -- messageController.getMessages --grep "authorization check"
```

### Frontend - Sync Service
```bash
# Test offline queue
flutter test lib/data/services/sync_service_test.dart --grep "addToQueue"
flutter test lib/data/services/sync_service_test.dart --grep "processQueue"
flutter test lib/data/services/sync_service_test.dart --grep "organizationId"
```

### Frontend - Task Providers
```bash
# Test rejection card logic
flutter test lib/state/task_providers_test.dart --grep "rejection card"
flutter test lib/state/task_providers_test.dart --grep "socket listener"
```

---

## Integration Tests

### Workflow 1: Admin Task Creation
1. Admin logs in
2. Opens Create Task
3. **Verify:** Member dropdown shows team members ✅
4. Admin fills form + assigns to member
5. **Verify:** Task appears in member's list ✅
6. **Verify:** Socket.IO broadcasts task-updated event ✅

### Workflow 2: Member Submission
1. Member logs in
2. Opens assigned task
3. Clicks "Submit Work"
4. Uploads files + description
5. **Verify:** Task status → "SUBMITTED" ✅
6. **Verify:** Admin receives notification ✅
7. **Verify:** Task removed from member's pending tab ✅

### Workflow 3: Rejection & Resubmission
1. Admin opens Admin Review
2. Reviews member's submission
3. Clicks "REJECT" with feedback
4. **Verify:** Member sees rejection card ✅
5. Member clicks "Resubmit"
6. Uploads new files
7. **Verify:** Task shows "SUBMITTED" (NOT "pending") ✅
8. **Verify:** Rejection card disappears ✅
9. **Verify:** Admin sees new submission notification ✅

### Workflow 4: Offline Sync
1. Enable airplane mode
2. Member submits work
3. **Verify:** "Queued offline" message appears ✅
4. **Verify:** Files stored in local cache ✅
5. Disable airplane mode
6. **Verify:** "Syncing..." notification shows ✅
7. **Verify:** Submission syncs to server ✅
8. **Verify:** No 400/403 errors in logs ✅
9. **Verify:** organizationId sent in payload ✅

### Workflow 5: Real-Time Collaboration
1. User A opens task detail
2. User B opens same task
3. User A sends message
4. **Verify:** User B sees message immediately ✅
5. **Verify:** No refresh needed ✅
6. User B replies
7. **Verify:** User A sees reply instantly ✅
8. **Verify:** Read receipts show (✓✓) ✅

### Workflow 6: Multi-Tenant Isolation
1. Org A admin logs in
2. Tries to access Org B task via URL hack
3. **Verify:** 403 Unauthorized ✅
4. Org A member cannot see Org B members
5. **Verify:** Member list empty for Org B ✅
6. Socket.IO join-task validates org
7. **Verify:** Cannot join chat for wrong org ✅

### Workflow 7: File Viewing
1. Task has admin reference files
2. Member opens task detail
3. **Verify:** Files show as clickable cards ✅
4. Click image file
5. **Verify:** Opens in image viewer (not download) ✅
6. Click PDF file
7. **Verify:** Opens in browser (not auto-download) ✅

### Workflow 8: Task Dependencies
1. Create Task A
2. Create Task B (depends on Task A)
3. **Verify:** Task B shows "locked" status ✅
4. Member completes Task A
5. Admin approves Task A
6. **Verify:** Task B unlocked automatically ✅
7. **Verify:** Member notified task unlocked ✅
8. Try to create circular dependency
9. **Verify:** 400 error "Circular dependency" ✅

---

## Performance Tests

### Response Time
- GET /api/v1/users → < 200ms
- GET /api/v1/tasks → < 500ms
- POST /api/v1/submissions → < 2s
- Sync 5 offline submissions → < 10s

### Concurrent Users
- 50 users in same task chat
- **Verify:** Messages broadcast to all ✅
- **Verify:** Read receipts sync ✅
- **Verify:** No message loss ✅

### File Upload
- Upload 5MB file
- **Verify:** Uses 5-min timeout ✅
- **Verify:** S3 upload succeeds ✅
- **Verify:** Signed URL generated ✅

---

## Security Tests

### Organization Boundary
- User A cannot see User B's org data
- Cross-org API calls rejected
- Socket.IO cross-org join blocked
- S3 file access scoped by org

### Input Validation
- XSS attempt in message → sanitized ✅
- SQL injection in search → blocked ✅
- Circular dependency → rejected ✅
- Invalid taskId format → 400 error ✅

### Authentication
- Expired JWT → 401 Unauthorized ✅
- Missing token → 401 required ✅
- Invalid token → 401 rejected ✅
- Logout → token cleared ✅

---

## Database Tests

### Indexes
```javascript
// Verify indexes created
db.tasks_ith.getIndexes()
// Should include: organizationId, assignedTo, status, createdAt
```

### Data Integrity
```javascript
// Check task after resubmission
db.tasks_ith.findOne({_id: ObjectId("...")})
// status should be "submitted" (not "pending")

// Check history
db.tasks_ith.findOne({_id: ObjectId("...")}).history
// Should show: "Resubmitted after rejection"
```

---

## Logging & Monitoring

### Check Logs For
1. No "ERROR" entries for core flows
2. Security log entries for cross-org attempts
3. Request ID in all logs (tracing)
4. API version headers in responses

### Monitor Metrics
- Response times
- Error rates
- User counts
- Message throughput

