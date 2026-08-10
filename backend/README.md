# Task Manager - Backend API (Node.js)

**Tech Stack:** Node.js + Express + MongoDB + Socket.IO  
**Architecture:** RESTful API + Real-time WebSocket

---

## 🚀 Overview

Backend API server for the INNO TECH HUB Task Manager system. Provides authentication, task management, real-time messaging, and multi-tenant organization support.

---

## 📋 Quick Start

### Prerequisites
- Node.js (v16+)
- MongoDB (v4.4+)
- npm or yarn

### Installation

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Copy environment variables
copy .env.example .env

# Edit .env with your configuration
# Set MONGO_URI, JWT_SECRET, etc.

# Run development server
npm run dev
```

Server will start on `http://localhost:5000`

---

## 📁 Project Structure

```
backend/
├── config/              # Configuration files
├── controllers/         # Route controllers (business logic)
├── middleware/          # Express middleware (auth, validation, etc.)
├── models/              # MongoDB/Mongoose models
├── routes/              # API route definitions
├── services/            # External services (S3, FCM, email)
├── utils/               # Helper functions and utilities
├── jobs/                # Cron jobs and scheduled tasks
├── logs/                # Application logs
├── scripts/             # Database migration and utility scripts
├── node_modules/        # Dependencies (not in git)
├── .env                 # Environment variables (not in git)
├── app.js               # Express app configuration
├── server.js            # Server entry point
└── package.json         # Dependencies and scripts
```

---

## 🔧 Configuration

### Environment Variables (`.env`)

```env
# Server
PORT=5000
NODE_ENV=development

# Database
MONGO_URI=mongodb://localhost:27017/taskmanager

# Authentication
JWT_SECRET=your-super-secure-secret-key-here
JWT_EXPIRES_IN=7d

# AWS S3 (for file uploads)
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket-name

# Firebase Cloud Messaging (push notifications)
FCM_SERVER_KEY=your-fcm-server-key

# Email (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Master Admin
MASTER_ADMIN_USERNAME=sanjay
```

---

## 🛠️ Development

### Start Development Server
```bash
npm run dev
```
Uses `nodemon` for auto-restart on file changes.

### Start Production Server
```bash
npm start
```

### Run Tests
```bash
npm test
```

### Lint Code
```bash
npm run lint
```

---

## 📡 API Endpoints

### Base URL
```
http://localhost:5000/api/v1
```

### Authentication
```
POST   /auth/login              - User login
POST   /auth/users              - Create user (Admin only)
GET    /auth/users              - Get all users (Admin only)
GET    /auth/me                 - Get current user
PATCH  /auth/me/password        - Change own password
DELETE /auth/users/:id          - Delete user (Admin only)
PATCH  /auth/fcm-token          - Update FCM token
```

### Tasks
```
POST   /tasks                   - Create task (Admin only)
GET    /tasks                   - Get all tasks (filtered by role)
GET    /tasks/:id               - Get task by ID
PATCH  /tasks/:id               - Update task
DELETE /tasks/:id               - Delete task (Admin only)
POST   /tasks/:id/assign        - Assign task to users
POST   /tasks/:id/comments      - Add comment to task
POST   /tasks/bulk-update       - Bulk update tasks
```

### Submissions
```
POST   /submissions             - Submit work
GET    /submissions             - Get all submissions (filtered by role)
GET    /submissions/:id         - Get submission by ID
PATCH  /submissions/:id/status  - Update submission status (Admin only)
POST   /submissions/:id/comments - Add comment to submission
```

### Messages
```
POST   /messages                - Send message
GET    /messages/task/:taskId   - Get messages for task
PATCH  /messages/mark-read/:taskId - Mark messages as read
```

### Analytics
```
GET    /analytics/leaderboard   - Get team leaderboard (Admin only)
GET    /analytics/team-activity - Get team activity (Admin only)
GET    /analytics/dashboard-stats - Get dashboard stats
```

### Super Admin (Coming Soon - Multi-tenant)
```
POST   /super-admin/organizations           - Create organization
GET    /super-admin/organizations            - List organizations
PATCH  /super-admin/organizations/:id        - Update organization
DELETE /super-admin/organizations/:id        - Delete organization
POST   /super-admin/organizations/:id/toggle - Activate/deactivate org
```

---

## 🔒 Security Features

✅ **JWT Authentication** - Secure token-based auth  
✅ **Password Hashing** - bcrypt with salt  
✅ **Input Sanitization** - XSS protection  
✅ **Rate Limiting** - Prevent brute force  
✅ **CORS** - Configured for frontend  
✅ **Helmet** - Security headers  
✅ **Role-Based Access Control** - Permission system  
✅ **Strong Password Validation** - Enforced rules  

---

## 📊 Database Models

### User
- name, username, password (hashed)
- role: `member`, `admin`, `super_admin`
- fcmToken (push notifications)
- lastLoginTimestamp

### Task
- title, description, status, priority
- assignedTo (array of user IDs)
- createdBy (user ID)
- dueDate, adminNote, adminFiles
- dependsOn (task dependencies)
- history (audit trail)

### Submission
- task (task ID)
- user (user ID)
- status: `pending`, `approved`, `rejected`
- beforeFiles, afterFiles
- description, feedback

### Message
- taskId, sender (user ID)
- text, isSystem (for system messages)
- readBy (array of user IDs)

---

## 🔄 Real-time Features (Socket.IO)

### Events Emitted by Server
```javascript
'task-assigned'      // New task assigned to user
'task-updated'       // Task status/details changed
'task-deleted'       // Task deleted
'new-chat-message'   // New message in task chat
'submission-updated' // Submission status changed
```

### Events Received from Client
```javascript
'join-task'          // User joins task room for updates
'leave-task'         // User leaves task room
```

---

## 📦 Key Dependencies

- `express` - Web framework
- `mongoose` - MongoDB ORM
- `jsonwebtoken` - JWT authentication
- `bcryptjs` - Password hashing
- `socket.io` - Real-time communication
- `aws-sdk` - S3 file uploads
- `multer` - File upload handling
- `node-cron` - Scheduled tasks
- `dotenv` - Environment variables
- `helmet` - Security headers
- `cors` - Cross-origin requests

See `package.json` for complete list.

---

## 🗄️ Database Scripts

### Active Scripts
```bash
# Create test accounts
node scripts/create-test-accounts.js

# Reset database
node scripts/full-reset-db.js

# Set super admin
node scripts/set-super-admin.js

# Reset super admin password
node scripts/reset-super-admin-password.js
```

### Archived Migration Scripts
Legacy migration scripts (for multi-tenant conversion) are archived in `scripts/archived/`:
- `migrate-roles.js` - Role system migration
- `migrate-to-multitenant.js` - Multi-tenant conversion
- `migrate-username-to-email.js` - Username to email migration

### Backup & Restore
```bash
# Backup Database
mongodump --uri="mongodb://localhost:27017/taskmanager" --out=./backups/$(date +%Y%m%d)

# Restore Database
mongorestore --uri="mongodb://localhost:27017/taskmanager" ./backups/20260718
```

---

## 🧪 Testing

### Test API Endpoints
```bash
# Using the test script
node test-endpoints.js

# Or use Postman/Insomnia
# Import collection from API_TEST_GUIDE.md
```

### Load Testing
```bash
# Install artillery
npm install -g artillery

# Run load test
artillery quick --count 10 --num 50 http://localhost:5000/api/v1/tasks
```

---

## 🚀 Deployment

### Production Checklist
- [ ] Set `NODE_ENV=production` in `.env`
- [ ] Use strong `JWT_SECRET`
- [ ] Configure MongoDB Atlas or production database
- [ ] Set up AWS S3 bucket for file uploads
- [ ] Configure FCM for push notifications
- [ ] Set up SSL/TLS certificate
- [ ] Configure reverse proxy (nginx)
- [ ] Set up process manager (PM2)
- [ ] Configure monitoring (e.g., New Relic)
- [ ] Set up logging (Winston to file/service)

### Deploy with PM2
```bash
# Install PM2
npm install -g pm2

# Start application
pm2 start server.js --name task-manager-api

# Monitor
pm2 monit

# View logs
pm2 logs task-manager-api

# Restart
pm2 restart task-manager-api
```

---

## 🐛 Troubleshooting

**Issue: "ECONNREFUSED" MongoDB connection error**
- Ensure MongoDB is running: `mongod`
- Check MONGO_URI in `.env`

**Issue: JWT verification failed**
- Check JWT_SECRET matches between requests
- Token may have expired (default 7 days)

**Issue: File upload fails**
- Verify AWS credentials in `.env`
- Check S3 bucket permissions
- Ensure bucket region matches AWS_REGION

**Issue: Push notifications not working**
- Verify FCM_SERVER_KEY is correct
- Check device FCM token is registered
- Ensure Firebase project is configured

---

## 📚 Related Documentation

- [API Reference](../docs/API_REFERENCE.md) - Complete endpoint documentation
- [User Guide](../docs/USER_GUIDE.md) - End-user manual
- [Technical Documentation](../docs/TECHNICAL_DOCUMENTATION.md) - Architecture details
- [Roles & Permissions](../docs/ROLES_AND_PERMISSIONS.md) - Permission matrix

---

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Run tests and linting
4. Submit a pull request

---

## 📝 Change Log

### v2.0.0 (July 2026)
- ✅ New role system (member, admin, super_admin)
- ✅ Multi-tenant preparation
- ✅ Enhanced security features
- ✅ Improved error handling and logging

### v1.0.0 (Initial Release)
- ✅ Basic authentication
- ✅ Task management
- ✅ Real-time chat
- ✅ File uploads
- ✅ Push notifications

---

**Version:** 2.0.0  
**Last Updated:** July 18, 2026  
**Maintained by:** INNO TECH HUB
