# Task Manager - Collaborative Task Management Platform

**Version:** 1.3.0  
**Multi-Tenant SaaS Platform**  
**Built with:** Node.js/Express, Flutter, MongoDB, Socket.IO  
**Last Updated:** July 27, 2026

---

## 🚀 Quick Start

### For Developers
**CRITICAL:** Before implementing ANY feature, read `DEVELOPMENT_RULES.md` in the project root. It contains authoritative rules on:
- API structure and response formats
- Frontend implementation patterns
- Authentication & authorization
- Token efficiency practices
- Multi-tenant architecture
- All development guidelines

### Start Backend
```bash
cd backend
npm install
npm run dev
# Server running on http://localhost:5000
```

### Start Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome
# App running on http://localhost:51543
```

---

## 📁 Project Structure

```
TaskManager/
├── DEVELOPMENT_RULES.md          # ⭐ AUTHORITATIVE DEVELOPMENT GUIDE - READ FIRST
├── README.md                     # This file
├── START_HERE.md                 # Getting started guide
├── PROJECT_STATUS.md             # Current project status
├── .kiro/steering/               # AI guidance documents
│   ├── tech.md                  # Technology stack
│   ├── structure.md             # Project structure
│   └── product.md               # Product overview
│
├── docs/                         # Primary documentation
│   ├── API_REFERENCE.md         # Complete API documentation
│   ├── TECHNICAL_DOCUMENTATION.md # Architecture details
│   ├── USER_GUIDE.md            # End-user manual
│   ├── ROLES_AND_PERMISSIONS.md # Permission matrix
│   ├── ROADMAP.md               # Feature roadmap
│   ├── QUICK_REFERENCE.md       # Quick lookup
│   └── README.md                # Documentation index
│
├── backend/                      # Node.js/Express API
│   ├── config/                  # Configuration (DB, S3)
│   ├── controllers/             # Route handlers
│   ├── middleware/              # Express middleware
│   ├── models/                  # MongoDB schemas
│   ├── routes/                  # API routes
│   ├── services/                # External integrations (S3, FCM)
│   ├── scripts/                 # Database utilities
│   ├── logs/                    # Application logs
│   ├── app.js                   # Express setup
│   ├── server.js                # Server entry point
│   ├── package.json             # Dependencies
│   ├── .env                     # Environment variables (git-ignored)
│   ├── .env.example             # Environment template
│   ├── API_TEST_GUIDE.md        # Testing endpoints
│   └── README.md                # Backend setup
│
├── frontend/                     # Flutter mobile app
│   ├── lib/
│   │   ├── data/               # Data layer (API, models, services)
│   │   ├── presentation/       # UI (screens, widgets)
│   │   ├── state/              # Riverpod providers
│   │   ├── core/               # Constants, theme
│   │   └── main.dart           # App entry point
│   ├── pubspec.yaml            # Dependencies
│   ├── .env                    # Environment config
│   └── README.md               # Frontend setup
│
└── MULTI_TENANT_IMPLEMENTATION_PLAN.md # Multi-tenant strategy
```

---

## 🏗️ Architecture Overview

### Three-Layer Architecture
```
┌─────────────────────────┐
│    Flutter Frontend     │  Mobile UI, offline support
├─────────────────────────┤
│   REST API + Socket.IO  │  Node.js/Express backend
├─────────────────────────┤
│      MongoDB NoSQL      │  Tenant-scoped data storage
└─────────────────────────┘
```

### Multi-Tenant Design
- Single database, organization-scoped data isolation
- Users linked to organizations via `organizationId` field
- Super Admin (role: `super_admin`) manages organizations
- Organization Admins (role: `admin`) manage their org's data
- Members (role: `member`) perform assigned work

### Real-Time Communication
- WebSocket-based messaging via Socket.IO
- Task-based chat rooms
- Live task status updates
- Typing indicators
- Message read receipts

---

## 📚 Key Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **DEVELOPMENT_RULES.md** | ⭐ Authoritative dev guide, API structure, patterns | All developers |
| **docs/TECHNICAL_DOCUMENTATION.md** | In-depth architecture, security, performance | Developers, architects |
| **docs/API_REFERENCE.md** | Complete API endpoint listing | Frontend, backend devs |
| **docs/USER_GUIDE.md** | End-user manual and features | End users, support |
| **docs/ROLES_AND_PERMISSIONS.md** | Permission matrix | Devs implementing auth |
| **.kiro/steering/** | AI guidance for agent development | AI agents |

---

## 🔐 Security Features

- ✅ **JWT Authentication** - 7-day token expiration
- ✅ **Role-Based Access Control** - member, admin, super_admin
- ✅ **Password Hashing** - bcryptjs with 10 salt rounds
- ✅ **Request Validation** - Joi schema validation
- ✅ **Rate Limiting** - 100 req/15min per IP
- ✅ **CORS Protection** - Environment-specific origins
- ✅ **XSS Protection** - HTML sanitization
- ✅ **Helmet.js** - Security headers
- ✅ **AWS S3 Presigned URLs** - Secure file access

---

## 🌐 API Endpoints

All endpoints follow pattern: `/api/v1/{resource}/{action}`

### Core Endpoints
| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/auth/login` | User login (email + password) |
| GET | `/auth/me` | Current user profile |
| GET | `/tasks` | List all tasks |
| GET | `/tasks/my` | User's assigned tasks |
| POST | `/submissions` | Submit work (multipart) |
| GET | `/messages/:taskId` | Task chat history |
| GET | `/analytics/leaderboard` | Performance rankings |

**Full API Reference:** `docs/API_REFERENCE.md`

---

## 🗄️ Database Models

### User
- email (unique), password, role, organizationId
- FCM token for push notifications

### Organization
- name, slug, adminId, memberLimit, subscriptionTier
- Special org: "ITH" (always active)

### Task
- title, description, assignedTo, status, priority
- dueDate, adminFiles, dependsOn, comments, history

### Submission
- taskId, employee, status (pending/approved/rejected)
- beforeFiles, afterFiles, adminFeedback, comments

### Message
- taskId, sender, text (sanitized), readBy, createdAt

---

## 🚀 Deployment

### Environment Variables
Copy `.env.example` to `.env` and configure:
```bash
# Backend
PORT=5000
MONGO_URI=mongodb://...
JWT_SECRET=your-secret-key
AWS_S3_BUCKET=bucket-name
FCM_SERVER_KEY=firebase-key

# Frontend
BACKEND_URL=https://api.example.com
```

### Production Build
```bash
# Backend
NODE_ENV=production npm run pm2:start

# Frontend
flutter build apk    # Android
flutter build ios    # iOS
flutter build web    # Web
```

---

## 📊 API Response Format

### Success Response
```json
{
  "success": true,
  "data": { "user": {...}, "token": "..." },
  "message": "Login successful"
}
```

### Error Response
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

## 🛠️ Development Workflow

### Before Writing Code
1. ✅ Read `DEVELOPMENT_RULES.md` (mandatory)
2. ✅ Check if backend endpoint exists
3. ✅ Read backend controller for exact response format
4. ✅ Check database schema
5. ✅ Match frontend to backend structure exactly

### After Making Changes
1. ✅ Test backend endpoint with curl/Postman
2. ✅ Verify frontend compiles (no errors)
3. ✅ Test functionality end-to-end
4. ✅ Delete redundant/old code
5. ✅ Update documentation if API changes

---

## 📞 Support & Resources

### Getting Help
- **Setup issues:** See `START_HERE.md`
- **API questions:** Check `docs/API_REFERENCE.md`
- **Frontend patterns:** Read `DEVELOPMENT_RULES.md`
- **Backend problems:** Check backend logs: `npm run pm2:logs`

### Testing Endpoints
```bash
# Login
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Pass123!"}'

# Get tasks
curl -H "Authorization: Bearer {token}" \
  http://localhost:5000/api/v1/tasks

# See API_TEST_GUIDE.md for more examples
```

---

## 📈 Project Status

- ✅ **Backend:** Production ready
- ✅ **Frontend:** Core features implemented
- ✅ **Database:** Multi-tenant setup complete
- ✅ **Real-time:** Socket.IO working
- ✅ **Security:** All measures implemented
- 🔄 **In Progress:** Feature enhancements

---

## 🎯 Key Files to Know

### Essential (Read before coding)
- `DEVELOPMENT_RULES.md` - Authoritative development guide
- `docs/TECHNICAL_DOCUMENTATION.md` - Architecture reference
- `docs/API_REFERENCE.md` - API endpoint listing

### Backend
- `backend/app.js` - Express app setup
- `backend/server.js` - Server entry point
- `backend/models/*.js` - Database schemas
- `backend/controllers/*.js` - Business logic

### Frontend
- `frontend/lib/main.dart` - App entry point
- `frontend/lib/data/services/api_client.dart` - HTTP client
- `frontend/lib/state/auth_provider.dart` - Authentication state
- `frontend/lib/presentation/screens/` - UI screens

---

## 📝 Development Guidelines

### API Development
- All endpoints must follow response format in `DEVELOPMENT_RULES.md`
- All requests require proper authentication (except /auth/login and /health)
- All responses must include "success" and "message" fields
- All data must be organizationId-scoped for multi-tenancy

### Frontend Development
- Use `ApiClient` for all HTTP calls
- Use Riverpod providers for state management
- Follow Flutter naming conventions (snake_case for files)
- Match backend response structures exactly
- Don't make assumptions about API structure

### Multi-Tenant Rules
- Super Admin (role: super_admin) has organizationId: null
- Org Admins/Members have organizationId set
- All queries automatically scoped by organizationId in middleware
- No data should cross organization boundaries

---

## ✨ Features

- ✅ Task assignment and tracking
- ✅ Real-time team collaboration
- ✅ Work submission and approval workflow
- ✅ Performance leaderboards
- ✅ Push notifications
- ✅ File uploads (AWS S3)
- ✅ Multi-tenant support
- ✅ Offline-first mobile app
- ✅ Role-based access control
- ✅ Task dependencies and subtasks

---

## 🔗 Related Documentation

- [Technology Stack](`.kiro/steering/tech.md`)
- [Project Structure](`.kiro/steering/structure.md`)
- [Product Overview](`.kiro/steering/product.md`)
- [Multi-Tenant Plan](MULTI_TENANT_IMPLEMENTATION_PLAN.md)

---

## 📄 License & Ownership

Task Manager - Inno Tech Hub Platform  
© 2026 All rights reserved

---

**Remember:** Always read `DEVELOPMENT_RULES.md` before implementing features!
