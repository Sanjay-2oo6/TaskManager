# Notification & Badge System Status

## What Triggers Notifications ✅

### Task Management
- ✅ New task assigned to you
- ✅ Task status updated (pending → submitted → completed → etc.)
- ✅ Task deadline changed
- ✅ Task unlocked (dependency completed)
- ✅ Task overdue reminder (scheduled job)

### Submissions
- ✅ New submission awaiting review (to admins)
- ✅ Submission approved (to member)
- ✅ Submission rejected (to member)
- ✅ Resubmission submitted (to admins)
- ✅ Review response comment (to member)
- ✅ Employee response to review (to admin)

### Collaboration
- ✅ New chat message in task collaboration

**Notification Data Includes:**
```json
{
  "notification": {
    "title": "💬 Message from John",
    "body": "Task: Hello everyone"
  },
  "data": {
    "taskId": "507f1f77bcf86cd799439011",
    "type": "CHAT_MESSAGE",
    "senderName": "John Doe"
  }
}
```

---

## Badge System ✅

### Unread Message Badges
- **Created**: When new message arrives (`onNewMessage` event increments badge)
- **Displayed**: On task card as red dot with count
- **Cleared**: When user clicks on chat tab or when messages are marked as read
- **Locations**: Task card badge + chat UI

### Badge Clearing Flow
1. User opens task detail screen → chat tab
2. `_tabController.index == 1` triggers listener
3. Badge cleared via: `ref.read(unreadCountsProvider.notifier).clear(taskId)`
4. API call: `POST /messages/{taskId}/read` persists state to backend
5. Socket event: `mark-read` emitted so other users see ✓✓ immediately

### Clear Triggers
- ✅ User switches to chat tab
- ✅ User reads the messages
- ✅ Badge data persisted to backend

---

## Notification Click Navigation ✅

### What Happens When You Tap Notification

**Backend sends data:**
```javascript
data: { 
  taskId: data.taskId,
  type: 'CHAT_MESSAGE',
  senderName: populatedMessage.sender.name
}
```

**Frontend receives in `onMessageOpenedApp`:**
- Extracts `taskId` from notification data
- Navigates to: `navigatorKey.currentState?.pushNamed('/task/$taskId')`
- Opens TaskDetailScreen with the specific task

**Result:** User is taken directly to the task that has new messages ✅

---

## System Flow (Example: New Chat Message)

```
1. Admin sends message "Hello" in task chat
                ↓
2. Socket event 'send-message' received at server
                ↓
3. Message saved to database
                ↓
4. Server broadcasts 'new-chat-message' to room 'task_<id>'
                ↓
5. Push notification sent to other task members with:
   - Notification title & body (visible in notification center)
   - Data containing taskId (for navigation)
                ↓
6. Frontend receives notification
   - If user has notification permission: Shows notification
   - Stores in badge counter
                ↓
7. User clicks notification
   - App opens to that specific task
                ↓
8. Chat tab opens
   - Badge automatically cleared
   - Messages marked as read on backend
```

---

## Known Behaviors

### Message Badges
- ✅ Show immediately on message arrival
- ✅ Show count (e.g., "3" unread messages)
- ✅ Clear when chat is viewed
- ✅ Clear for read messages

### Notification Persistence
- ✅ Persists across app restarts
- ✅ Persisted to database (not lost on network failure)
- ✅ Works in foreground and background

### Real-Time Updates
- ✅ Messages appear in real-time via Socket.IO
- ✅ Read receipts (✓✓) appear instantly
- ✅ Badges update without page reload
- ✅ Typing indicators work in real-time

---

## Chat Bubble Alignment

**Fixed in this session:**
- ✅ Own messages: Right side (coral/red bubble)
- ✅ Received messages: Left side (white bubble)
- ✅ Sender name/role shown only for received messages
- ✅ Read receipts (✓✓) shown only for own messages
- ✅ Timestamps visible on all messages

---

## Summary

✅ **All notification triggers configured**  
✅ **Badge system fully operational**  
✅ **Notification tap redirects to task**  
✅ **Messages clear badges automatically**  
✅ **Chat bubbles aligned correctly (left/right)**  
✅ **Real-time updates via Socket.IO**

**No issues found. System is working as expected.**
