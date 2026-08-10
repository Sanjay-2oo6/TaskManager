# Immediate Fix Priority List - Action Items

**Status:** Ready for Implementation  
**Complexity:** Medium  
**Estimated Time:** 2-3 days for experienced developer

---

## BLOCKING ISSUES (Users Cannot Use System)

### 1. ❌ BLOCKING: Admin Cannot See Team Members
**Why It's Blocking:** Admin can't assign tasks to anyone  
**Location:** API endpoint for user list  
**Quick Diagnosis:**
```bash
# Test as admin
curl -H "Authorization: Bearer ADMIN_JWT" \
  http://localhost:5000/api/v1/users
# If response is empty or excludes team members, THIS IS THE BUG
```

**Likely Cause:** 
- Organization filter returning empty
- OR Admin role excluded from member list
- OR User endpoint not implemented

**Files to Check:**
1. `backend/routes/appRoutes.js` - getUsers endpoint definition
2. `backend/controllers/appController.js` - getUsers implementation  
3. `backend/middleware/organizationMiddleware.js` - org filtering
4. `backend/models/User.js` - User schema

**Fix Steps:**
```javascript
// In appController.js - getUsers
exports.getUsers = async (req, res) => {
  try {
    // ✅ Get org from user
    const organizationId = req.user.organizationId;
    if (!organizationId) {
      return res.status(400).json({ success: false, message: 'No organization context' });
    }

    // ✅ Query users in same org (all roles - admin needs to see members)
    const users = await User.find({ organizationId })
      .select('_id name username role email organizationId')
      .lean();

    res.status(200).json({ 
      success: true, 
      data: users,
      count: users.length 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
```

**Verification:**
- [ ] Admin logs in
- [ ] Opens task creation screen
- [ ] Member list shows 3+ team members
- [ ] Can select member from dropdown

---

### 2. ❌ BLOCKING: Offline Sync Fails When Online
**Why It's Blocking:** Offline submissions don't sync  
**Location:** `frontend/lib/data/services/sync_service.dart`  
**Root Cause:** organizationId not included in sync payload

**Fix Steps:**
```dart
// In sync_service.dart - _performSync method
Future<bool> _performSync(SyncAction action) async {
  try {
    // ✅ GET organizationId from somewhere:
    // Option 1: From action.payload (recommended)
    // Option 2: From stored user session
    final organizationId = action.payload['organizationId'] ?? 
                           _getStoredOrgId(); // ← Need to implement
    
    switch (action.type) {
      case SyncActionType.submitProof:
        return await _syncSubmitProof(action, organizationId);
      case SyncActionType.createMessage:
        return await _syncCreateMessage(action, organizationId);
      case SyncActionType.updateSubmissionStatus:
        return await _syncUpdateSubmissionStatus(action, organizationId);
    }
  } catch (e) {
    _logger.e('Sync error: $e');
    return false;
  }
}

// Then in _syncSubmitProof
Future<bool> _syncSubmitProof(SyncAction action, String organizationId) async {
  final payload = action.payload;
  final taskId = payload['taskId'];
  final description = payload['description'] ?? '';

  final formData = FormData.fromMap({
    'taskId': taskId,
    'organizationId': organizationId, // ✅ ADD THIS
    'description': description,
  });
  // ... rest of upload
}
```

**Verification:**
- [ ] Go offline (airplane mode)
- [ ] Submit task proof
- [ ] See queue notification
- [ ] Go online
- [ ] Submission syncs successfully
- [ ] No 400/403 errors in logs

---

### 3. ❌ BLOCKING: Rejected Task Shows "Pending" After Resubmission
**Why It's Blocking:** Workflow appears broken to users  
**Location:** Multiple files (backend + frontend)  
**Root Cause:** State not updating after resubmission

**Backend Fix (Verify Correct):**
```javascript
// In submissionController.js - createSubmission (Line 103-121)
// ✅ This should already set task.status = 'submitted'
const updatedTask = await Task.findByIdAndUpdate(
  taskId,
  { status: 'submitted', submission: submission._id },
  { new: true }
);

// ✅ Emit event with full task
if (io) {
  const transformedTask = await Task.findById(taskId)
    .populate('assignedTo createdBy', 'name username');
  const room = `org_${organizationId}`;
  
  // IMPORTANT: Emit with explicit status
  io.to(room).emit('task-updated', {
    taskId,
    status: 'submitted', // ← Explicit status
    task: transformedTask.toObject()
  });
}
```

**Frontend Fix (New Code):**
```dart
// In task_providers.dart - TaskDetailNotifier
class TaskDetailNotifier extends StateNotifier<TaskDetailState> {
  final SocketService _socket;
  
  TaskDetailNotifier(this._socket) : super(TaskDetailState());
  
  Future<void> loadTask(String taskId) async {
    // ... existing load code
  }
  
  void _setupSocketListeners(String taskId) {
    // ✅ ADD THIS: Listen for task updates
    _socket.socket?.on('task-updated', (data) {
      if (data['taskId'] == taskId) {
        final updatedTask = Task.fromJson(data['task']);
        state = state.copyWith(task: updatedTask);
        print('✅ Task updated via socket: ${updatedTask.status}');
      }
    });
  }
}
```

**Frontend UI Fix:**
```dart
// In task_detail_screen.dart - Line 677
// BETTER: Only show rejection card if task is actually rejected
if (task.status == 'rejected' && task.history != null && task.history!.isNotEmpty) {
  final lastAction = task.history!.last.action.toLowerCase();
  if (lastAction.contains('reject')) {
    // Show rejection card
  }
}
```

**Verification:**
- [ ] Member submits work
- [ ] Admin rejects with feedback
- [ ] Member resubmits work
- [ ] Task shows status: "SUBMITTED"
- [ ] Rejection card disappears
- [ ] Admin sees new submission notification

---

## HIGH PRIORITY ISSUES (Fix This Sprint)

### 4. 🟠 Real-Time Messages Not Syncing in Collaboration Tab
**Location:** `frontend/lib/state/message_providers.dart`  
**Symptoms:** Messages sent don't appear immediately, need to refresh  
**Investigation:**
```dart
// Check if message provider listens to socket events
// Should have something like:
socket.on('new-chat-message', (message) {
  // Update state
});
```

**If Missing, Add:**
```dart
void _setupSocketListeners() {
  _socket.socket?.on('new-chat-message', (messageData) {
    print('📨 New message: $messageData');
    // Parse message
    final message = Message.fromJson(messageData);
    
    // Update state
    state = state.copyWith(
      messages: [...state.messages, message]
    );
  });
}
```

---

### 5. 🟠 Sync Service Not Detecting New Submissions
**Location:** `frontend/lib/data/services/sync_service.dart` + `frontend/lib/state/task_providers.dart`  
**Issue:** After submission, task list doesn't refresh  
**Fix:**
```dart
// In proof_upload_screen.dart - after successful submission
Future<void> _onSubmissionSuccess() async {
  // ✅ Force reload task from backend
  await ref.read(taskDetailProvider(taskId).notifier).loadTask(taskId);
  
  // ✅ Also refresh task list
  await ref.read(tasksProvider.notifier).loadTasks();
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('✅ Submitted successfully!'))
  );
}
```

---

### 6. 🟠 SyncAction Missing organizationId Field
**Location:** `frontend/lib/data/models/sync_action.dart`  
**Fix:**
```dart
import 'package:hive/hive.dart';

part 'sync_action.g.dart';

@HiveType()
class SyncAction {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late String type;
  
  @HiveField(2)
  late Map<String, dynamic> payload;
  
  @HiveField(3)
  late DateTime timestamp;
  
  @HiveField(4)
  int retryCount = 0;
  
  @HiveField(5)  // ✅ ADD THIS
  late String organizationId;
}
```

Then update sync_service.dart to include it:
```dart
// When adding to queue
await _syncBox.put(action.id, SyncAction()
  ..organizationId = getCurrentOrgId() // ✅ ADD THIS
  ..type = 'submitProof'
  ..payload = {...}
);
```

---

## VERIFICATION CHECKLIST

Use this checklist after fixes to verify each works:

### Admin User Flow
- [ ] Admin logs in
- [ ] Opens "Create Task" screen
- [ ] Member dropdown shows 3+ names
- [ ] Can select member
- [ ] Creates task successfully
- [ ] Task appears in member's list

### Member Submission Flow
- [ ] Member opens assigned task
- [ ] Clicks "Submit Work"
- [ ] Uploads before/after photos
- [ ] Submits successfully
- [ ] Task shows "SUBMITTED"
- [ ] Admin sees notification

### Rejection & Resubmission Flow
- [ ] Admin opens admin review screen
- [ ] Reviews submission
- [ ] Clicks "REJECT" with feedback
- [ ] Member sees rejection notification
- [ ] Member opens task (shows rejection card)
- [ ] Member clicks "Resubmit"
- [ ] Uploads new proof
- [ ] Task shows "SUBMITTED" again
- [ ] Rejection card disappears

### Offline Sync Flow
- [ ] Enable airplane mode
- [ ] Try to submit work
- [ ] See "Queued offline" message
- [ ] Disable airplane mode
- [ ] See "Syncing..." message
- [ ] Submission syncs successfully
- [ ] No error messages

### Real-Time Collaboration
- [ ] Two users open same task
- [ ] User 1 sends message
- [ ] User 2 sees message appear immediately
- [ ] User 2 sends reply
- [ ] User 1 sees it appear immediately

---

## Database Queries to Check

Run these in MongoDB to verify data is correct:

```javascript
// Check task status after rejection + resubmission
db.tasks_ith.findOne({_id: ObjectId("...")})
// Should show: status: "submitted"

// Check submissions for this task
db.submissions_ith.find({task: ObjectId("...")})
// Should show: 
// - First submission: status: "pending" then "approved"
// - Second submission: status: "pending"

// Check user organization
db.users_ith.findOne({username: "admin"})
// Should show: organizationId: "ith"
```

---

## API Endpoints to Test

```bash
# 1. Get users (should include team members)
GET /api/v1/users
Authorization: Bearer ADMIN_TOKEN

# 2. Get tasks (should include all org tasks)
GET /api/v1/tasks
Authorization: Bearer MEMBER_TOKEN

# 3. Create submission (must include organizationId)
POST /api/v1/submissions
Authorization: Bearer MEMBER_TOKEN
Content-Type: multipart/form-data
- taskId: "..."
- description: "..."
- beforeFiles: [file1, file2]
- afterFiles: [file3, file4]

# 4. Get submission (should include organizationId validation)
GET /api/v1/submissions/:id
Authorization: Bearer TOKEN

# 5. Update submission status (rejects cross-org access)
PATCH /api/v1/submissions/:id/status
Authorization: Bearer ADMIN_TOKEN
{
  "status": "approved" | "rejected",
  "adminFeedback": "Good work!"
}

# 6. Get task (should show updated status after submission)
GET /api/v1/tasks/:id
Authorization: Bearer TOKEN
```

---

## Files Modified Checklist

After implementing fixes, update these files:

### Backend
- [ ] `controllers/appController.js` - Fix getUsers
- [ ] `controllers/submissionController.js` - Verify org context
- [ ] `middleware/organizationMiddleware.js` - Add org validation to all routes

### Frontend  
- [ ] `lib/data/models/sync_action.dart` - Add organizationId field
- [ ] `lib/data/services/sync_service.dart` - Include organizationId in sync
- [ ] `lib/state/task_providers.dart` - Listen to socket events
- [ ] `lib/state/message_providers.dart` - Listen to socket events
- [ ] `lib/presentation/screens/task_detail_screen.dart` - Fix rejection logic, add refresh
- [ ] `lib/presentation/screens/proof_upload_screen.dart` - Add post-submission refresh
- [ ] `lib/data/services/socket_service.dart` - Verify room validation

---

## Rollout Plan

### Phase 1: Local Testing (30 min)
1. Apply all fixes locally
2. Run through all verification checklists
3. Test offline sync
4. Test multi-tenant isolation

### Phase 2: Staging Deployment (1 hour)
1. Deploy to staging environment
2. Run full test suite
3. Manual testing with multiple users
4. Check production-like data

### Phase 3: Production Rollout (30 min)
1. Deploy to production
2. Monitor logs for errors
3. Have rollback plan ready
4. Communicate to users

---

## Rollback Plan

If issues arise in production:

```bash
# 1. Revert code
git revert <commit-hash>

# 2. Restart services
npm restart  # Backend
flutter run # Frontend rebuild

# 3. Clear caches if needed
redis-cli FLUSHDB
# OR in app: Clear Hive boxes
# await Hive.deleteBoxFromDisk('sync_queue');

# 4. Notify users
# "Brief maintenance, system restored"
```

---

**Next Steps:**
1. Read through this list carefully
2. Identify which fixes you can implement immediately
3. Create separate PRs for each major fix
4. Run verification checklist after each PR
5. Deploy to staging before production

**Questions?** Check the detailed audit reports:
- `COMPREHENSIVE_CODEBASE_AUDIT_2.md` - Full analysis
- `BUG_REPORT_REJECTED_TASK_PENDING.md` - Resubmission bug deep-dive

**Status:** Ready to implement 🚀
