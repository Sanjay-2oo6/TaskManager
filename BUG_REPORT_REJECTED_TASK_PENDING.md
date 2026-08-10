# Bug Report: Rejected Task Shows as "Pending" After Resubmission

## Issue Description
When an admin rejects a task submission and the member resubmits the work, the task continues to show as "pending" instead of updating to "submitted" status.

## Root Cause Analysis

### Backend Issue (PRIMARY)
**File:** `backend/controllers/submissionController.js` - Line 103-110

```javascript
// ✅ FIX: Always set task to 'submitted' when new submission created (handles resubmission after rejection)
const updatedTask = await Task.findByIdAndUpdate(
  taskId, 
  { status: 'submitted', submission: submission._id },
  { new: true }
);
```

**Problem:** The comment says "Always set task to 'submitted'" but this logic is in `createSubmission()` which correctly sets the task status to 'submitted' when a new submission is created.

However, the issue is that when admin rejects a submission:

**File:** `backend/controllers/submissionController.js` - Line 277
```javascript
const taskStatus = status === 'approved' ? 'completed' : 'rejected';
// ...
task.status = taskStatus;
```

When `status === 'rejected'`, the task is set to `'rejected'`. But when the member resubmits:

1. A NEW submission is created with status 'pending'
2. The task is updated to `'submitted'`
3. BUT the task is NOT being emitted via Socket.IO properly to the frontend

### Frontend Issue (SECONDARY)
**File:** `frontend/lib/presentation/screens/task_detail_screen.dart` - Line 677

```dart
// --- REJECTION FEEDBACK CARD ---
if (task.status == 'pending' && task.history != null && task.history!.any((h) => h.action.toLowerCase().contains('reject'))) ...[
```

**Problem:** This condition checks if `task.status == 'pending'` AND history contains a rejection. This shows the rejection card even when the task should be 'submitted' after resubmission.

The rejection card should only show if the LATEST rejection is NOT followed by a successful resubmission.

### State Management Issue (TERTIARY)
**File:** `frontend/lib/state/task_providers.dart`

The task detail provider needs to properly handle task updates when:
1. Submission is created (task → 'submitted')
2. Rejection occurs (task → 'rejected') 
3. Resubmission occurs (task → 'submitted')

## Symptom Timeline

1. ✅ Admin creates and assigns task → Task shows as 'pending'
2. ✅ Member submits work → Task shows as 'submitted'
3. ✅ Admin rejects → Task shows as 'rejected' (should trigger UI refresh)
4. ❌ Member resubmits → Task STILL shows as 'pending' (should show 'submitted')

## Expected Behavior

After member resubmits:
- Task status should be `'submitted'` (not 'pending', not 'rejected')
- Rejection feedback card should disappear
- Submit button should hide (task is waiting for review)
- New badge/notification should appear to admin about resubmission

## Data Flow During Resubmission

```
Backend: createSubmission()
  ↓
  Creates: Submission { status: 'pending' }
  ↓
  Updates: Task { status: 'submitted' } ✅
  ↓
  Emits: 'new-submission' event
  ↓
  Emits: 'task-updated' event ✅
  ↓
Frontend: taskDetailProvider receives update
  ↓
  UI re-renders with new task.status ❌ (NOT HAPPENING)
```

## Required Fixes

### Fix 1: Verify Socket.IO Emission (Backend)
Location: `backend/controllers/submissionController.js:115-121`

Ensure the 'task-updated' event includes the correct updated task with status='submitted':

```javascript
if (io) {
  const transformedTask = await Task.findById(taskId).populate('assignedTo createdBy', 'name username');
  const room = `org_${organizationId}`;
  io.to(room).emit('new-submission', { 
    taskId, 
    submissionId: submission._id, 
    employeeName: employee.name, 
    submission: submission.toObject() 
  });
  io.to(room).emit('task-updated', { 
    taskId, 
    status: 'submitted', // ✅ EXPLICIT status
    task: transformedTask.toObject() // ✅ Full updated task
  });
}
```

### Fix 2: Frontend State Update
Location: `frontend/lib/state/task_providers.dart`

Ensure the task provider listens to 'task-updated' event and updates:

```dart
// In socket listener
socket.on('task-updated', (data) {
  final taskId = data['taskId'];
  final updatedTask = Task.fromJson(data['task']);
  
  // Update the specific task in the detail provider
  state.task = updatedTask;
  
  // Also upsert in the task list provider for consistency
  ref.read(tasksProvider.notifier).upsertTask(updatedTask);
});
```

### Fix 3: Improve Rejection Feedback Logic
Location: `frontend/lib/presentation/screens/task_detail_screen.dart:677`

Update to only show rejection card if latest history action is a rejection:

```dart
// --- REJECTION FEEDBACK CARD ---
if (task.status == 'rejected' && task.history != null && task.history!.isNotEmpty) ...[
  () {
    final lastEntry = task.history!.last;
    final isLatestActionRejection = lastEntry.action.toLowerCase().contains('reject');
    
    if (!isLatestActionRejection) return SizedBox.shrink();
    
    return Container(
      // ... rejection feedback UI
    );
  }(),
],
```

### Fix 4: Add Force Refresh
Location: `frontend/lib/presentation/screens/task_detail_screen.dart`

After submission is created, force reload the task from server:

```dart
// In proof_upload_screen.dart or submission completion
Future<void> _onSubmissionSuccess() async {
  // Force reload task data from backend
  await ref.read(taskDetailProvider(widget.taskId).notifier).loadTask(widget.taskId);
  
  // Also refresh task list
  await ref.read(tasksProvider.notifier).loadTasks();
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('✅ Resubmitted successfully! Waiting for admin review...'))
  );
}
```

## Testing Steps

1. **Setup:**
   - Login as Member
   - Find a task assigned to you
   - Submit work

2. **Rejection:**
   - Login as Admin
   - Review the submission
   - Reject with feedback
   - Verify member sees rejection card ✅

3. **Resubmission (BROKEN):**
   - Login as Member
   - Open rejected task (should show rejection card)
   - Resubmit work
   - **Expected:** Task shows 'submitted', rejection card disappears
   - **Actual:** Task still shows 'pending', rejection card persists

4. **After Fix:**
   - Repeat step 3
   - **Expected:** Task shows 'submitted' ✅, rejection card disappears ✅

## Files to Review/Modify

- ✅ `backend/controllers/submissionController.js` (createSubmission - verify fix)
- ✅ `backend/controllers/submissionController.js` (updateSubmissionStatus - verify rejection logic)
- 🔧 `frontend/lib/state/task_providers.dart` (ensure proper state updates)
- 🔧 `frontend/lib/presentation/screens/task_detail_screen.dart` (improve rejection card logic)
- 🔧 `frontend/lib/presentation/screens/proof_upload_screen.dart` (add force refresh)

## Priority
**HIGH** - Users cannot properly resubmit rejected work, blocking workflow

## Status
**Ready for Fix**
