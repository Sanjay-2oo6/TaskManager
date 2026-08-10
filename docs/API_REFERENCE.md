# Task Manager - API Reference

**Version:** 1.3.0  
**Base URL:** `https://api.taskmanager.com/api/v1`  
**Protocol:** HTTPS  
**Format:** JSON  
**Authentication:** JWT Bearer Token

---

## Quick Start

### Making Your First API Call

```bash
# 1. Login to get token
curl -X POST https://api.taskmanager.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "john.doe@company.com", "password": "SecurePass@123"}'

# Response includes token
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}

# 2. Use token for authenticated requests
curl -X GET https://api.taskmanager.com/api/v1/tasks \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

---

## Authentication

### POST /auth/login

Authenticate user and receive JWT token.

**Endpoint:** `/auth/login`  
**Method:** `POST`  
**Authentication:** None

**Request Body:**
```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "64a5e7f8c9d2b3a1e4f5g6h7",
      "name": "John Doe",
      "email": "john.doe@company.com",
      "role": "member"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Login successful"
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid credentials
- `429 Too Many Requests` - Rate limit exceeded (100 attempts per 15 min)

**Example:**
```javascript
const response = await fetch('https://api.taskmanager.com/api/v1/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'john.doe@company.com',
    password: 'SecurePass@123'
  })
});
const data = await response.json();
console.log(data.data.token); // Store this token
```

---

### POST /auth/users

Create new user account.

**Endpoint:** `/auth/users`  
**Method:** `POST`  
**Authentication:** Required (Admin only)

**Request Body:**
```json
{
  "name": "string (required, max 100 chars)",
  "email": "string (required, unique, valid email)",
  "password": "string (required, min 8 chars, complexity required)",
  "role": "string (optional, default: member)"
}
```

**Role Options:** `member`, `admin`, `super_admin` (super_admin only available to super admin users)

**Password Requirements:**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "64a5e7f8c9d2b3a1e4f5g6h8",
      "name": "Jane Smith",
      "email": "jane.smith@company.com",
      "role": "member"
    }
  },
  "message": "User created successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid input or weak password
- `403 Forbidden` - Non-admin attempting to create user
- `409 Conflict` - Email already exists

---

### GET /auth/me

Get current authenticated user profile.

**Endpoint:** `/auth/me`  
**Method:** `GET`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "64a5e7f8c9d2b3a1e4f5g6h7",
      "name": "John Doe",
      "email": "john.doe@company.com",
      "role": "member",
      "createdAt": "2026-07-01T10:30:00.000Z",
      "lastLoginTimestamp": "2026-07-18T08:15:30.000Z"
    }
  },
  "message": "User profile loaded"
}
```

---

### GET /auth/users

Get all users (Admin only).

**Endpoint:** `/auth/users`  
**Method:** `GET`  
**Authentication:** Required (Admin only)

**Success Response (200):**
```json
{
  "success": true,
  "count": 25,
  "data": [
    {
      "id": "...",
      "name": "John Doe",
      "username": "john.doe",
      "role": "employee",
      "createdAt": "2026-07-01T10:30:00.000Z"
    },
    ...
  ]
}
```

---

### PATCH /auth/me/password

Change current user's password or name.

**Endpoint:** `/auth/me/password`  
**Method:** `PATCH`  
**Authentication:** Required

**Request Body:**
```json
{
  "name": "string (optional)",
  "password": "string (optional, must meet requirements)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64a5e7f8c9d2b3a1e4f5g6h7",
    "name": "John Doe Updated",
    "username": "john.doe",
    "role": "employee"
  },
  "message": "Mission identity updated successfully"
}
```

---

### DELETE /auth/users/:id

Delete user account (Admin only).

**Endpoint:** `/auth/users/:id`  
**Method:** `DELETE`  
**Authentication:** Required (Admin only)

**URL Parameters:**
- `id` - User ObjectId

**Success Response (200):**
```json
{
  "success": true,
  "message": "User removed successfully"
}
```

**Error Responses:**
- `403 Forbidden` - Attempting to delete protected master admin account
- `404 Not Found` - User does not exist

---

### PATCH /auth/users/:id/password

Update user password (Admin only).

**Endpoint:** `/auth/users/:id/password`  
**Method:** `PATCH`  
**Authentication:** Required (Admin only)

**Request Body:**
```json
{
  "password": "string (required, must meet requirements)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Password updated successfully"
}
```

---

### PATCH /auth/fcm-token

Update Firebase Cloud Messaging token.

**Endpoint:** `/auth/fcm-token`  
**Method:** `PATCH`  
**Authentication:** Required

**Request Body:**
```json
{
  "token": "string (required, FCM device token)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "FCM Token updated successfully"
}
```

---

## Tasks

### POST /tasks

Create new task.

**Endpoint:** `/tasks`  
**Method:** `POST`  
**Authentication:** Required (Admin/Assigner only)  
**Content-Type:** `multipart/form-data`

**Form Fields:**
```
title: string (required)
description: string (optional)
assignedTo: string[] or JSON array (required)
dueDate: ISO 8601 date string (required)
priority: "low"|"medium"|"high"|"extreme" (default: medium)
adminNote: string (optional)
dependsOn: string[] or JSON array (optional)
parentTaskId: string (optional)
files: File[] (optional, max 10 files, 20MB each)
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "_id": "task_id_123",
    "title": "Website Redesign",
    "description": "Redesign the company homepage",
    "assignedTo": [
      {
        "_id": "user_id_1",
        "name": "John Doe",
        "username": "john.doe"
      }
    ],
    "createdBy": {
      "_id": "admin_id",
      "name": "Admin User"
    },
    "status": "pending",
    "priority": "high",
    "dueDate": "2026-07-25T23:59:59.000Z",
    "adminNote": "Focus on mobile responsiveness",
    "adminFiles": [
      "https://s3.amazonaws.com/bucket/presigned-url..."
    ],
    "dependsOn": [],
    "createdAt": "2026-07-18T10:00:00.000Z",
    "updatedAt": "2026-07-18T10:00:00.000Z"
  }
}
```

**Example (JavaScript with FormData):**
```javascript
const formData = new FormData();
formData.append('title', 'Website Redesign');
formData.append('description', 'Redesign homepage');
formData.append('assignedTo', JSON.stringify(['user_id_1', 'user_id_2']));
formData.append('dueDate', '2026-07-25T23:59:59.000Z');
formData.append('priority', 'high');
formData.append('files', fileInput.files[0]);

const response = await fetch('https://api.taskmanager.com/api/v1/tasks', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});
```

---

### GET /tasks

Get all tasks with pagination and filters.

**Endpoint:** `/tasks`  
**Method:** `GET`  
**Authentication:** Required

**Query Parameters:**
```
page: number (default: 1)
limit: number (default: 20, max: 100)
status: "pending"|"in-progress"|"submitted"|"completed"|"rejected"|"waiting"|"all"
priority: "low"|"medium"|"high"|"extreme"|"all"
sortBy: "createdAt"|"dueDate"|"priority"
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "task_id_123",
      "title": "Website Redesign",
      "status": "pending",
      "priority": "high",
      "dueDate": "2026-07-25T23:59:59.000Z",
      "assignedTo": [...],
      "createdBy": {...},
      "createdAt": "2026-07-18T10:00:00.000Z"
    },
    ...
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 145,
    "totalPages": 8,
    "hasNext": true,
    "hasPrev": false
  }
}
```

**Example:**
```bash
curl -X GET "https://api.taskmanager.com/api/v1/tasks?page=1&limit=20&status=pending&priority=high&sortBy=dueDate" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### GET /tasks/user

Get tasks assigned to current user.

**Endpoint:** `/tasks/user`  
**Method:** `GET`  
**Authentication:** Required

**Query Parameters:** Same as GET /tasks

**Success Response (200):** Same format as GET /tasks

---

### GET /tasks/:id

Get single task details.

**Endpoint:** `/tasks/:id`  
**Method:** `GET`  
**Authentication:** Required

**URL Parameters:**
- `id` - Task ObjectId

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "task_id_123",
    "title": "Website Redesign",
    "description": "Redesign the company homepage",
    "assignedTo": [
      {
        "_id": "user_id_1",
        "name": "John Doe",
        "username": "john.doe"
      }
    ],
    "createdBy": {
      "_id": "admin_id",
      "name": "Admin User",
      "username": "admin"
    },
    "status": "pending",
    "priority": "high",
    "dueDate": "2026-07-25T23:59:59.000Z",
    "notes": "Employee notes here",
    "adminNote": "Focus on mobile responsiveness",
    "adminFiles": ["https://s3.amazonaws.com/presigned-url..."],
    "adminFileNames": ["spec.pdf", "mockup.png"],
    "dependsOn": [
      {
        "_id": "dependency_task_id",
        "title": "Design Approval",
        "status": "completed"
      }
    ],
    "parentTaskId": null,
    "comments": [
      {
        "_id": "comment_id",
        "user": {
          "_id": "user_id",
          "name": "John Doe",
          "username": "john.doe"
        },
        "text": "I have a question about this",
        "createdAt": "2026-07-18T11:00:00.000Z"
      }
    ],
    "history": [
      {
        "_id": "history_id",
        "action": "Created Task",
        "user": {
          "_id": "admin_id",
          "name": "Admin User"
        },
        "timestamp": "2026-07-18T10:00:00.000Z",
        "details": "Initial creation"
      },
      {
        "action": "Status changed to in-progress",
        "user": {...},
        "timestamp": "2026-07-18T12:00:00.000Z",
        "details": "Employee started working"
      }
    ],
    "createdAt": "2026-07-18T10:00:00.000Z",
    "updatedAt": "2026-07-18T12:00:00.000Z"
  }
}
```

**Error Responses:**
- `403 Forbidden` - Employee trying to view task not assigned to them
- `404 Not Found` - Task does not exist

---

### PATCH /tasks/:id

Update task details.

**Endpoint:** `/tasks/:id`  
**Method:** `PATCH`  
**Authentication:** Required (Admin/Assigner only)  
**Content-Type:** `application/json` or `multipart/form-data`

**Request Body (JSON):**
```json
{
  "title": "string (optional)",
  "description": "string (optional)",
  "status": "string (optional)",
  "priority": "string (optional)",
  "dueDate": "ISO date string (optional)",
  "adminNote": "string (optional)",
  "notes": "string (optional)",
  "assignedTo": "string[] (optional)",
  "dependsOn": "string[] (optional)"
}
```

**Status Options:** `pending`, `in-progress`, `submitted`, `completed`, `rejected`, `waiting`

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    ...updated_task...
  }
}
```

**Side Effects:**
- Status change triggers notifications to assignees
- Updates are logged in task history
- Socket.IO broadcast to all connected clients
- System message added to task chat

**Example:**
```javascript
const response = await fetch('https://api.taskmanager.com/api/v1/tasks/task_id_123', {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    status: 'in-progress',
    notes: 'Started working on this task'
  })
});
```

---

### DELETE /tasks/:id

Delete task permanently.

**Endpoint:** `/tasks/:id`  
**Method:** `DELETE`  
**Authentication:** Required (Admin only)

**URL Parameters:**
- `id` - Task ObjectId

**Success Response (200):**
```json
{
  "success": true,
  "message": "Task purged."
}
```

**Side Effects:**
- All related messages are deleted
- All related submissions are deleted
- Task is removed from other tasks' dependency arrays
- Socket.IO broadcast to notify all clients

**Warning:** This action cannot be undone.

---

### POST /tasks/:id/assign

Assign or reassign task to users.

**Endpoint:** `/tasks/:id/assign`  
**Method:** `POST`  
**Authentication:** Required (Admin/Assigner only)

**Request Body:**
```json
{
  "assignedTo": ["user_id_1", "user_id_2"]
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    ...updated_task_with_new_assignees...
  }
}
```

**Side Effects:**
- Notifications sent to newly assigned users
- Task history updated
- Socket.IO broadcast

---

### POST /tasks/:id/comments

Add comment to task.

**Endpoint:** `/tasks/:id/comments`  
**Method:** `POST`  
**Authentication:** Required

**Request Body:**
```json
{
  "text": "string (required, max 1000 chars)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    ...task_with_new_comment...
  }
}
```

**Authorization:**
- Employees can only comment on tasks assigned to them
- Admins/Assigners can comment on any task

**Side Effects:**
- Notifications sent to all task assignees (except commenter)
- Socket.IO broadcast
- Real-time update in task chat

---

### POST /tasks/bulk-update

Update multiple tasks at once.

**Endpoint:** `/tasks/bulk-update`  
**Method:** `POST`  
**Authentication:** Required (Admin/Assigner only)

**Request Body:**
```json
{
  "taskIds": ["task_id_1", "task_id_2", "task_id_3"],
  "updates": {
    "status": "completed",
    "priority": "low"
  }
}
```

**Allowed Update Fields:** `status`, `priority`, `dueDate`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Bulk update applied."
}
```

---

## Submissions

### POST /submissions

Submit work for a task.

**Endpoint:** `/submissions`  
**Method:** `POST`  
**Authentication:** Required  
**Content-Type:** `multipart/form-data`

**Form Fields:**
```
taskId: string (required)
description: string (optional)
beforeFiles: File[] (optional)
afterFiles: File[] (optional)
```

**File Requirements:**
- Max 10 files per submission
- Max 20MB per file
- Supported formats: JPEG, PNG, GIF, PDF

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "_id": "submission_id_456",
    "task": "task_id_123",
    "employee": "user_id_1",
    "taskTitle": "Website Redesign",
    "employeeName": "John Doe",
    "description": "Completed the homepage redesign",
    "beforeFiles": ["s3_key_1", "s3_key_2"],
    "beforeFileNames": ["before1.jpg", "before2.jpg"],
    "afterFiles": ["s3_key_3", "s3_key_4"],
    "afterFileNames": ["after1.jpg", "after2.jpg"],
    "status": "pending",
    "createdAt": "2026-07-18T15:30:00.000Z"
  }
}
```

**Side Effects:**
- Task status automatically changed to "submitted"
- Notifications sent to all reviewers (admin/assigner)
- Socket.IO broadcast

**Example:**
```javascript
const formData = new FormData();
formData.append('taskId', 'task_id_123');
formData.append('description', 'Work completed successfully');
formData.append('beforeFiles', beforeFile1);
formData.append('beforeFiles', beforeFile2);
formData.append('afterFiles', afterFile1);
formData.append('afterFiles', afterFile2);

const response = await fetch('https://api.taskmanager.com/api/v1/submissions', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});
```

---

### GET /submissions

Get all submissions with pagination.

**Endpoint:** `/submissions`  
**Method:** `GET`  
**Authentication:** Required

**Query Parameters:**
```
page: number (default: 1)
limit: number (default: 20, max: 100)
status: "pending"|"approved"|"rejected"|"all"
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "submission_id",
      "task": {...},
      "employee": {...},
      "status": "pending",
      "beforeFilesUrls": ["https://s3.amazonaws.com/..."],
      "afterFilesUrls": ["https://s3.amazonaws.com/..."],
      "description": "Work completed",
      "createdAt": "2026-07-18T15:30:00.000Z"
    },
    ...
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 45,
    "totalPages": 3,
    "hasNext": true,
    "hasPrev": false
  }
}
```

**Authorization:**
- Employees see only their own submissions
- Admins/Assigners see all submissions

---

### GET /submissions/:id

Get single submission details.

**Endpoint:** `/submissions/:id`  
**Method:** `GET`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "submission_id_456",
    "task": {
      "_id": "task_id_123",
      "title": "Website Redesign"
    },
    "employee": {
      "_id": "user_id_1",
      "name": "John Doe",
      "username": "john.doe"
    },
    "taskTitle": "Website Redesign",
    "employeeName": "John Doe",
    "description": "Completed the homepage redesign",
    "beforeFilesUrls": [
      "https://s3.amazonaws.com/bucket/presigned-url-1...",
      "https://s3.amazonaws.com/bucket/presigned-url-2..."
    ],
    "afterFilesUrls": [
      "https://s3.amazonaws.com/bucket/presigned-url-3...",
      "https://s3.amazonaws.com/bucket/presigned-url-4..."
    ],
    "status": "pending",
    "adminFeedback": null,
    "comments": [],
    "createdAt": "2026-07-18T15:30:00.000Z",
    "updatedAt": "2026-07-18T15:30:00.000Z"
  }
}
```

**Authorization:**
- Employees can only view their own submissions
- Admins/Assigners can view any submission

---

### GET /submissions/task/:taskId

Get all submissions for a specific task.

**Endpoint:** `/submissions/task/:taskId`  
**Method:** `GET`  
**Authentication:** Required

**URL Parameters:**
- `taskId` - Task ObjectId

**Query Parameters:** page, limit (same as GET /submissions)

**Success Response (200):** Same format as GET /submissions

---

### PATCH /submissions/:id/status

Update submission status (approve/reject).

**Endpoint:** `/submissions/:id/status`  
**Method:** `PATCH`  
**Authentication:** Required (Admin/Assigner only)

**Request Body:**
```json
{
  "status": "approved" | "rejected",
  "adminFeedback": "string (required if rejected)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    ...updated_submission...
  }
}
```

**Side Effects:**
- If approved: Task status changed to "completed"
- If rejected: Task status changed to "rejected"
- Notification sent to employee
- Socket.IO broadcast

**Example:**
```javascript
// Approve submission
await fetch('https://api.taskmanager.com/api/v1/submissions/sub_id/status', {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    status: 'approved',
    adminFeedback: 'Excellent work!'
  })
});

// Reject submission
await fetch('https://api.taskmanager.com/api/v1/submissions/sub_id/status', {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    status: 'rejected',
    adminFeedback: 'Please fix the header alignment and resubmit'
  })
});
```

---

### POST /submissions/:id/comments

Add comment to submission.

**Endpoint:** `/submissions/:id/comments`  
**Method:** `POST`  
**Authentication:** Required

**Request Body:**
```json
{
  "text": "string (required)"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "comment": {
      "user": "user_id",
      "text": "Please adjust the header color",
      "createdAt": "2026-07-18T16:00:00.000Z"
    }
  }
}
```

**Authorization:**
- Employee who submitted can comment
- Admin/Assigner can comment on any submission

**Side Effects:**
- Notification sent to relevant parties
- Socket.IO broadcast with event `submission-comment-added`

---

### GET /submissions/:id/comments

Get all comments for a submission.

**Endpoint:** `/submissions/:id/comments`  
**Method:** `GET`  
**Authentication:** Required

**Query Parameters:**
```
page: number (default: 1)
limit: number (default: 10)
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "comment_id",
      "user": {
        "_id": "user_id",
        "name": "Admin User",
        "username": "admin"
      },
      "text": "Please adjust the header color",
      "createdAt": "2026-07-18T16:00:00.000Z"
    },
    ...
  ],
  "pagination": {...}
}
```

---

## Messages

### GET /messages/task/:taskId

Get all messages for a task.

**Endpoint:** `/messages/task/:taskId`  
**Method:** `GET`  
**Authentication:** Required

**URL Parameters:**
- `taskId` - Task ObjectId

**Query Parameters:**
```
page: number (default: 1)
limit: number (default: 50)
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "message_id_789",
      "taskId": "task_id_123",
      "sender": {
        "_id": "user_id_1",
        "name": "John Doe",
        "username": "john.doe",
        "role": "employee"
      },
      "text": "I've started working on this task",
      "readBy": [
        {
          "user": "user_id_2",
          "readAt": "2026-07-18T16:05:00.000Z"
        }
      ],
      "isSystem": false,
      "createdAt": "2026-07-18T16:00:00.000Z",
      "updatedAt": "2026-07-18T16:05:00.000Z"
    },
    {
      "text": "Admin User changed status to IN-PROGRESS",
      "isSystem": true,
      "createdAt": "2026-07-18T15:55:00.000Z"
    }
  ],
  "pagination": {...}
}
```

**Authorization:**
- Employees can only access messages for tasks assigned to them
- Admins/Assigners can access any task's messages

---

### POST /messages

Send message to task chat.

**Endpoint:** `/messages`  
**Method:** `POST`  
**Authentication:** Required

**Request Body:**
```json
{
  "taskId": "string (required)",
  "text": "string (required, max 1000 chars)"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "_id": "message_id_790",
    "taskId": "task_id_123",
    "sender": {
      "_id": "user_id_1",
      "name": "John Doe",
      "username": "john.doe",
      "role": "employee"
    },
    "text": "Question about the design requirements",
    "readBy": [],
    "isSystem": false,
    "createdAt": "2026-07-18T16:10:00.000Z"
  }
}
```

**Side Effects:**
- Notifications sent to all task assignees (except sender)
- Socket.IO broadcast with event `new-chat-message`
- Real-time delivery to connected clients

**Authorization:**
- Must be assigned to the task or be admin/assigner

---

### PATCH /messages/mark-read/:taskId

Mark all messages as read for a task.

**Endpoint:** `/messages/mark-read/:taskId`  
**Method:** `PATCH`  
**Authentication:** Required

**URL Parameters:**
- `taskId` - Task ObjectId

**Success Response (200):**
```json
{
  "success": true,
  "message": "Messages marked as read",
  "data": {
    "modifiedCount": 5
  }
}
```

**Side Effects:**
- User added to `readBy` array with timestamp
- Unread count updated
- Socket.IO broadcast to update UI

---

### GET /messages/unread-count

Get total unread message count for current user.

**Endpoint:** `/messages/unread-count`  
**Method:** `GET`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "unreadCount": 12,
    "byTask": [
      {
        "taskId": "task_id_123",
        "taskTitle": "Website Redesign",
        "count": 5
      },
      {
        "taskId": "task_id_456",
        "taskTitle": "Bug Fixes",
        "count": 7
      }
    ]
  }
}
```

---

## Analytics

### GET /analytics/leaderboard

Get employee performance leaderboard.

**Endpoint:** `/analytics/leaderboard`  
**Method:** `GET`  
**Authentication:** Required (Admin/Assigner only)

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "employee": {
        "_id": "user_id_1",
        "name": "John Doe",
        "username": "john.doe"
      },
      "totalTasks": 45,
      "completedTasks": 42,
      "pendingTasks": 3,
      "completionRate": 93.33,
      "avgCompletionTime": 2.5,
      "onTimeRate": 95.24,
      "rejectionRate": 4.76
    },
    {
      "employee": {...},
      "totalTasks": 38,
      "completedTasks": 35,
      ...
    }
  ]
}
```

**Metrics Explained:**
- `totalTasks` - All tasks assigned to employee
- `completedTasks` - Successfully completed tasks
- `completionRate` - Percentage of completed tasks
- `avgCompletionTime` - Average days to complete
- `onTimeRate` - Percentage completed before deadline
- `rejectionRate` - Percentage of submissions rejected

---

### GET /analytics/team-activity

Get recent team activity feed.

**Endpoint:** `/analytics/team-activity`  
**Method:** `GET`  
**Authentication:** Required (Admin/Assigner only)

**Query Parameters:**
```
limit: number (default: 20, max: 100)
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "type": "task_completed",
      "task": {
        "_id": "task_id_123",
        "title": "Website Redesign"
      },
      "user": {
        "_id": "user_id_1",
        "name": "John Doe"
      },
      "timestamp": "2026-07-18T15:45:00.000Z"
    },
    {
      "type": "task_assigned",
      "task": {...},
      "user": {...},
      "timestamp": "2026-07-18T14:30:00.000Z"
    },
    {
      "type": "submission_rejected",
      "submission": {...},
      "user": {...},
      "timestamp": "2026-07-18T13:15:00.000Z"
    }
  ]
}
```

**Activity Types:**
- `task_assigned` - New task assigned
- `task_completed` - Task finished
- `task_in_progress` - Task started
- `submission_created` - Work submitted
- `submission_approved` - Work approved
- `submission_rejected` - Work rejected

---

### GET /analytics/dashboard-stats

Get dashboard summary statistics.

**Endpoint:** `/analytics/dashboard-stats`  
**Method:** `GET`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "totalTasks": 145,
    "pendingTasks": 32,
    "inProgressTasks": 28,
    "submittedTasks": 15,
    "completedTasks": 70,
    "overdueTasks": 5,
    "todayTasks": 8,
    "weekTasks": 22,
    "unreadMessages": 12,
    "pendingSubmissions": 6,
    "teamSize": 25,
    "activeUsers": 18
  }
}
```

**Note:** Statistics are filtered based on user role:
- Employees see only their own stats
- Admins/Assigners see team-wide stats

---

## File Upload

### POST /upload

Upload file to S3.

**Endpoint:** `/upload`  
**Method:** `POST`  
**Authentication:** Required  
**Content-Type:** `multipart/form-data`

**Form Fields:**
```
file: File (required)
folder: string (optional, default: "uploads")
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "key": "uploads/1689724800000-filename.jpg",
    "url": "https://s3.amazonaws.com/bucket/presigned-url...",
    "fileName": "filename.jpg",
    "fileSize": 2048576,
    "mimeType": "image/jpeg"
  }
}
```

**File Restrictions:**
- Max size: 20MB
- Allowed types: JPEG, PNG, GIF, WebP, PDF, DOC, DOCX
- Automatic virus scanning
- Server-side encryption (AES-256)

**Example:**
```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);
formData.append('folder', 'references');

const response = await fetch('https://api.taskmanager.com/api/v1/upload', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});
```

---

## Pagination

All list endpoints support pagination with consistent format:

**Query Parameters:**
```
page: number (default: 1, min: 1)
limit: number (default: 20, min: 1, max: 100)
```

**Response Format:**
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalItems": 145,
    "totalPages": 8,
    "hasNext": true,
    "hasPrev": false
  }
}
```

**Example Implementation (JavaScript):**
```javascript
async function fetchAllTasks(page = 1, limit = 20) {
  const response = await fetch(
    `https://api.taskmanager.com/api/v1/tasks?page=${page}&limit=${limit}`,
    {
      headers: { 'Authorization': `Bearer ${token}` }
    }
  );
  
  const result = await response.json();
  
  console.log(`Page ${result.pagination.currentPage} of ${result.pagination.totalPages}`);
  console.log(`Showing ${result.data.length} of ${result.pagination.totalItems} total`);
  
  return result;
}

// Fetch next page
if (result.pagination.hasNext) {
  const nextPage = await fetchAllTasks(result.pagination.currentPage + 1);
}
```

---

## Rate Limiting

API endpoints are rate-limited to prevent abuse:

**Limits:**
- Authentication endpoints: 5 requests per 15 minutes per IP
- General API endpoints: 100 requests per minute per user
- File upload endpoints: 20 requests per hour per user

**Rate Limit Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1689724800
```

**Rate Limit Exceeded (429):**
```json
{
  "success": false,
  "message": "Too many requests, please try again later",
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "retryAfter": 60
  }
}
```

---

## Error Handling

### Standard Error Response

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional details about the error",
    "field": "fieldName"
  }
}
```

### Common Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | INVALID_INPUT | Request validation failed |
| 400 | MISSING_FIELD | Required field not provided |
| 400 | INVALID_FORMAT | Data format incorrect |
| 401 | UNAUTHORIZED | Missing or invalid token |
| 401 | TOKEN_EXPIRED | JWT token has expired |
| 403 | FORBIDDEN | Insufficient permissions |
| 403 | ROLE_REQUIRED | Action requires specific role |
| 404 | NOT_FOUND | Resource does not exist |
| 409 | CONFLICT | Resource already exists |
| 409 | USERNAME_TAKEN | Username not available |
| 413 | FILE_TOO_LARGE | File exceeds size limit |
| 422 | VALIDATION_ERROR | Data validation failed |
| 422 | WEAK_PASSWORD | Password doesn't meet requirements |
| 422 | CIRCULAR_DEPENDENCY | Task dependency creates cycle |
| 429 | RATE_LIMIT_EXCEEDED | Too many requests |
| 500 | INTERNAL_ERROR | Server error |
| 503 | SERVICE_UNAVAILABLE | Server or service is down |

### Error Handling Example

```javascript
async function createTask(taskData) {
  try {
    const response = await fetch('https://api.taskmanager.com/api/v1/tasks', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(taskData)
    });
    
    const result = await response.json();
    
    if (!response.ok) {
      // Handle specific errors
      switch (result.error?.code) {
        case 'FORBIDDEN':
          console.error('You do not have permission to create tasks');
          break;
        case 'VALIDATION_ERROR':
          console.error('Invalid task data:', result.error.details);
          break;
        case 'RATE_LIMIT_EXCEEDED':
          console.error('Too many requests. Retry after:', result.error.retryAfter, 'seconds');
          break;
        default:
          console.error('Error:', result.message);
      }
      throw new Error(result.message);
    }
    
    return result.data;
  } catch (error) {
    console.error('Failed to create task:', error);
    throw error;
  }
}
```

---

## WebSocket Events (Socket.IO)

### Connection

**Connect to WebSocket:**
```javascript
import io from 'socket.io-client';

const socket = io('https://api.taskmanager.com', {
  auth: {
    token: 'your_jwt_token'
  },
  transports: ['websocket']
});

socket.on('connect', () => {
  console.log('Connected to server');
});

socket.on('disconnect', () => {
  console.log('Disconnected from server');
});

socket.on('error', (error) => {
  console.error('Socket error:', error);
});
```

### Events Reference

#### Client → Server

| Event | Payload | Description |
|-------|---------|-------------|
| `join-task` | `{ taskId: string }` | Join task chat room |
| `leave-task` | `{ taskId: string }` | Leave task chat room |
| `send-message` | `{ taskId, text }` | Send chat message |
| `typing` | `{ taskId, isTyping }` | Typing indicator |

#### Server → Client

| Event | Payload | Description |
|-------|---------|-------------|
| `task-assigned` | `{ task, operatorId }` | New task assigned |
| `task-updated` | `{ taskId, status, task }` | Task status changed |
| `task-deleted` | `{ taskId }` | Task deleted |
| `new-chat-message` | `{ message }` | New chat message |
| `user-typing` | `{ userId, isTyping }` | User typing status |
| `submission-comment-added` | `{ submissionId, comment }` | New submission comment |

### WebSocket Example

```javascript
// Join task room
socket.emit('join-task', 'task_id_123');

// Listen for new messages
socket.on('new-chat-message', (message) => {
  console.log('New message:', message.text);
  // Update UI
  addMessageToChat(message);
});

// Send message
function sendMessage(taskId, text) {
  socket.emit('send-message', {
    taskId,
    text
  });
}

// Typing indicator
let typingTimeout;
function handleTyping(taskId) {
  socket.emit('typing', { taskId, isTyping: true });
  
  clearTimeout(typingTimeout);
  typingTimeout = setTimeout(() => {
    socket.emit('typing', { taskId, isTyping: false });
  }, 1000);
}

// Listen for typing
socket.on('user-typing', ({ userId, isTyping }) => {
  if (isTyping) {
    showTypingIndicator(userId);
  } else {
    hideTypingIndicator(userId);
  }
});

// Clean up on unmount
function cleanup() {
  socket.emit('leave-task', 'task_id_123');
  socket.disconnect();
}
```

---

## SDK & Client Libraries

### Official JavaScript/TypeScript Client

```javascript
import TaskManagerAPI from 'task-manager-api-client';

const client = new TaskManagerAPI({
  baseURL: 'https://api.taskmanager.com/api/v1',
  token: 'your_jwt_token'
});

// Authentication
const { token, user } = await client.auth.login('john.doe@company.com', 'password');

// Tasks
const tasks = await client.tasks.getAll({ status: 'pending', page: 1 });
const task = await client.tasks.getById('task_id_123');
await client.tasks.create({
  title: 'New Task',
  assignedTo: ['user_id_1'],
  dueDate: '2026-07-25',
  priority: 'high'
});

// Submissions
const submission = await client.submissions.create({
  taskId: 'task_id_123',
  description: 'Work completed',
  beforeFiles: [file1, file2],
  afterFiles: [file3, file4]
});

// Messages
const messages = await client.messages.getByTask('task_id_123');
await client.messages.send('task_id_123', 'Hello team');

// WebSocket
client.socket.on('new-chat-message', (message) => {
  console.log('New message:', message);
});
```

### Flutter/Dart Client

```dart
import 'package:task_manager_api/task_manager_api.dart';

final client = TaskManagerAPI(
  baseUrl: 'https://api.taskmanager.com/api/v1',
  token: token,
);

// Authentication
final authResponse = await client.auth.login(
  username: 'john.doe',
  password: 'SecurePass@123',
);

// Tasks
final tasks = await client.tasks.getAll(
  page: 1,
  limit: 20,
  status: TaskStatus.pending,
);

final task = await client.tasks.getById('task_id_123');

// Submissions
final submission = await client.submissions.create(
  taskId: 'task_id_123',
  description: 'Work completed',
  beforeFiles: [file1, file2],
  afterFiles: [file3, file4],
);

// Messages
final messages = await client.messages.getByTask('task_id_123');
await client.messages.send('task_id_123', 'Hello team');
```

---

## Postman Collection

Import our Postman collection for easy API testing:

**Collection URL:** `https://api.taskmanager.com/postman/collection.json`

**Environment Variables:**
```json
{
  "base_url": "https://api.taskmanager.com/api/v1",
  "token": "{{auth_token}}",
  "user_id": "{{current_user_id}}",
  "task_id": "{{sample_task_id}}"
}
```

---

## Changelog

### v1.3.0 (Current) - July 15, 2026
- Added submission comments endpoints
- Implemented pagination on all list endpoints
- Enhanced error responses with error codes
- Added circular dependency detection

### v1.2.0 - July 1, 2026
- Added task dependencies (dependsOn field)
- Implemented task history tracking
- Added bulk task update endpoint
- WebSocket events for real-time updates

### v1.1.0 - June 15, 2026
- Added 7-day JWT token expiration
- Implemented rate limiting
- Added file upload endpoint
- Enhanced security with input sanitization

### v1.0.0 - June 1, 2026
- Initial API release
- Core authentication endpoints
- Task management endpoints
- Submission system
- Message system

---

## Support

**Documentation:** https://docs.taskmanager.com  
**API Status:** https://status.taskmanager.com  
**Support Email:** api-support@taskmanager.com  
**GitHub Issues:** https://github.com/taskmanager/api/issues

---

*Last Updated: July 18, 2026*  
*API Version: 1.3.0*


---

## Super Admin - Organization Management

**Authentication:** All endpoints require `super_admin` role and JWT Bearer token

### POST /super-admin/organizations

Create a new organization with admin account.

**Endpoint:** `/super-admin/organizations`  
**Method:** `POST`  
**Authentication:** Required (Super Admin only)

**Request Body:**
```json
{
  "name": "string (required, min 3 chars, max 100 chars)",
  "slug": "string (required, lowercase alphanumeric with hyphens, unique)",
  "memberLimit": "number (optional, default: 10)",
  "adminName": "string (required, admin's full name)",
  "adminEmail": "string (required, unique email)",
  "adminPassword": "string (required, min 8 chars with complexity)"
}
```

**Password Requirements:**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "organization": {
      "_id": "org_id_789",
      "name": "Acme Corporation",
      "slug": "acme-corp",
      "adminId": "admin_user_id_1",
      "memberLimit": 10,
      "memberCount": 1,
      "isActive": true,
      "isSpecial": false,
      "createdAt": "2026-07-18T10:00:00.000Z",
      "updatedAt": "2026-07-18T10:00:00.000Z"
    },
    "admin": {
      "id": "admin_user_id_1",
      "name": "Jane Smith",
      "email": "jane.smith@acmecorp.com",
      "role": "admin"
    }
  },
  "message": "Organization created successfully"
}
```

**Error Responses:**
- `400 Bad Request` - Missing fields or invalid input
- `400 Bad Request` - Slug already exists
- `400 Bad Request` - Email already exists
- `400 Bad Request` - Weak password
- `403 Forbidden` - Non-super-admin attempting to create

**Example:**
```bash
curl -X POST https://api.taskmanager.com/api/v1/super-admin/organizations \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Corporation",
    "slug": "acme-corp",
    "memberLimit": 50,
    "adminName": "Jane Smith",
    "adminEmail": "jane@acmecorp.com",
    "adminPassword": "SecureAdmin@2026"
  }'
```

---

### GET /super-admin/organizations

List all organizations with pagination and filters.

**Endpoint:** `/super-admin/organizations`  
**Method:** `GET`  
**Authentication:** Required (Super Admin only)

**Query Parameters:**
```
page: number (default: 1)
limit: number (default: 20, max: 100)
search: string (optional, searches name and slug)
isActive: boolean (optional, filter by active status)
sortBy: string (optional, default: "createdAt". Options: "createdAt", "name", "memberCount")
order: "asc" | "desc" (optional, default: "desc")
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "org_id_789",
      "name": "Acme Corporation",
      "slug": "acme-corp",
      "adminId": {
        "_id": "admin_user_id_1",
        "name": "Jane Smith",
        "username": "jane.smith"
      },
      "memberLimit": 50,
      "memberCount": 23,
      "isActive": true,
      "createdAt": "2026-07-18T10:00:00.000Z"
    },
    {
      "_id": "org_id_790",
      "name": "Tech Innovations Ltd",
      "slug": "tech-innovations",
      "adminId": {...},
      "memberLimit": 100,
      "memberCount": 67,
      "isActive": true,
      "createdAt": "2026-07-10T14:30:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalPages": 5,
    "totalCount": 95
  }
}
```

**Example:**
```bash
# List all active organizations
curl "https://api.taskmanager.com/api/v1/super-admin/organizations?isActive=true&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Search for organization
curl "https://api.taskmanager.com/api/v1/super-admin/organizations?search=acme" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Sort by member count descending
curl "https://api.taskmanager.com/api/v1/super-admin/organizations?sortBy=memberCount&order=desc" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### GET /super-admin/organizations/:id

Get single organization details.

**Endpoint:** `/super-admin/organizations/:id`  
**Method:** `GET`  
**Authentication:** Required (Super Admin only)

**URL Parameters:**
- `id` - Organization ObjectId

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "org_id_789",
    "name": "Acme Corporation",
    "slug": "acme-corp",
    "adminId": {
      "_id": "admin_user_id_1",
      "name": "Jane Smith",
      "username": "jane.smith",
      "createdAt": "2026-07-18T10:00:00.000Z"
    },
    "createdBy": {
      "_id": "super_admin_id",
      "name": "Super Admin",
      "username": "superadmin"
    },
    "memberLimit": 50,
    "memberCount": 23,
    "actualMemberCount": 23,
    "isActive": true,
    "isSpecial": false,
    "logo": "https://s3.amazonaws.com/bucket/logo.png",
    "banner": "https://s3.amazonaws.com/bucket/banner.jpg",
    "welcomeMessage": "Welcome to Acme",
    "themeColor": "#6366F1",
    "createdAt": "2026-07-18T10:00:00.000Z",
    "updatedAt": "2026-07-18T10:00:00.000Z"
  }
}
```

**Error Responses:**
- `404 Not Found` - Organization does not exist

---

### PATCH /super-admin/organizations/:id

Update organization details.

**Endpoint:** `/super-admin/organizations/:id`  
**Method:** `PATCH`  
**Authentication:** Required (Super Admin only)

**Request Body:**
```json
{
  "name": "string (optional, min 3 chars)",
  "memberLimit": "number (optional, protected for ITH org)",
  "logo": "string (optional, URL or S3 key)",
  "banner": "string (optional, URL or S3 key)",
  "welcomeMessage": "string (optional)",
  "themeColor": "string (optional, hex color)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "org_id_789",
    "name": "Acme Corporation Updated",
    "memberLimit": 75,
    "logo": "https://s3.amazonaws.com/bucket/logo-new.png",
    "banner": "https://s3.amazonaws.com/bucket/banner-new.jpg",
    "welcomeMessage": "Welcome to Acme!",
    "themeColor": "#7C3AED",
    ...
  },
  "message": "Organization updated successfully"
}
```

**Restrictions:**
- ITH organization (special system org) cannot change memberLimit
- Cannot change organization slug after creation

**Error Responses:**
- `403 Forbidden` - Attempting to modify ITH org member limit
- `404 Not Found` - Organization does not exist

**Example:**
```bash
curl -X PATCH https://api.taskmanager.com/api/v1/super-admin/organizations/org_id_789 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Corporation Updated",
    "memberLimit": 75,
    "welcomeMessage": "Welcome to our updated team!"
  }'
```

---

### DELETE /super-admin/organizations/:id

Delete organization and all associated data.

**Endpoint:** `/super-admin/organizations/:id`  
**Method:** `DELETE`  
**Authentication:** Required (Super Admin only)

**URL Parameters:**
- `id` - Organization ObjectId

**Success Response (200):**
```json
{
  "success": true,
  "message": "Organization and all associated data deleted successfully"
}
```

**Side Effects:**
- Deletes all users in organization
- Deletes all tasks for organization
- Deletes all submissions for organization
- Deletes all messages for organization
- Removes organization from system

**Restrictions:**
- Cannot delete ITH (special system) organization
- This action cannot be undone

**Error Responses:**
- `403 Forbidden` - Attempting to delete ITH organization
- `404 Not Found` - Organization does not exist

**Warning:** This is a destructive operation. All organization data will be permanently deleted.

**Example:**
```bash
curl -X DELETE https://api.taskmanager.com/api/v1/super-admin/organizations/org_id_789 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### POST /super-admin/organizations/:id/toggle

Toggle organization active/inactive status.

**Endpoint:** `/super-admin/organizations/:id/toggle`  
**Method:** `POST`  
**Authentication:** Required (Super Admin only)

**URL Parameters:**
- `id` - Organization ObjectId

**Request Body:** (empty)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "_id": "org_id_789",
    "name": "Acme Corporation",
    "slug": "acme-corp",
    "isActive": false,
    ...
  },
  "message": "Organization deactivated successfully"
}
```

**Side Effects:**
- When deactivated: Organization members cannot login
- When activated: Full access restored
- Deactivation is reversible (unlike deletion)

**Restrictions:**
- Cannot deactivate ITH (special system) organization
- Deactivation affects all members immediately

**Error Responses:**
- `403 Forbidden` - Attempting to deactivate ITH organization
- `404 Not Found` - Organization does not exist

**Example:**
```bash
# Toggle inactive to active (or vice versa)
curl -X POST https://api.taskmanager.com/api/v1/super-admin/organizations/org_id_789/toggle \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### GET /super-admin/stats

Get platform-wide statistics and health metrics.

**Endpoint:** `/super-admin/stats`  
**Method:** `GET`  
**Authentication:** Required (Super Admin only)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "organizations": {
      "total": 95,
      "active": 88,
      "inactive": 7,
      "recentlyCreated": 5
    },
    "users": {
      "total": 2847,
      "admins": 95,
      "members": 2751,
      "superAdmins": 1
    },
    "platform": {
      "totalTasks": 12456,
      "totalSubmissions": 8934,
      "averageTasksPerOrg": 131,
      "averageUsersPerOrg": 30
    },
    "timestamp": "2026-07-18T16:00:00.000Z"
  }
}
```

**Metrics Breakdown:**
- `organizations.total` - Total organizations in system
- `organizations.active` - Organizations with isActive = true
- `organizations.recentlyCreated` - Created in last 7 days
- `users.total` - Total user accounts across all orgs
- `users.admins` - Organization admins
- `users.members` - Team members
- `platform.totalTasks` - Sum of all tasks
- `platform.averageTasksPerOrg` - Mean tasks per organization
- `platform.averageUsersPerOrg` - Mean users per organization

**Example:**
```bash
curl https://api.taskmanager.com/api/v1/super-admin/stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---
