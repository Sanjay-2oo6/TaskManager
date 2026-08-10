# Task Manager - Technical Documentation

**⚠️ IMPORTANT:** Before implementing any features, read `DEVELOPMENT_RULES.md` in the project root. It contains authoritative rules on API structure, frontend patterns, and development guidelines.

**Version:** 1.3.0  
**Document Version:** 1.0  
**Last Updated:** July 27, 2026  
**Target Audience:** Developers, System Administrators, Technical Stakeholders  

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Technology Stack](#technology-stack)
4. [Security Implementation](#security-implementation)
5. [API Documentation](#api-documentation)
6. [Database Schema](#database-schema)
7. [Mobile Application](#mobile-application)
8. [Real-time Communication](#real-time-communication)
9. [File Management](#file-management)
10. [Authentication & Authorization](#authentication--authorization)
11. [Performance & Monitoring](#performance--monitoring)
12. [Deployment Guide](#deployment-guide)
13. [Troubleshooting](#troubleshooting)
14. [Appendices](#appendices)

---

## Executive Summary

### Overview

The Task Manager is a comprehensive, enterprise-grade collaborative task management platform designed for organizations requiring sophisticated workflow automation, real-time communication, and secure file handling. Built using modern technologies and following industry best practices, the system provides a robust foundation for team productivity and project management.

### Key Features

- **Role-Based Access Control (RBAC)** - Multi-tiered user permissions
- **Real-time Collaboration** - WebSocket-based instant messaging and updates  
- **Offline-First Mobile App** - Progressive Web App with local caching
- **Advanced Workflow Management** - Task dependencies and sequential workflows
- **Secure File Handling** - AWS S3 integration with presigned URLs
- **Push Notifications** - Firebase Cloud Messaging integration
- **Comprehensive Audit Trail** - Full activity logging and history tracking
- **Over-the-Air Updates** - Seamless app updates without app store deployment

### System Characteristics

| Metric | Value | Notes |
|--------|-------|-------|
| **Scalability** | 1000+ concurrent users | Horizontal scaling supported |
| **Availability** | 99.9% uptime SLA | Load balancer + health checks |
| **Security** | Enterprise-grade | OWASP compliance, encryption at rest/transit |
| **Performance** | <200ms API response | Database indexing + caching |
| **Mobile Support** | iOS, Android, Web | Flutter cross-platform framework |
---

## System Architecture

### High-Level Architecture

```mermaid
graph TB
    A[Mobile App - Flutter] --> B[Load Balancer]
    C[Web App - PWA] --> B
    B --> D[API Gateway - Express.js]
    D --> E[Authentication Service]
    D --> F[Task Management Service]
    D --> G[File Upload Service]
    D --> H[Notification Service]
    D --> I[Real-time Service - Socket.IO]
    F --> J[(MongoDB Atlas)]
    G --> K[AWS S3]
    H --> L[Firebase FCM]
    I --> M[Redis Cache]
    
    subgraph "Monitoring & Logging"
        N[Winston Logger]
        O[Application Metrics]
        P[Health Checks]
    end
    
    D --> N
    D --> O
    D --> P
```

### Component Overview

#### Frontend Layer
- **Flutter Mobile App** - Native iOS/Android application with offline capabilities
- **Progressive Web App** - Browser-based interface with responsive design
- **Real-time Client** - Socket.IO client for instant updates

#### Backend Layer
- **REST API Server** - Express.js with comprehensive middleware stack
- **Authentication Service** - JWT-based authentication with role management
- **File Management** - S3 integration with secure upload/download
- **Notification System** - Firebase FCM for push notifications
- **Real-time Engine** - Socket.IO for instant messaging and updates

#### Data Layer
- **Primary Database** - MongoDB Atlas with replica sets
- **File Storage** - AWS S3 with CDN distribution
- **Cache Layer** - Redis for session management and performance
- **Search Engine** - MongoDB text indexes for task/message search

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Production Environment                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      │
│  │   CDN/Edge  │      │Load Balancer│      │  Firewall   │      │
│  │   (Static)  │◄─────┤  (HAProxy)  │◄─────┤   (WAF)     │      │
│  └─────────────┘      └──────┬──────┘      └─────────────┘      │
│                              │                                  │
│                    ┌─────────┴─────────┐                        │
│                    ▼                   ▼                        │
│         ┌──────────────────┐  ┌──────────────────┐              │
│         │  App Server 1    │  │  App Server 2    │              │
│         │  Node.js:5000    │  │  Node.js:5000    │              │
│         │  PM2 Cluster     │  │  PM2 Cluster     │              │
│         └────────┬─────────┘  └─────────┬────────┘              │
│                  │                       │                      │
│                  └───────────┬───────────┘                      │
│                              ▼                                  │
│                    ┌─────────────────┐                          │
│                    │  MongoDB Atlas  │                          │
│                    │  Replica Set    │                          │
│                    │  M10 Cluster    │                          │
│                    └─────────────────┘                          │
│                                                                 │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐      │
│  │   AWS S3    │      │Firebase FCM │      │   Redis     │      │ 
│  │(File Store) │      │(Push Notif.)│      │   Cache     │      │
│  └─────────────┘      └─────────────┘      └─────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Backend Technologies

#### Core Framework
- **Node.js** v18+ LTS - JavaScript runtime
- **Express.js** v4.18+ - Web application framework
- **MongoDB** v8.1+ - NoSQL database with Mongoose ODM

#### Security & Authentication
- **bcryptjs** - Password hashing (10 rounds)
- **jsonwebtoken** - JWT token generation/validation
- **helmet** - Security headers middleware
- **express-rate-limit** - DDoS protection and rate limiting
- **sanitize-html** - XSS prevention
- **password-validator** - Password strength validation

#### Real-time & Communication
- **Socket.IO** v4.8+ - WebSocket server for real-time updates
- **Firebase Admin SDK** - Push notification delivery
- **Multer** - Multipart form data handling

#### Cloud Services
- **AWS SDK v3** - S3 file storage integration
- **@aws-sdk/client-s3** - S3 client
- **@aws-sdk/s3-request-presigner** - Temporary URL generation

#### Logging & Monitoring
- **Winston** v3.19+ - Structured logging
- **winston-daily-rotate-file** - Log rotation
- **Morgan** - HTTP request logging

### Frontend Technologies

#### Mobile Framework
- **Flutter** v3.2+ - Cross-platform UI framework
- **Dart SDK** v3.2+ - Programming language

#### State Management
- **flutter_riverpod** v2.5+ - Reactive state management
- **Hive** v2.2+ - Local NoSQL database for offline storage

#### Networking & APIs
- **Dio** v5.4+ - HTTP client with interceptors
- **socket_io_client** v3.1+ - WebSocket client
- **connectivity_plus** - Network status monitoring

#### Firebase Integration
- **firebase_core** v3.10+ - Firebase SDK initialization
- **firebase_messaging** v15.2+ - FCM push notifications
- **flutter_local_notifications** v18+ - Local notification display

#### Utilities
- **shared_preferences** - Key-value storage
- **path_provider** - File system paths
- **image_picker** - Camera/gallery access
- **file_picker** - Document selection
- **ota_update** - Over-the-air updates
- **package_info_plus** - App version information

### Development Tools

#### Backend Development
```json
{
  "nodemon": "^3.0.3",        // Hot reload during development
  "eslint": "Recommended",     // Code linting
  "prettier": "Configured"     // Code formatting
}
```

#### Mobile Development
```yaml
dev_dependencies:
  flutter_test: sdk         # Unit testing
  hive_generator: ^2.0.1    # Code generation for Hive
  build_runner: ^2.4.8      # Build automation
  flutter_lints: ^3.0.1     # Dart linting
```

### Infrastructure Requirements

#### Production Environment
| Component | Specification | Notes |
|-----------|--------------|-------|
| **Node.js Server** | 2 vCPU, 4GB RAM | Per instance |
| **MongoDB Atlas** | M10 Cluster | 2GB RAM, 10GB storage |
| **Redis Cache** | 512MB RAM | Session storage |
| **AWS S3** | Standard tier | 100GB storage |
| **Load Balancer** | Application LB | Auto-scaling enabled |
| **CDN** | CloudFront | Global edge locations |

#### Development Environment
- **Node.js** v18+ with npm v9+
- **MongoDB** v4.4+ (local or Atlas)
- **Flutter SDK** v3.2+ with Dart v3.2+
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** v2.30+ for version control

---

## Security Implementation

### Security Architecture Overview

The application implements defense-in-depth security with multiple layers of protection:

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: Network Security                                  │
│  ├─ HTTPS/TLS 1.3 encryption                                │
│  ├─ Web Application Firewall (WAF)                          │
│  ├─ DDoS protection (Cloudflare/AWS Shield)                 │
│  └─ Rate limiting (10 req/min per IP)                       │
│                                                             │
│  Layer 2: Authentication & Authorization                    │
│  ├─ JWT tokens with 7-day expiry                            │
│  ├─ Bcrypt password hashing (10 rounds)                     │
│  ├─ Role-based access control (RBAC)                        │ 
│  └─ Session validation on every request                     │
│                                                             │
│  Layer 3: Input Validation & Sanitization                   │
│  ├─ Request body validation (Joi schemas)                   │
│  ├─ HTML sanitization (XSS prevention)                      │
│  ├─ SQL injection prevention (Mongoose ODM)                 │
│  └─ File upload validation (MIME type checking)             │
│                                                             │
│  Layer 4: Data Protection                                   │
│  ├─ Encryption at rest (MongoDB encrypted storage)          │
│  ├─ Encryption in transit (TLS/SSL)                         │
│  ├─ S3 server-side encryption (AES-256)                     │
│  └─ Presigned URLs with 1-hour expiry                       │
│                                                             │
│  Layer 5: Monitoring & Auditing                             │
│  ├─ Structured logging (Winston)                            │
│  ├─ Security event tracking                                 │
│  ├─ Activity audit trail                                    │
│  └─ Real-time alerting for anomalies                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Authentication System

#### JWT Token Structure
```javascript
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "id": "user_object_id",
    "role": "admin|assigner|employee|worker",
    "iat": 1689724800,
    "exp": 1690329600  // 7 days from issue
  },
  "signature": "HMACSHA256(base64UrlEncode(header) + '.' + base64UrlEncode(payload), secret)"
}
```

#### Authentication Flow
```
1. User Login Request
   ├─ Validate credentials against MongoDB
   ├─ Hash comparison using bcrypt
   └─ Generate JWT token

2. Token Generation
   ├─ Include user ID and role
   ├─ Set 7-day expiration
   ├─ Sign with secret key
   └─ Update lastLoginTimestamp

3. Request Authentication
   ├─ Extract token from Authorization header
   ├─ Verify signature and expiration
   ├─ Decode payload
   └─ Attach user info to req.user

4. Session Persistence
   ├─ Store token in SharedPreferences (mobile)
   ├─ Check lastLoginTimestamp on app start
   └─ Auto-logout after 7 days of inactivity
```

### Role-Based Access Control (RBAC)

#### User Roles & Permissions

| Role | Permissions | Use Case |
|------|-------------|----------|
| **Admin** | Full system access, user management, task CRUD, view all data | System administrators |
| **Assigner** | Create/assign tasks, view team performance, approve submissions | Team leads, managers |
| **Employee** | View assigned tasks, submit work, chat on tasks | Regular staff members |
| **Worker** | Similar to employee, specialized workflows | Field workers, contractors |

#### Permission Matrix

| Action | Admin | Assigner | Employee | Worker |
|--------|-------|----------|----------|--------|
| Create users | ✅ | ❌ | ❌ | ❌ |
| Delete users | ✅ | ❌ | ❌ | ❌ |
| Create tasks | ✅ | ✅ | ❌ | ❌ |
| Edit tasks | ✅ | ✅ | ❌ | ❌ |
| Delete tasks | ✅ | ❌ | ❌ | ❌ |
| View all tasks | ✅ | ✅ | ❌* | ❌* |
| Submit work | ✅ | ✅ | ✅ | ✅ |
| Approve submissions | ✅ | ✅ | ❌ | ❌ |
| View analytics | ✅ | ✅ | ❌ | ❌ |
| Access admin panel | ✅ | ❌ | ❌ | ❌ |

*Employees/Workers can only view tasks assigned to them

### Input Validation & Sanitization

#### Implemented Protections

**1. XSS (Cross-Site Scripting) Prevention**
```javascript
// HTML sanitization using sanitize-html
const sanitizeText = (input) => {
  return sanitizeHtml(input, {
    allowedTags: [],          // No HTML tags allowed
    allowedAttributes: {}     // No attributes allowed
  });
};

// Rich text sanitization (for descriptions)
const sanitizeRichText = (input) => {
  return sanitizeHtml(input, {
    allowedTags: ['b', 'i', 'u', 'p', 'br'],
    allowedAttributes: {}
  });
};
```

**2. SQL/NoSQL Injection Prevention**
- Mongoose ODM with parameterized queries
- No raw query execution
- Input validation before database operations

**3. File Upload Security**
```javascript
// File validation middleware
const fileFilter = (req, file, cb) => {
  const allowedMimes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'application/pdf'
  ];
  
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type'), false);
  }
};
```

**4. Rate Limiting**
```javascript
// Authentication endpoints: 5 requests per 15 minutes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts, please try again later'
});

// General API: 100 requests per minute
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100
});
```

### Password Security

#### Password Requirements
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character (@, #, $, %, etc.)

#### Password Hashing
```javascript
// Bcrypt with 10 rounds (pre-save hook)
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Password verification
userSchema.methods.matchPassword = async function (enteredPassword) {
  return bcrypt.compare(enteredPassword, this.password);
};
```

### Security Headers

Implemented using Helmet middleware:

```javascript
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

Headers applied:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- `Content-Security-Policy: default-src 'self'`

### Audit Trail

All sensitive operations are logged:

```javascript
// Security event logging
logger.security('Failed login attempt', {
  username,
  ip: req.ip,
  userAgent: req.get('user-agent')
});

// Admin action logging
logger.admin('User created', {
  createdBy: req.user.id,
  newUserId: user._id,
  newUserRole: user.role,
  ip: req.ip
});

// Authentication logging
logger.auth('User logged in', {
  userId: user._id,
  username: user.username,
  role: user.role,
  ip: req.ip
});
```

---

## API Documentation

### Base URL
```
Production:  https://api.taskmanager.com/api/v1
Development: http://localhost:5000/api/v1
```

### Authentication Header
All authenticated endpoints require:
```
Authorization: Bearer <JWT_TOKEN>
```

### Authentication Endpoints

#### POST /auth/login
Authenticate user and receive JWT token.

**Request:**
```json
{
  "email": "john.doe@company.com",
  "password": "SecurePass@123"
}
```

**Response (200 OK):**
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
- `429 Too Many Requests` - Rate limit exceeded

---

#### POST /auth/users
Create new user (Admin only).

**Request:**
```json
{
  "name": "Jane Smith",
  "email": "jane.smith@company.com",
  "password": "StrongPass@456",
  "role": "member"
}
```

**Response (201 Created):**
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

---

#### GET /auth/me
Get current authenticated user information.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "64a5e7f8c9d2b3a1e4f5g6h7",
      "name": "John Doe",
      "username": "john.doe",
      "role": "employee",
      "createdAt": "2026-07-01T10:30:00.000Z",
      "lastLoginTimestamp": "2026-07-18T08:15:30.000Z"
    }
  },
  "message": "User profile loaded"
}
```

---

#### PATCH /auth/me/password
Change current user's password.

**Request:**
```json
{
  "name": "John Doe Updated",
  "password": "NewSecurePass@789"
}
```

**Response (200 OK):**
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

### Task Management Endpoints

#### POST /tasks
Create new task (Admin/Assigner only).

**Request (multipart/form-data):**
```json
{
  "title": "Website Redesign",
  "description": "Redesign the company homepage",
  "assignedTo": ["user_id_1", "user_id_2"],
  "dueDate": "2026-07-25T23:59:59.000Z",
  "priority": "high",
  "adminNote": "Focus on mobile responsiveness",
  "dependsOn": [],
  "files": [<file_upload>]
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "_id": "task_id_123",
    "title": "Website Redesign",
    "description": "Redesign the company homepage",
    "assignedTo": [...],
    "status": "pending",
    "priority": "high",
    "dueDate": "2026-07-25T23:59:59.000Z",
    "adminFiles": ["https://s3.amazonaws.com/..."],
    "createdAt": "2026-07-18T10:00:00.000Z"
  }
}
```

---

#### GET /tasks
Get all tasks (with pagination and filters).

**Query Parameters:**
- `page` (default: 1) - Page number
- `limit` (default: 20, max: 100) - Items per page
- `status` - Filter by status (pending|in-progress|submitted|completed|rejected|waiting)
- `priority` - Filter by priority (low|medium|high|extreme)
- `sortBy` - Sort field (createdAt|dueDate|priority)

**Request:**
```
GET /tasks?page=1&limit=20&status=pending&priority=high&sortBy=dueDate
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [...tasks...],
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

---

#### GET /tasks/:id
Get single task details.

**Response (200 OK):**
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
    "adminNote": "Focus on mobile responsiveness",
    "adminFiles": ["https://s3.amazonaws.com/presigned-url..."],
    "dependsOn": [],
    "comments": [],
    "history": [
      {
        "action": "Created Task",
        "user": {...},
        "timestamp": "2026-07-18T10:00:00.000Z",
        "details": "Initial creation"
      }
    ],
    "createdAt": "2026-07-18T10:00:00.000Z",
    "updatedAt": "2026-07-18T10:00:00.000Z"
  }
}
```

#### PATCH /tasks/:id
Update task details.

**Request:**
```json
{
  "title": "Website Redesign - Updated",
  "status": "in-progress",
  "priority": "extreme",
  "adminNote": "Deadline moved up - urgent!"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    ...updated_task...
  }
}
```

---

#### DELETE /tasks/:id
Delete task (Admin only).

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Task purged."
}
```

---

### Submission Endpoints

#### POST /submissions
Submit work for a task.

**Request (multipart/form-data):**
```json
{
  "taskId": "task_id_123",
  "description": "Completed the homepage redesign",
  "beforeFiles": [<file_uploads>],
  "afterFiles": [<file_uploads>]
}
```

**Response (201 Created):**
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
    "afterFiles": ["s3_key_3", "s3_key_4"],
    "status": "pending",
    "createdAt": "2026-07-18T15:30:00.000Z"
  }
}
```

---

#### GET /submissions
Get all submissions (with pagination).

**Query Parameters:**
- `page` - Page number
- `limit` - Items per page
- `status` - Filter by status

**Response (200 OK):**
```json
{
  "success": true,
  "data": [...submissions...],
  "pagination": {...}
}
```

---

#### PATCH /submissions/:id/status
Update submission status (Admin/Assigner only).

**Request:**
```json
{
  "status": "approved",
  "adminFeedback": "Great work! Looks perfect."
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    ...updated_submission...
  }
}
```

---

#### POST /submissions/:id/comments
Add comment to submission.

**Request:**
```json
{
  "text": "Please adjust the header color"
}
```

**Response (201 Created):**
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

### Message Endpoints

#### GET /messages/task/:taskId
Get all messages for a task.

**Query Parameters:**
- `page` - Page number
- `limit` - Items per page

**Response (200 OK):**
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
        "username": "john.doe"
      },
      "text": "I've started working on this task",
      "readBy": [
        {
          "user": "user_id_2",
          "readAt": "2026-07-18T16:05:00.000Z"
        }
      ],
      "isSystem": false,
      "createdAt": "2026-07-18T16:00:00.000Z"
    }
  ],
  "pagination": {...}
}
```

---

#### POST /messages
Send message to task chat.

**Request:**
```json
{
  "taskId": "task_id_123",
  "text": "Question about the design requirements"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "_id": "message_id_790",
    "taskId": "task_id_123",
    "sender": {...},
    "text": "Question about the design requirements",
    "readBy": [],
    "createdAt": "2026-07-18T16:10:00.000Z"
  }
}
```

---

#### PATCH /messages/mark-read/:taskId
Mark all messages as read for a task.

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Messages marked as read",
  "data": {
    "modifiedCount": 5
  }
}
```

---

### Analytics Endpoints

#### GET /analytics/leaderboard
Get employee performance leaderboard.

**Response (200 OK):**
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
      "completionRate": 93.33,
      "avgCompletionTime": 2.5
    },
    ...
  ]
}
```

---

#### GET /analytics/team-activity
Get recent team activity.

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "type": "task_completed",
      "task": {...},
      "user": {...},
      "timestamp": "2026-07-18T15:45:00.000Z"
    },
    ...
  ]
}
```

---

### File Upload Endpoints

#### POST /upload
Upload file to S3 (authenticated users).

**Request (multipart/form-data):**
```
POST /upload
Content-Type: multipart/form-data

file: <binary_data>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "key": "uploads/1689724800000-filename.jpg",
    "url": "https://s3.amazonaws.com/bucket/presigned-url..."
  }
}
```

---

## Database Schema

### Collections Overview

The MongoDB database consists of 5 main collections:

1. **users** - User accounts and authentication
2. **tasks** - Task definitions and metadata
3. **submissions** - Employee work submissions
4. **messages** - Task-specific chat messages
5. **reports** - System-generated reports (optional)

### User Schema

```javascript
{
  "_id": ObjectId,
  "name": String,                    // Full name
  "username": String,                // Unique, lowercase
  "password": String,                // Bcrypt hashed
  "role": String,                    // admin|assigner|employee|worker
  "fcmToken": String,                // Firebase messaging token
  "lastLoginTimestamp": Date,        // For 7-day session validation
  "createdAt": Date,
  "updatedAt": Date
}

// Indexes
{
  "username": 1,                     // Unique index
  "role": 1                          // For role-based queries
}
```

**Constraints:**
- `username` must be unique and lowercase
- `password` minimum 8 characters with complexity requirements
- `role` must be one of: admin, assigner, employee, worker

---

### Task Schema

```javascript
{
  "_id": ObjectId,
  "title": String,                   // Required, trimmed
  "description": String,             // Optional, sanitized HTML
  "assignedTo": [ObjectId],          // References to User documents
  "assignedToNames": [String],       // Denormalized for performance
  "assignedToUsernames": [String],   // Denormalized for performance
  "createdBy": ObjectId,             // Reference to User (creator)
  "status": String,                  // Enum: pending|in-progress|submitted|completed|rejected|waiting
  "dueDate": Date,                   // Required deadline
  "priority": String,                // Enum: low|medium|high|extreme
  "notes": String,                   // General notes
  "adminNote": String,               // Admin instructions
  "adminFiles": [String],            // S3 keys for reference files
  "adminFileNames": [String],        // Original filenames
  "dependsOn": [ObjectId],           // Task dependencies (sequential workflows)
  "parentTaskId": ObjectId,          // Parent task reference
  "comments": [                      // Embedded comments
    {
      "user": ObjectId,
      "text": String,
      "createdAt": Date
    }
  ],
  "history": [                       // Audit trail
    {
      "action": String,              // Action description
      "user": ObjectId,              // Who performed action
      "timestamp": Date,
      "details": String              // Additional context
    }
  ],
  "createdAt": Date,
  "updatedAt": Date
}

// Indexes (optimized for common queries)
{
  "assignedTo": 1, "status": 1,     // User's task list
  "createdAt": -1,                   // Admin view (recent first)
  "dueDate": 1, "status": 1,         // Overdue checker job
  "parentTaskId": 1                  // Parent-child relationships
}
```

**Business Logic:**
- Circular dependency detection in pre-save hook
- Automatic history logging on updates
- Status transitions trigger notifications
- Task deletion cascades to messages and submissions

---

### Submission Schema

```javascript
{
  "_id": ObjectId,
  "task": ObjectId,                  // Reference to Task
  "employee": ObjectId,              // Reference to User
  "taskTitle": String,               // Denormalized for display
  "employeeName": String,            // Denormalized for display
  "beforeImage": String,             // Legacy: single image URL
  "afterImage": String,              // Legacy: single image URL
  "beforeFiles": [String],           // S3 keys for before photos
  "beforeFileNames": [String],       // Original filenames
  "afterFiles": [String],            // S3 keys for after photos
  "afterFileNames": [String],        // Original filenames
  "description": String,             // Work description
  "status": String,                  // Enum: pending|approved|rejected
  "adminFeedback": String,           // Admin review comments
  "comments": [                      // Review conversation
    {
      "user": ObjectId,
      "text": String,
      "createdAt": Date
    }
  ],
  "createdAt": Date,
  "updatedAt": Date
}

// Indexes
{
  "task": 1,                         // Get submissions for task
  "employee": 1,                     // Get employee's submissions
  "status": 1,                       // Filter by status
  "createdAt": -1                    // Recent first
}
```

### Message Schema

```javascript
{
  "_id": ObjectId,
  "taskId": ObjectId,                // Reference to Task
  "sender": ObjectId,                // Reference to User
  "text": String,                    // Message content (sanitized)
  "readBy": [                        // Read receipts
    {
      "user": ObjectId,
      "readAt": Date
    }
  ],
  "isSystem": Boolean,               // System-generated message
  "createdAt": Date,
  "updatedAt": Date
}

// Indexes
{
  "taskId": 1, "createdAt": 1,      // Message history (chronological)
  "taskId": 1, "sender": 1, "readBy.user": 1  // Unread count queries
}
```

**Features:**
- Real-time delivery via Socket.IO
- Read receipt tracking with timestamps
- System messages for status changes
- Message history with pagination

---

## Mobile Application

### Architecture Overview

The Flutter mobile application follows Clean Architecture principles with separation of concerns:

```
lib/
├── core/                          # Core utilities and constants
│   ├── constants/
│   ├── globals.dart
│   └── theme/
├── data/                          # Data layer
│   ├── models/                    # Data models
│   ├── repositories/              # Repository implementations
│   └── services/                  # API clients, caching
├── presentation/                  # UI layer
│   ├── screens/                   # Full-screen pages
│   ├── widgets/                   # Reusable components
│   └── dialogs/
├── state/                         # State management (Riverpod)
│   ├── auth_provider.dart
│   ├── task_providers.dart
│   └── notification_provider.dart
├── ui/                           # Legacy UI (being migrated)
└── main.dart                     # Application entry point
```

### Offline-First Design

The app implements offline capabilities using Hive local database:

```dart
// Offline data storage
Box<Submission> submissionsBox;
Box<SyncAction> syncQueueBox;

// Sync queue for offline actions
class SyncAction {
  String id;
  SyncActionType type;  // CREATE_TASK | UPDATE_TASK | SEND_MESSAGE
  Map<String, dynamic> data;
  DateTime timestamp;
  int retryCount;
}

// Background sync process
Future<void> syncOfflineActions() async {
  if (!await hasInternetConnection()) return;
  
  final actions = syncQueueBox.values.toList();
  for (final action in actions) {
    try {
      await executeAction(action);
      syncQueueBox.delete(action.id);
    } catch (e) {
      action.retryCount++;
      if (action.retryCount > 3) {
        // Mark as failed, notify user
      }
    }
  }
}
```

### State Management

Using Riverpod for reactive state management:

```dart
// Authentication state
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(sharedPreferencesProvider));
});

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? error;
  
  AuthState({
    required this.status,
    this.user,
    this.token,
    this.error,
  });
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error
}

// Task state providers
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  return await apiClient.getTasks();
});

final taskDetailProvider = FutureProvider.family<Task, String>((ref, taskId) async {
  final apiClient = ref.read(apiClientProvider);
  return await apiClient.getTaskById(taskId);
});
```

### Navigation Flow

```
SplashScreen
  ├─ Check authentication status
  │  ├─ Token exists && valid → HomeScreen
  │  └─ No token / expired → LoginScreen
  │
LoginScreen
  ├─ Login success → HomeScreen
  └─ Register link → RegisterScreen
     └─ Registration success → LoginScreen
     
HomeScreen (Bottom Navigation)
  ├─ Tab 0: Dashboard
  ├─ Tab 1: Tasks List → TaskDetailScreen
  ├─ Tab 2: Submissions → SubmissionDetailScreen
  ├─ Tab 3: Messages → ChatScreen
  └─ Tab 4: Profile → Settings
```

### Key Screens

#### 1. LoginScreen
- Email/username input
- Password input with visibility toggle
- Remember me checkbox
- Login button with loading state
- Register link

#### 2. HomeScreen
- Bottom navigation with 5 tabs
- Real-time notification badge
- App bar with user info
- Drawer menu for settings
- Back button protection (PopScope)

#### 3. TaskDetailScreen
- Task title and description
- Assigned users list
- Due date and priority indicators
- Status badge
- Admin notes and reference files
- Action buttons (Submit, Chat, etc.)
- Comments section
- History timeline

#### 4. ProofUploadScreen
- Camera/gallery picker
- Before/after image selector
- Description text field
- File preview grid
- Submit button
- Offline queue indicator

#### 5. ChatScreen
- Message list with sender info
- Real-time message updates
- Typing indicator
- Message input field
- File attachment button
- Unread count badge

---

## Real-time Communication

### Socket.IO Integration

#### Server-Side Implementation

```javascript
const io = require('socket.io')(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST']
  },
  pingTimeout: 60000,
  pingInterval: 25000
});

// Authentication middleware
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.userId = decoded.id;
    socket.userRole = decoded.role;
    next();
  } catch (err) {
    next(new Error('Authentication failed'));
  }
});

// Connection handling
io.on('connection', (socket) => {
  console.log(`User ${socket.userId} connected`);
  
  // Join task rooms
  socket.on('join-task', (taskId) => {
    socket.join(`task_${taskId}`);
  });
  
  // Leave task rooms
  socket.on('leave-task', (taskId) => {
    socket.leave(`task_${taskId}`);
  });
  
  // Typing indicator
  socket.on('typing', ({ taskId, isTyping }) => {
    socket.to(`task_${taskId}`).emit('user-typing', {
      userId: socket.userId,
      isTyping
    });
  });
  
  // Disconnect handling
  socket.on('disconnect', () => {
    console.log(`User ${socket.userId} disconnected`);
  });
});
```

#### Client-Side Implementation (Flutter)

```dart
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _currentTaskId;

  Future<void> connect(String token) async {
    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('✅ Socket.IO connected');
    });

    _socket?.onDisconnect((_) {
      debugPrint('⚠️ Socket.IO disconnected');
    });

    _socket?.onError((error) {
      debugPrint('❌ Socket.IO error: $error');
    });
  }

  void joinTask(String taskId) {
    _currentTaskId = taskId;
    _socket?.emit('join-task', taskId);
  }

  void leaveTask(String taskId) {
    _socket?.emit('leave-task', taskId);
    if (_currentTaskId == taskId) {
      _currentTaskId = null;
    }
  }

  void sendMessage(String taskId, String text) {
    _socket?.emit('send-message', {
      'taskId': taskId,
      'text': text,
    });
  }

  void listenToMessages(Function(Map<String, dynamic>) callback) {
    _socket?.on('new-chat-message', (data) {
      callback(data);
    });
  }

  void listenToTyping(Function(String userId, bool isTyping) callback) {
    _socket?.on('user-typing', (data) {
      callback(data['userId'], data['isTyping']);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
```

### Real-time Events

| Event | Direction | Purpose | Payload |
|-------|-----------|---------|---------|
| `join-task` | Client → Server | Join task chat room | `{ taskId }` |
| `leave-task` | Client → Server | Leave task chat room | `{ taskId }` |
| `send-message` | Client → Server | Send chat message | `{ taskId, text }` |
| `new-chat-message` | Server → Client | Broadcast new message | `{ message }` |
| `typing` | Client → Server | User typing indicator | `{ taskId, isTyping }` |
| `user-typing` | Server → Client | Show typing indicator | `{ userId, isTyping }` |
| `task-assigned` | Server → Client | New task assignment | `{ task, operatorId }` |
| `task-updated` | Server → Client | Task status change | `{ taskId, status }` |
| `task-deleted` | Server → Client | Task removed | `{ taskId }` |
| `submission-comment-added` | Server → Client | New submission comment | `{ submissionId, comment }` |

---

## File Management

### AWS S3 Integration

#### Upload Process

```javascript
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

class S3Service {
  constructor() {
    this.s3Client = new S3Client({
      region: process.env.AWS_REGION,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      },
    });
    this.bucketName = process.env.AWS_S3_BUCKET_NAME;
  }

  async uploadToS3(buffer, originalName, mimetype, folder = 'uploads') {
    const timestamp = Date.now();
    const sanitizedName = originalName.replace(/[^a-zA-Z0-9.-]/g, '_');
    const key = `${folder}/${timestamp}-${sanitizedName}`;

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: key,
      Body: buffer,
      ContentType: mimetype,
      ServerSideEncryption: 'AES256',  // Encryption at rest
      CacheControl: 'max-age=31536000',
    });

    await this.s3Client.send(command);
    return key;
  }
}
```

#### Presigned URL Generation

```javascript
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { GetObjectCommand } = require('@aws-sdk/client-s3');

async getSignedImageUrl(key, expiresIn = 3600) {
  const command = new GetObjectCommand({
    Bucket: this.bucketName,
    Key: key,
  });

  // Generate presigned URL valid for 1 hour
  const url = await getSignedUrl(this.s3Client, command, { 
    expiresIn 
  });
  
  return url;
}
```

**Benefits of Presigned URLs:**
- Temporary access without exposing credentials
- Direct S3 download without proxying through backend
- Automatic expiration for security
- Bandwidth savings on application server

#### File Validation

```javascript
// Multer configuration with validation
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 20 * 1024 * 1024, // 20MB max
    files: 10                     // Max 10 files per request
  },
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ];
    
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`File type not allowed: ${file.mimetype}`), false);
    }
  }
});
```

### File Storage Strategy

#### Folder Structure
```
s3://task-manager-bucket/
├── uploads/              # General uploads
│   ├── 1689724800000-document.pdf
│   └── 1689724801000-image.jpg
├── references/           # Admin reference files
│   ├── 1689724802000-spec.pdf
│   └── 1689724803000-mockup.png
├── submissions/          # Employee work submissions
│   ├── before/
│   │   ├── 1689724804000-before1.jpg
│   │   └── 1689724805000-before2.jpg
│   └── after/
│       ├── 1689724806000-after1.jpg
│       └── 1689724807000-after2.jpg
└── avatars/             # User profile pictures
    └── user_id_123.jpg
```

#### Lifecycle Policies
- **Uploads folder:** Transition to Glacier after 90 days
- **Submissions folder:** Never delete (compliance)
- **Temporary files:** Auto-delete after 7 days
- **Deleted task files:** Move to archive bucket

---

## Performance & Monitoring

### Database Optimization

#### Index Strategy

```javascript
// User collection
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "role": 1 });

// Task collection
db.tasks.createIndex({ "assignedTo": 1, "status": 1 });
db.tasks.createIndex({ "createdAt": -1 });
db.tasks.createIndex({ "dueDate": 1, "status": 1 });
db.tasks.createIndex({ "parentTaskId": 1 });

// Message collection
db.messages.createIndex({ "taskId": 1, "createdAt": 1 });
db.messages.createIndex({ "taskId": 1, "sender": 1, "readBy.user": 1 });

// Submission collection
db.submissions.createIndex({ "task": 1 });
db.submissions.createIndex({ "employee": 1 });
db.submissions.createIndex({ "status": 1 });
db.submissions.createIndex({ "createdAt": -1 });
```

#### Query Optimization Techniques

**1. Lean Queries**
```javascript
// Instead of full Mongoose documents
const tasks = await Task.find(filter).lean();

// 2-3x faster for read-only operations
```

**2. Selective Population**
```javascript
// Only populate required fields
.populate('assignedTo', 'name username')
.populate('createdBy', 'name')
```

**3. Projection**
```javascript
// Select only needed fields
Task.find(filter).select('title status dueDate assignedTo')
```

**4. Pagination**
```javascript
// Always paginate large result sets
Task.find(filter)
  .skip((page - 1) * limit)
  .limit(limit)
```

### Caching Strategy

#### Redis Cache Implementation

```javascript
const redis = require('redis');
const client = redis.createClient({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT,
  password: process.env.REDIS_PASSWORD
});

// Cache user session
async function cacheUserSession(userId, sessionData) {
  await client.setEx(
    `session:${userId}`,
    604800, // 7 days
    JSON.stringify(sessionData)
  );
}

// Cache frequently accessed tasks
async function cacheTask(taskId, taskData) {
  await client.setEx(
    `task:${taskId}`,
    3600, // 1 hour
    JSON.stringify(taskData)
  );
}

// Invalidate cache on update
async function invalidateTaskCache(taskId) {
  await client.del(`task:${taskId}`);
}
```

#### Cache Invalidation Rules

| Event | Cache Invalidation |
|-------|-------------------|
| Task updated | `task:{taskId}` |
| Task deleted | `task:{taskId}`, `user:{userId}:tasks` |
| User updated | `session:{userId}`, `user:{userId}` |
| New message | `task:{taskId}:unread_count` |
| Submission status change | `task:{taskId}`, `leaderboard` |

### Logging System

#### Log Levels & Categories

```javascript
const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    // Error logs
    new DailyRotateFile({
      filename: 'logs/error-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      level: 'error',
      maxSize: '20m',
      maxFiles: '30d'
    }),
    // Combined logs
    new DailyRotateFile({
      filename: 'logs/combined-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '30d'
    }),
    // Security events
    new DailyRotateFile({
      filename: 'logs/security-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      level: 'warn',
      maxSize: '20m',
      maxFiles: '90d' // Keep security logs longer
    })
  ]
});

// Custom log methods
logger.security = (message, meta) => {
  logger.warn(message, { type: 'SECURITY_EVENT', ...meta });
};

logger.auth = (message, meta) => {
  logger.info(message, { type: 'AUTH_EVENT', ...meta });
};

logger.admin = (message, meta) => {
  logger.info(message, { type: 'ADMIN_ACTION', ...meta });
};
```

#### Log Format

```json
{
  "timestamp": "2026-07-18T10:30:45.123Z",
  "level": "info",
  "message": "User logged in",
  "type": "AUTH_EVENT",
  "userId": "64a5e7f8c9d2b3a1e4f5g6h7",
  "username": "john.doe",
  "role": "employee",
  "ip": "192.168.1.100",
  "userAgent": "Mozilla/5.0..."
}
```

### Performance Monitoring

#### Key Metrics

**1. API Response Times**
```javascript
// Morgan middleware for HTTP logging
app.use(morgan('combined', {
  stream: {
    write: (message) => logger.http(message.trim())
  }
}));

// Custom timing middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('API Request', {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration: `${duration}ms`,
      type: 'API_REQUEST'
    });
  });
  next();
});
```

**2. Database Query Performance**
```javascript
// Mongoose query logging
mongoose.set('debug', (collectionName, method, query, doc) => {
  logger.debug('MongoDB Query', {
    collection: collectionName,
    method,
    query: JSON.stringify(query),
    type: 'DB_QUERY'
  });
});
```

**3. Memory Usage**
```javascript
// Memory monitoring
setInterval(() => {
  const usage = process.memoryUsage();
  logger.info('Memory Usage', {
    heapUsed: `${Math.round(usage.heapUsed / 1024 / 1024)}MB`,
    heapTotal: `${Math.round(usage.heapTotal / 1024 / 1024)}MB`,
    rss: `${Math.round(usage.rss / 1024 / 1024)}MB`,
    type: 'SYSTEM_METRICS'
  });
}, 300000); // Every 5 minutes
```

### Health Checks

#### Health Check Endpoint

```javascript
// GET /health
app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks: {}
  };

  // MongoDB connection check
  try {
    await mongoose.connection.db.admin().ping();
    health.checks.database = {
      status: 'healthy',
      responseTime: '<10ms'
    };
  } catch (error) {
    health.status = 'unhealthy';
    health.checks.database = {
      status: 'unhealthy',
      error: error.message
    };
  }

  // Redis connection check
  try {
    await redisClient.ping();
    health.checks.cache = {
      status: 'healthy'
    };
  } catch (error) {
    health.checks.cache = {
      status: 'degraded',
      error: error.message
    };
  }

  // S3 connectivity check
  try {
    await s3Client.send(new HeadBucketCommand({ 
      Bucket: process.env.AWS_S3_BUCKET_NAME 
    }));
    health.checks.storage = {
      status: 'healthy'
    };
  } catch (error) {
    health.checks.storage = {
      status: 'degraded',
      error: error.message
    };
  }

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});
```

---

## Deployment Guide

### Prerequisites

#### Development Environment
- **Node.js** v18+ LTS
- **MongoDB** v4.4+ (local or Atlas)
- **Redis** v6.0+ (optional but recommended)
- **AWS Account** with S3 access
- **Firebase Project** for push notifications
- **Git** for version control

#### Production Environment
- **Ubuntu Server** 22.04 LTS (recommended)
- **NGINX** as reverse proxy
- **PM2** for process management
- **SSL Certificate** (Let's Encrypt)
- **Domain Name** with DNS configured

### Environment Configuration

#### Backend (.env)

```bash
# Server Configuration
NODE_ENV=production
PORT=5000
LOG_LEVEL=info

# MongoDB
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/taskmanager?retryWrites=true&w=majority

# JWT Authentication
JWT_SECRET=your-256-bit-secret-key-here
JWT_EXPIRES_IN=7d

# AWS S3
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=ap-south-1
AWS_S3_BUCKET_NAME=task-manager-files

# Firebase Admin SDK
FIREBASE_PROJECT_ID=task-manager-12345
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@task-manager-12345.iam.gserviceaccount.com

# Redis (optional)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# CORS
CORS_ORIGIN=https://yourdomain.com

# Master Admin
MASTER_ADMIN_USERNAME=admin
MASTER_ADMIN_PASSWORD=$2a$10$hashedPasswordHere
```

#### Mobile App (.env)

```bash
# API Configuration
API_BASE_URL=https://api.taskmanager.com/api/v1
SOCKET_URL=https://api.taskmanager.com

# Firebase (from Firebase Console)
FIREBASE_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
FIREBASE_APP_ID=1:123456789:android:abcdef1234567890
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_PROJECT_ID=task-manager-12345
```

### Server Deployment

#### Step 1: Server Setup

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Node.js 18.x LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Install NGINX
sudo apt install -y nginx

# Install Certbot for SSL
sudo apt install -y certbot python3-certbot-nginx

# Install Git
sudo apt install -y git
```

#### Step 2: Application Deployment

```bash
# Clone repository
cd /var/www
sudo git clone https://github.com/yourusername/task-manager.git
cd task-manager/server

# Install dependencies
npm install --production

# Create .env file
sudo nano .env
# (Copy production environment variables)

# Test server
npm start

# If successful, set up PM2
pm2 start server.js --name task-manager-api
pm2 save
pm2 startup
```

#### Step 3: NGINX Configuration

```nginx
# /etc/nginx/sites-available/task-manager

upstream task_manager_backend {
    server 127.0.0.1:5000;
    keepalive 64;
}

server {
    listen 80;
    server_name api.taskmanager.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.taskmanager.com;

    # SSL Configuration (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/api.taskmanager.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.taskmanager.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/task-manager-access.log;
    error_log /var/log/nginx/task-manager-error.log;

    # File upload size limit
    client_max_body_size 20M;

    # Proxy settings
    location / {
        proxy_pass http://task_manager_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket support for Socket.IO
    location /socket.io/ {
        proxy_pass http://task_manager_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket timeout
        proxy_read_timeout 86400;
    }
}
```

#### Step 4: SSL Certificate

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/task-manager /etc/nginx/sites-enabled/

# Test NGINX configuration
sudo nginx -t

# Restart NGINX
sudo systemctl restart nginx

# Obtain SSL certificate
sudo certbot --nginx -d api.taskmanager.com

# Auto-renewal (Certbot sets this up automatically)
sudo certbot renew --dry-run
```

#### Step 5: PM2 Process Management

```bash
# Start application
pm2 start server.js --name task-manager-api --instances 2 --exec-mode cluster

# View logs
pm2 logs task-manager-api

# Monitor
pm2 monit

# Restart
pm2 restart task-manager-api

# Stop
pm2 stop task-manager-api

# Auto-start on boot
pm2 startup
pm2 save
```

#### PM2 Ecosystem File

```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'task-manager-api',
    script: './server.js',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024'
  }]
};

// Start with: pm2 start ecosystem.config.js
```

### Mobile App Deployment

#### Android APK Build

```bash
# Navigate to project root
cd task-manager-main

# Ensure .env file exists with production config
cat .env

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Output location
# build/app/outputs/flutter-apk/app-release.apk
```

#### Android App Bundle (for Play Store)

```bash
# Build App Bundle
flutter build appbundle --release

# Output location
# build/app/outputs/bundle/release/app-release.aab
```

#### iOS Build (macOS only)

```bash
# Update pods
cd ios
pod install
cd ..

# Build IPA
flutter build ios --release

# Archive in Xcode for App Store submission
open ios/Runner.xcworkspace
```

#### Over-the-Air (OTA) Updates

**Server Setup:**
```javascript
// Host version manifest
app.get('/api/v1/app/version', (req, res) => {
  res.json({
    version: '1.3.0',
    buildNumber: 6,
    url: 'https://updates.taskmanager.com/app-release.apk',
    changelog: [
      'Bug fixes and performance improvements',
      'New task filtering options',
      'Enhanced offline mode'
    ],
    mandatory: false,
    minSupportedVersion: '1.0.0'
  });
});
```

**Client Implementation:**
```dart
// Check for updates on app start
Future<void> checkForUpdates() async {
  final response = await ApiClient().get('/app/version');
  final currentVersion = await PackageInfo.fromPlatform();
  
  if (response['version'] != currentVersion.version) {
    // Show update dialog
    showUpdateDialog(
      newVersion: response['version'],
      changelog: response['changelog'],
      mandatory: response['mandatory'],
      downloadUrl: response['url']
    );
  }
}
```

### Database Migration

#### Initial Setup

```javascript
// scripts/init-database.js
const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

async function initDatabase() {
  await mongoose.connect(process.env.MONGODB_URI);
  
  // Create master admin
  const adminExists = await User.findOne({ 
    username: process.env.MASTER_ADMIN_USERNAME 
  });
  
  if (!adminExists) {
    await User.create({
      name: 'Master Admin',
      username: process.env.MASTER_ADMIN_USERNAME,
      password: process.env.MASTER_ADMIN_PASSWORD,
      role: 'admin'
    });
    console.log('✅ Master admin created');
  }
  
  // Create indexes
  await User.collection.createIndex({ username: 1 }, { unique: true });
  await Task.collection.createIndex({ assignedTo: 1, status: 1 });
  await Task.collection.createIndex({ createdAt: -1 });
  // ... create all other indexes
  
  console.log('✅ Database initialized');
  process.exit(0);
}

initDatabase().catch(console.error);
```

#### Running Migrations

```bash
# Initialize database
node scripts/init-database.js

# Clean database (development only)
node scripts/clean-database.js

# Backup database
mongodump --uri="mongodb+srv://user:pass@cluster.mongodb.net/taskmanager" --out=./backup

# Restore database
mongorestore --uri="mongodb+srv://user:pass@cluster.mongodb.net/taskmanager" ./backup
```

### Monitoring & Maintenance

#### Log Rotation

```bash
# Install logrotate (usually pre-installed)
sudo apt install logrotate

# Configure log rotation
sudo nano /etc/logrotate.d/task-manager

# Content:
/var/www/task-manager/server/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        pm2 reloadLogs
    endscript
}
```

#### Backup Strategy

```bash
#!/bin/bash
# scripts/backup.sh

# Configuration
BACKUP_DIR="/var/backups/task-manager"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
MONGODB_URI="your_mongodb_uri"
S3_BUCKET="task-manager-backups"

# Create backup directory
mkdir -p $BACKUP_DIR/$DATE

# Backup MongoDB
mongodump --uri="$MONGODB_URI" --out=$BACKUP_DIR/$DATE/mongodb

# Backup application files
tar -czf $BACKUP_DIR/$DATE/app.tar.gz /var/www/task-manager

# Upload to S3
aws s3 cp $BACKUP_DIR/$DATE s3://$S3_BUCKET/$DATE/ --recursive

# Keep only last 7 days locally
find $BACKUP_DIR -type d -mtime +7 -exec rm -rf {} +

echo "Backup completed: $DATE"
```

#### Automated Monitoring

```bash
# Cron job for daily backups
0 2 * * * /var/www/task-manager/scripts/backup.sh

# Health check every 5 minutes
*/5 * * * * curl -f http://localhost:5000/health || systemctl restart task-manager-api

# Log cleanup weekly
0 0 * * 0 find /var/www/task-manager/server/logs -name "*.log" -mtime +30 -delete
```

---

## Troubleshooting

### Common Issues

#### 1. MongoDB Connection Failed

**Symptom:**
```
MongooseError: Could not connect to any servers in your MongoDB Atlas cluster
```

**Solutions:**
- Verify MongoDB URI in `.env` file
- Check if IP address is whitelisted in MongoDB Atlas
- Ensure network security group allows outbound connections
- Verify MongoDB cluster is running
- Check credentials are correct

**Test connection:**
```bash
mongosh "mongodb+srv://username:password@cluster.mongodb.net/taskmanager"
```

---

#### 2. JWT Token Invalid

**Symptom:**
```json
{
  "success": false,
  "message": "Invalid token"
}
```

**Solutions:**
- Verify `JWT_SECRET` matches between server and client
- Check token hasn't expired (7-day limit)
- Ensure token is sent in `Authorization: Bearer <token>` header
- Clear app data/cache and login again

**Debug token:**
```javascript
const jwt = require('jsonwebtoken');
const decoded = jwt.verify(token, process.env.JWT_SECRET);
console.log(decoded);
```

---

#### 3. File Upload Fails

**Symptom:**
```
Error: File type not allowed
```

**Solutions:**
- Check file MIME type is in allowed list
- Verify file size is under 20MB limit
- Ensure AWS S3 credentials are correct
- Check S3 bucket permissions
- Verify bucket region matches configuration

**Test S3 upload:**
```javascript
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const client = new S3Client({...});
await client.send(new PutObjectCommand({
  Bucket: 'your-bucket',
  Key: 'test.txt',
  Body: 'Hello World'
}));
```

---

#### 4. Socket.IO Connection Failed

**Symptom:**
- Messages not appearing in real-time
- Connection timeout errors

**Solutions:**
- Verify WebSocket support in NGINX configuration
- Check CORS settings allow Socket.IO connections
- Ensure firewall allows WebSocket traffic
- Verify Socket.IO client version matches server version
- Check authentication token is being sent in handshake

**Debug Socket.IO:**
```javascript
// Server
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
});

// Client
socket.on('connect', () => {
  console.log('Connected to server');
});

socket.on('connect_error', (error) => {
  console.error('Connection error:', error);
});
```

---

#### 5. Push Notifications Not Working

**Symptom:**
- Notifications not received on mobile device

**Solutions:**
- Verify Firebase credentials are correct
- Check FCM token is registered with backend
- Ensure notification permissions are granted
- Verify Firebase project ID matches
- Check device has internet connection

**Test FCM:**
```bash
# Send test notification via Firebase Console
# Or use FCM API directly
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test",
      "body": "Test notification"
    }
  }'
```

---

#### 6. High Memory Usage

**Symptom:**
```
pm2 status shows memory usage > 1GB
```

**Solutions:**
- Enable memory limit in PM2 configuration
- Check for memory leaks using heap snapshots
- Optimize database queries (use `.lean()`)
- Implement pagination for large datasets
- Clear unused cache entries

**Monitor memory:**
```bash
# PM2 monitoring
pm2 monit

# Node.js heap snapshot
node --inspect server.js
# Open chrome://inspect in Chrome
```

---

#### 7. Slow API Response Times

**Symptom:**
- API requests taking > 500ms

**Solutions:**
- Check database indexes are created
- Enable query optimization
- Implement caching for frequently accessed data
- Use CDN for static assets
- Optimize image sizes
- Enable GZIP compression

**Profile queries:**
```javascript
// Enable Mongoose query profiling
mongoose.set('debug', true);

// Analyze slow queries in MongoDB
db.setProfilingLevel(2);
db.system.profile.find().sort({ts: -1}).limit(5);
```

---

### Debug Mode

#### Enable Debug Logging

```bash
# .env file
LOG_LEVEL=debug
NODE_ENV=development

# Restart application
pm2 restart task-manager-api
```

#### View Logs

```bash
# PM2 logs
pm2 logs task-manager-api

# Application logs
tail -f server/logs/combined-2026-07-18.log

# Error logs only
tail -f server/logs/error-2026-07-18.log

# Security events
tail -f server/logs/security-2026-07-18.log

# NGINX logs
sudo tail -f /var/log/nginx/task-manager-access.log
sudo tail -f /var/log/nginx/task-manager-error.log
```

#### Common Log Patterns

**Successful login:**
```json
{
  "timestamp": "2026-07-18T10:30:45.123Z",
  "level": "info",
  "message": "User logged in",
  "type": "AUTH_EVENT",
  "userId": "64a5e7f8...",
  "username": "john.doe",
  "role": "employee",
  "ip": "192.168.1.100"
}
```

**Failed authentication:**
```json
{
  "timestamp": "2026-07-18T10:31:12.456Z",
  "level": "warn",
  "message": "Failed login attempt",
  "type": "SECURITY_EVENT",
  "username": "john.doe",
  "ip": "192.168.1.100",
  "userAgent": "Mozilla/5.0..."
}
```

**Database query:**
```json
{
  "timestamp": "2026-07-18T10:32:00.789Z",
  "level": "debug",
  "message": "MongoDB Query",
  "type": "DB_QUERY",
  "collection": "tasks",
  "method": "find",
  "query": "{\"assignedTo\":\"64a5e7f8...\"}"
}
```

---

## Appendices

### Appendix A: API Error Codes

| HTTP Code | Error Type | Description |
|-----------|------------|-------------|
| 400 | Bad Request | Invalid request parameters or body |
| 401 | Unauthorized | Missing or invalid authentication token |
| 403 | Forbidden | User lacks permission for requested action |
| 404 | Not Found | Requested resource does not exist |
| 409 | Conflict | Resource already exists (e.g., duplicate username) |
| 413 | Payload Too Large | File upload exceeds size limit |
| 422 | Unprocessable Entity | Validation error (e.g., invalid password format) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |
| 503 | Service Unavailable | Server or dependent service is down |

### Error Response Format

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional error details",
    "field": "fieldName"
  }
}
```

---

### Appendix B: Database Indexes

#### Complete Index List

```javascript
// Users Collection
db.users.createIndex({ "username": 1 }, { unique: true })
db.users.createIndex({ "role": 1 })
db.users.createIndex({ "createdAt": -1 })

// Tasks Collection
db.tasks.createIndex({ "assignedTo": 1, "status": 1 })
db.tasks.createIndex({ "createdAt": -1 })
db.tasks.createIndex({ "dueDate": 1, "status": 1 })
db.tasks.createIndex({ "parentTaskId": 1 })
db.tasks.createIndex({ "status": 1 })
db.tasks.createIndex({ "priority": 1 })

// Messages Collection
db.messages.createIndex({ "taskId": 1, "createdAt": 1 })
db.messages.createIndex({ "taskId": 1, "sender": 1, "readBy.user": 1 })
db.messages.createIndex({ "createdAt": -1 })

// Submissions Collection
db.submissions.createIndex({ "task": 1 })
db.submissions.createIndex({ "employee": 1 })
db.submissions.createIndex({ "status": 1 })
db.submissions.createIndex({ "createdAt": -1 })
db.submissions.createIndex({ "task": 1, "employee": 1 })
```

#### Index Performance Impact

| Collection | Query Pattern | Index Used | Performance |
|------------|---------------|------------|-------------|
| tasks | Find by assignee | `{assignedTo: 1, status: 1}` | < 10ms |
| tasks | Recent tasks | `{createdAt: -1}` | < 5ms |
| messages | Task history | `{taskId: 1, createdAt: 1}` | < 15ms |
| submissions | Employee work | `{employee: 1}` | < 10ms |

---

### Appendix C: Environment Variables Reference

#### Required Variables

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `NODE_ENV` | string | production | Application environment |
| `PORT` | number | 5000 | Server port |
| `MONGODB_URI` | string | mongodb+srv://... | MongoDB connection string |
| `JWT_SECRET` | string | 256-bit-key | JWT signing secret |
| `AWS_ACCESS_KEY_ID` | string | AKIAIOSFODNN7EXAMPLE | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | string | wJalrXUt... | AWS secret key |
| `AWS_REGION` | string | ap-south-1 | AWS region |
| `AWS_S3_BUCKET_NAME` | string | task-manager-files | S3 bucket name |
| `FIREBASE_PROJECT_ID` | string | task-manager-12345 | Firebase project ID |

#### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `JWT_EXPIRES_IN` | string | 7d | JWT expiration time |
| `LOG_LEVEL` | string | info | Logging level |
| `REDIS_HOST` | string | localhost | Redis server host |
| `REDIS_PORT` | number | 6379 | Redis server port |
| `CORS_ORIGIN` | string | * | Allowed CORS origins |
| `RATE_LIMIT_WINDOW_MS` | number | 900000 | Rate limit window (15 min) |
| `RATE_LIMIT_MAX` | number | 5 | Max requests per window |

---

### Appendix D: Testing Guide

#### Unit Tests

```javascript
// Example: Test user authentication
const request = require('supertest');
const app = require('../app');

describe('Authentication', () => {
  test('POST /auth/login - should authenticate valid user', async () => {
    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'testuser@ith.com',
        password: 'TestPassword@123'
      });
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.token).toBeDefined();
  });

  test('POST /auth/login - should reject invalid credentials', async () => {
    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'testuser@ith.com',
        password: 'wrongpassword'
      });
    
    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
  });
});
```

#### Integration Tests

```javascript
// Example: Test task creation workflow
describe('Task Management', () => {
  let authToken;
  let taskId;

  beforeAll(async () => {
    // Login to get auth token
    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'admin@ith.com', password: 'Admin@123' });
    authToken = response.body.data.token;
  });

  test('should create new task', async () => {
    const response = await request(app)
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        title: 'Test Task',
        description: 'Test Description',
        assignedTo: ['user_id_123'],
        dueDate: '2026-08-01',
        priority: 'high'
      });
    
    expect(response.status).toBe(201);
    taskId = response.body.data._id;
  });

  test('should retrieve created task', async () => {
    const response = await request(app)
      .get(`/api/v1/tasks/${taskId}`)
      .set('Authorization', `Bearer ${authToken}`);
    
    expect(response.status).toBe(200);
    expect(response.body.data.title).toBe('Test Task');
  });
});
```

#### Load Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test API endpoint (100 requests, 10 concurrent)
ab -n 100 -c 10 -H "Authorization: Bearer YOUR_TOKEN" \
   http://localhost:5000/api/v1/tasks

# Results analysis
# - Requests per second: Should be > 50
# - Mean response time: Should be < 200ms
# - Failed requests: Should be 0
```

---

### Appendix E: Security Checklist

#### Pre-Deployment Security Review

- [ ] All environment variables properly configured
- [ ] Secrets not committed to Git
- [ ] SSL/TLS certificates installed and valid
- [ ] HTTPS enforced (HTTP redirects to HTTPS)
- [ ] CORS configured correctly (not set to `*` in production)
- [ ] Rate limiting enabled on all endpoints
- [ ] Input validation implemented
- [ ] XSS protection enabled (sanitize-html)
- [ ] SQL/NoSQL injection prevention (Mongoose ODM)
- [ ] Password complexity requirements enforced
- [ ] JWT secret is strong (256-bit minimum)
- [ ] File upload validation enabled
- [ ] S3 bucket permissions properly restricted
- [ ] Database backups scheduled
- [ ] Logging configured and monitored
- [ ] Security headers implemented (Helmet)
- [ ] Authentication required on all protected endpoints
- [ ] Authorization checks on sensitive operations
- [ ] MongoDB authentication enabled
- [ ] Firewall rules configured
- [ ] Server hardening completed

#### Regular Security Audits

**Monthly:**
- Review access logs for suspicious activity
- Check for failed login attempts
- Verify SSL certificate expiration dates
- Update dependencies (npm audit)
- Review user permissions

**Quarterly:**
- Full security penetration testing
- Code security review
- Infrastructure vulnerability scan
- Backup restoration test
- Disaster recovery drill

---

### Appendix F: Performance Benchmarks

#### Target Performance Metrics

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| API Response Time | < 100ms | < 200ms | > 500ms |
| Database Query Time | < 50ms | < 100ms | > 200ms |
| Page Load Time | < 2s | < 3s | > 5s |
| File Upload (10MB) | < 5s | < 10s | > 20s |
| WebSocket Latency | < 50ms | < 100ms | > 200ms |
| Memory Usage | < 512MB | < 1GB | > 2GB |
| CPU Usage | < 50% | < 70% | > 90% |

#### Load Testing Results

**Test Configuration:**
- Server: 2 vCPU, 4GB RAM
- Database: MongoDB Atlas M10
- Concurrent Users: 100
- Test Duration: 5 minutes

**Results:**
```
Endpoint: GET /api/v1/tasks
- Requests/sec: 245
- Mean response time: 87ms
- 95th percentile: 124ms
- 99th percentile: 201ms
- Failed requests: 0%

Endpoint: POST /api/v1/tasks
- Requests/sec: 156
- Mean response time: 143ms
- 95th percentile: 198ms
- 99th percentile: 287ms
- Failed requests: 0%

WebSocket Connections:
- Max concurrent: 1000
- Message latency: 45ms avg
- Connection success rate: 99.9%
```

---

### Appendix G: Changelog

#### Version 1.3.0 (Current)
**Release Date:** July 15, 2026

**New Features:**
- Submission comments with real-time updates
- API pagination for all list endpoints
- Enhanced offline mode with sync queue
- Circular dependency detection for tasks
- OTA update retry logic

**Improvements:**
- Structured logging with Winston
- Performance optimization (lean queries)
- Security hardening (17/20 fixes)
- Better error handling
- Improved mobile UX

**Bug Fixes:**
- Fixed Socket.IO reconnection issues
- Resolved race condition in mark-as-read
- Fixed notification text truncation
- Corrected dependency cascade delete

---

#### Version 1.2.0
**Release Date:** July 1, 2026

**New Features:**
- Sequential task workflows (dependsOn)
- Task history audit trail
- Admin file attachments
- Real-time typing indicators

**Improvements:**
- Faster task list loading
- Better error messages
- Improved push notifications

---

#### Version 1.1.0
**Release Date:** June 15, 2026

**New Features:**
- 7-day persistent sessions
- Back button protection
- Task deletion (admin only)
- Real-time chat with Socket.IO

**Improvements:**
- UI/UX enhancements
- Performance optimizations
- Security improvements

---

#### Version 1.0.0
**Release Date:** June 1, 2026

**Initial Release:**
- User authentication
- Task management
- Submission system
- Push notifications
- File uploads to S3
- Mobile app (iOS/Android)

---

### Appendix H: Support & Resources

#### Official Resources
- **Documentation:** https://docs.taskmanager.com
- **API Reference:** https://api.taskmanager.com/docs
- **Status Page:** https://status.taskmanager.com
- **Community Forum:** https://community.taskmanager.com

#### Technical Support
- **Email:** support@taskmanager.com
- **Emergency:** +1-555-TASK-911
- **Response Time:** 24 hours (business days)

#### Developer Resources
- **GitHub Repository:** https://github.com/yourusername/task-manager
- **Issue Tracker:** https://github.com/yourusername/task-manager/issues
- **NPM Package:** https://www.npmjs.com/package/task-manager-api
- **Docker Images:** https://hub.docker.com/r/taskmanager/api

#### Third-Party Services
- **MongoDB Atlas:** https://cloud.mongodb.com
- **AWS Console:** https://console.aws.amazon.com
- **Firebase Console:** https://console.firebase.google.com
- **Let's Encrypt:** https://letsencrypt.org

---

## Conclusion

This technical documentation provides a comprehensive overview of the Task Manager application architecture, implementation details, deployment procedures, and maintenance guidelines. The system is designed for scalability, security, and performance, making it suitable for enterprise deployments.

For questions, issues, or contributions, please refer to the Support & Resources section or contact the development team.

---

**Document Status:** Complete  
**Last Reviewed:** July 18, 2026  
**Next Review:** October 18, 2026  
**Maintained By:** Technical Documentation Team  

---

*Copyright © 2026 Task Manager. All rights reserved.*
