# Task Manager - Collaborative Productivity Platform

**Version:** 1.3.0  
**Status:** Production Ready  
**Branch:** feat/bulk-user-import

---

## Overview

Task Manager is a multi-tenant, role-based productivity platform designed for teams to efficiently manage work, collaborate in real-time, and track performance. Built with Node.js/Express backend and Flutter mobile app.

### Key Features

- **Task Management** - Create, assign, and track tasks with priorities and deadlines
- **Real-time Collaboration** - Socket.IO-powered live updates and messaging
- **Submission Tracking** - Submit work for review and get instant feedback
- **Performance Analytics** - Leaderboards, dashboards, and detailed reporting
- **File Management** - AWS S3 integration for secure file storage
- **Push Notifications** - Firebase Cloud Messaging for instant alerts
- **Multi-tenant Architecture** - Complete data isolation between organizations

---

## Technology Stack

### Backend
- **Runtime:** Node.js v16+
- **Framework:** Express.js v4.18+
- **Database:** MongoDB v4.4+
- **Auth:** JWT (jsonwebtoken)
- **Real-time:** Socket.IO v4.8+
- **File Storage:** AWS S3
- **Notifications:** Firebase Cloud Messaging
- **Logging:** Winston with daily rotation

### Frontend
- **Framework:** Flutter (SDK >=3.2.0)
- **Language:** Dart
- **State Management:** Riverpod v2.5+
- **HTTP Client:** Dio v5.4+
- **Real-time:** socket_io_client v3.1+
- **Local Storage:** Hive + SharedPreferences
- **Notifications:** Firebase Messaging

---

## Project Structure

```
Taskmanager/
├── backend/                    # Node.js/Express API server
│   ├── controllers/           # Route handlers
│   ├── models/               # MongoDB schemas
│   ├── routes/               # API endpoints
│   ├── middleware/           # Express middleware
│   ├── services/             # External integrations
│   ├── utils/                # Helper functions
│   ├── jobs/                 # Scheduled tasks
│   ├── config/               # Configuration files
│   ├── logs/                 # Application logs (git-ignored)
│   ├── .env                  # Environment variables (git-ignored)
│   ├── .env.example          # Environment template
│   ├── package.json          # Dependencies
│   └── server.js             # Entry point
│
├── frontend/                  # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart         # App entry point
│   │   ├── screens/          # UI screens
│   │   ├── widgets/          # Reusable components
│   │   ├── providers/        # State management
│   │   ├── services/         # API & storage
│   │   ├── models/           # Data models
│   │   └── utils/            # Helpers
│   ├── .env                  # Frontend config (git-ignored)
│   ├── .env.example          # Configuration template
│   ├── pubspec.yaml          # Dependencies
│   └── pubspec.lock          # Lock file
│
├── .kiro/                     # Kiro AI configuration
│   ├── specs/                # Feature specifications
│   │   └── bulk-user-import/ # Bulk import feature spec
│   └── steering/             # Project guidelines
│
├── docs/                      # Documentation
│   ├── API_REFERENCE.md      # API endpoint docs
│   ├── TECHNICAL_DOCUMENTATION.md
│   ├── USER_GUIDE.md         # End-user manual
│   ├── ROADMAP.md            # Feature roadmap
│   └── ROLES_AND_PERMISSIONS.md
│
├── .gitignore                # Git ignore patterns
├── README.md                 # This file
└── .git/                     # Git repository
```

---

## Getting Started

### Prerequisites

- Node.js v16+ and npm
- Flutter SDK v3.2.0+
- MongoDB Atlas account (or local MongoDB)
- AWS S3 bucket for file storage
- Firebase project for notifications

### Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Start development server
npm run dev
# Server runs on http://localhost:5000
```

### Frontend Setup

```bash
cd frontend

# Install dependencies
flutter pub get

# Configure backend URL
echo "BACKEND_URL=http://192.168.X.X:5000" > .env

# Run on device/emulator
flutter run
```

---

## API Endpoints

All endpoints are prefixed with `/api/v1`

### Authentication
- `POST /auth/login` - Login and get JWT token
- `POST /auth/users` - Create new user (admin only)
- `PUT /auth/me/profile` - Update own profile
- `PUT /auth/fcm-token` - Register FCM token

### Tasks
- `GET /tasks` - Get all tasks (filtered by role/organization)
- `GET /tasks/:id` - Get task details
- `POST /tasks` - Create new task (admin only)
- `PUT /tasks/:id` - Update task
- `DELETE /tasks/:id` - Delete task (admin only)

### Submissions
- `GET /submissions/pending` - Get pending submissions (admin)
- `GET /submissions/member/my` - Get own submissions (member)
- `POST /submissions` - Submit work with attachments (member)
- `PATCH /submissions/:id/status` - Approve/reject submission (admin)

### Analytics
- `GET /analytics/leaderboard` - Get performance leaderboard
- `GET /analytics/stats` - Get system statistics
- `GET /analytics/activity` - Get team activity feed

See [docs/API_REFERENCE.md](docs/API_REFERENCE.md) for complete API documentation.

---

## User Roles

### Super Admin
- Manage organizations and their settings
- View system-wide analytics
- Access all admin features across all organizations

### Admin
- Manage team members within organization
- Create and assign tasks
- Review and approve submissions
- View team analytics and leaderboards

### Member
- View assigned tasks
- Submit work and receive feedback
- Chat and collaborate on tasks
- View personal performance metrics

---

## Environment Configuration

### Backend (.env)

```env
PORT=5000
NODE_ENV=development

# Database
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/dbname

# Authentication
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# AWS S3
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_REGION=ap-south-1
AWS_BUCKET_NAME=your-bucket

# Firebase
FIREBASE_SERVICE_ACCOUNT={...}

# Backend URL
BACKEND_URL=http://localhost:5000
```

### Frontend (.env)

```env
BACKEND_URL=http://192.168.X.X:5000
```

---

## Development

### Start Backend (Local)
```bash
cd backend
npm run dev      # With auto-reload (nodemon)
```

### Start Backend (Production)
```bash
cd backend
npm run pm2:start    # With PM2 process manager
npm run pm2:logs     # View logs
npm run pm2:restart  # Restart process
```

### Run Flutter App
```bash
cd frontend
flutter run -d device-id    # Specific device
flutter run -d chrome       # Web (development)
```

### View Logs
```bash
cd backend
npm run pm2:logs
# Or: tail -f logs/combined-*.log
```

---

## Features Under Development

### Phase: Bulk User Import
- Import multiple users from Excel/CSV
- Batch account creation with default passwords
- Duplicate detection and member limit enforcement
- Detailed import reports and audit logging

See [.kiro/specs/bulk-user-import/](\.kiro\specs\bulk-user-import\) for full specification.

---

## Documentation

- **[API Reference](docs/API_REFERENCE.md)** - Complete API endpoint reference
- **[Technical Documentation](docs/TECHNICAL_DOCUMENTATION.md)** - Architecture, deployment, and internals
- **[User Guide](docs/USER_GUIDE.md)** - End-user manual for all roles
- **[Roadmap](docs/ROADMAP.md)** - Feature roadmap and development phases
- **[Roles & Permissions](docs/ROLES_AND_PERMISSIONS.md)** - Permission matrix

---

## Security

- **JWT Authentication** - Stateless token-based auth
- **Password Hashing** - bcryptjs with salt rounds
- **Rate Limiting** - 100 requests per 15 minutes per IP
- **Input Validation** - Joi schema validation on all endpoints
- **CORS** - Environment-specific CORS configuration
- **Security Headers** - Helmet.js middleware
- **XSS Protection** - HTML sanitization
- **File Upload Limits** - 2MB per request

---

## Performance

- **Response Compression** - Gzip enabled (1KB threshold)
- **Database Indexes** - Optimized queries with indexes
- **Caching** - Redis caching for read-heavy endpoints
- **Real-time Events** - Namespace-based Socket.IO for efficient messaging
- **Monitoring** - Performance middleware tracks response times

---

## Testing

See feature specs for comprehensive test cases:
- **Phase 2 Tests** - Local backend testing against mobile app
- **Phase 3 Tests** - Production deployment verification
- **Unit Tests** - Service layer testing
- **Integration Tests** - End-to-end workflow validation

---

## Deployment

### Production Backend (Render)

```bash
# Deploy to Render
git push origin main

# Render automatically deploys on git push
# Set environment variables in Render dashboard
```

### Mobile App (Google Play / App Store)

```bash
# Android APK
flutter build apk --release

# iOS app
flutter build ios --release
```

---

## Support & Issues

- Report bugs via GitHub Issues
- Check existing documentation first
- Include reproduction steps and logs

---

## License

© 2026 Inno Tech Hub. All rights reserved.

---

## Repository

- **GitHub:** https://github.com/Sanjay-2oo6/Task-manager
- **Branch:** feat/bulk-user-import
- **Last Updated:** 2026-08-10

---

**Status:** 🟢 Production Ready | 🔵 Feature Development Active
