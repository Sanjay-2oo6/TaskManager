# Testing Submission Flow - Quick Reference

## Pre-Test Setup
- ✅ Backend running: `npm run dev` in `backend/` folder
- ✅ APK installed on device(s)
- ✅ Device on same WiFi network as backend server (192.168.29.120)
- ✅ Frontend `.env` has correct `BACKEND_URL=http://192.168.29.120:5000`

## Test Scenario 1: Basic Submission with Files

### Setup
1. Login as **member** (not admin)
2. From dashboard, go to **"My Tasks"** tab
3. Select any **assigned task**

### Test Steps
```
1. Tap "Submit Work" button
2. Select "Before" photo (e.g., from gallery)
3. Select "After" photo  
4. Add optional description: "Test submission"
5. Tap "SUBMIT COMPLETED WORK"
```

### Expected Results ✅
- [ ] Toast: "Submission sent successfully!"
- [ ] App navigates back automatically
- [ ] Task disappears from "My Tasks"
- [ ] Refresh and verify task not in list

### Backend Verification
```bash
# Check logs for successful submission
tail -f backend/logs/combined-*.log | grep "POST /api/v1/submissions"

# Expected log:
# POST /api/v1/submissions 201 {...}
```

### Database Verification (MongoDB)
```javascript
// Connect to MongoDB Compass
// Database: task_manager
// Collection: submissions_ith

// Find the submission:
db.submissions_ith.findOne({}, {sort: {createdAt: -1}})

// Expected fields:
// {
//   _id: ObjectId(...),
//   task: ObjectId(...),
//   employee: ObjectId(...),
//   status: "pending",  // ← IMPORTANT: must be "pending" not something else
//   beforeFiles: ["s3-key-1"],
//   afterFiles: ["s3-key-2"],
//   description: "Test submission",
//   createdAt: ISODate(...)
// }

// Verify task status changed:
db.tasks_ith.findOne({_id: task._id})
// Expected: status: "submitted" (not "pending")
```

---

## Test Scenario 2: Submission Without Files

### Test Steps
```
1. From task detail, tap "Submit Work"
2. Skip file selection
3. Add description: "No files for this task"
4. Tap "SUBMIT COMPLETED WORK"
```

### Expected Results ✅
- [ ] Toast: "Submission sent successfully!"
- [ ] Task moves to submitted state
- [ ] beforeFiles: [] (empty array)
- [ ] afterFiles: [] (empty array)
- [ ] description: "No files for this task"

---

## Test Scenario 3: Admin Receives Notification

### Setup
- Login as **admin** on device 2 (or same device, second account)
- Both devices on same WiFi

### Test Steps
```
1. Admin: Stay on dashboard (should see "Submissions" tab)
2. Member: Submit a task (as in Scenario 1)
3. Admin: Watch for notification
```

### Expected Results ✅
- [ ] Admin receives push notification: "📋 New Submission Awaiting Review"
- [ ] Notification includes member name and task title
- [ ] Tap notification → navigates to submission review
- [ ] Submissions count increases

### Verify in Backend Logs
```bash
# Check Firebase notification sending
tail -f backend/logs/combined-*.log | grep -E "(FCM|notification|sendToMultiple)"

# Expected logs:
# 📤 Sending notification to X admins...
# ✅ Notification sent
```

---

## Test Scenario 4: Admin Approves Submission

### Setup
- Previous submission still pending
- Admin logged in
- Submission visible in "Submissions" tab

### Test Steps
```
1. Admin: Tap on pending submission
2. Review member's before/after photos
3. Add feedback: "Great work!"
4. Tap "APPROVE" button
```

### Expected Results ✅
- [ ] Submission status changes to "approved"
- [ ] Feedback saved in database
- [ ] Member receives notification: "Your submission was approved!"
- [ ] Task status changes to "completed"

### Database Verification
```javascript
db.submissions_ith.findOne({_id: submission._id})
// Expected:
// {
//   status: "approved",
//   adminFeedback: "Great work!"
// }
```

---

## Test Scenario 5: Admin Rejects Submission

### Setup
- New submission created
- Admin logged in

### Test Steps
```
1. Admin: Tap on submission
2. Review photos
3. Add rejection reason: "Photo quality too low"
4. Tap "REJECT" button
```

### Expected Results ✅
- [ ] Submission status changes to "rejected"
- [ ] Feedback saved
- [ ] Member receives notification: "Your submission was rejected"
- [ ] Task status changes back to "pending"
- [ ] Member can re-submit

---

## Troubleshooting

### Problem: "POST / 401" or "POST / 400" in logs
**Cause**: Submission being sent to wrong endpoint
**Check**: 
- Frontend `.env` has correct `BACKEND_URL`
- Backend is running on port 5000
- No routing issues in ApiClient

**Fix**:
```dart
// Verify in app_constants.dart:
static String get apiBaseUrl => '$serverUrl/api/v1';

// Should resolve to: http://192.168.29.120:5000/api/v1
```

### Problem: No submission request in logs
**Cause**: Submission never left frontend
**Check**:
- Print statements show sync action queued?
- Is sync service being initialized?
- Is device actually online?

**Debug**:
- Check Flutter console for print statements
- Look for: "✅ Submission saved to Hive"
- Look for: "✅ Sync action queued"

### Problem: "File not found" errors
**Cause**: File paths are null or invalid
**Check**:
- Print statements show file saved?
- Look for: "✅ Before file saved:"
- Look for: "✅ After file saved:"

**Fix**: Ensure `beforeFiles.isNotEmpty` before submit

### Problem: "Status is still pending"
**Cause**: Task status not updated in database
**Check Backend Logs**:
```bash
tail -f backend/logs/combined-*.log | grep -i "task.status"
```

**MongoDB Check**:
```javascript
db.tasks_ith.findOne({_id: task._id}, {status: 1})
// If still "pending", check submission creation logs
```

---

## Performance Metrics to Track

```
Metric                      | Target    | Acceptable | Concern
---------------------------|-----------|-----------|----------
File upload time            | < 3s      | < 10s     | > 10s ⚠️
Submission processing       | < 2s      | < 5s      | > 5s ⚠️
Admin notification delay    | < 1s      | < 5s      | > 10s ⚠️
Task status update          | < 2s      | < 5s      | > 10s ⚠️
Re-submission after reject  | < 5s      | < 10s     | > 15s ⚠️
```

---

## Success Criteria ✅

All of the following must pass:
1. ✅ Submission created successfully (POST 201)
2. ✅ Task status changes to "submitted"
3. ✅ Admin receives notification
4. ✅ Admin can review submission details
5. ✅ Admin can approve/reject with feedback
6. ✅ Member receives approval/rejection notification
7. ✅ Member can resubmit after rejection
8. ✅ File uploads work (with and without files)
9. ✅ Descriptions saved correctly
10. ✅ Works on multiple devices

---

## Reporting Results

Use this template when reporting test results:

```
Device: [Vivo V40 / iPhone / etc.]
OS Version: [Android 12+ / iOS 14+ / etc.]
Backend Status: [Running / Paused / etc.]

Test Scenario: [1-5]
Status: [PASS / FAIL / PARTIAL]

✅ Passed:
- [ ] Item 1
- [ ] Item 2

❌ Failed:
- [ ] Item 1 - Error: [details]
- [ ] Item 2 - Error: [details]

📋 Notes:
[Any additional observations]

🔧 Backend Logs:
[Paste relevant log lines]
```
