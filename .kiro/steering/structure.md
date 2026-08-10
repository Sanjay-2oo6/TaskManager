# Project Structure & Organization

## Directory Layout

```
Taskmanager/
├── backend/                          # Node.js/Express API server
│   ├── config/                       # Configuration modules
│   │   ├── db.js                    # MongoDB connection
│   │   ├── s3.js                    # AWS S3 client
│   │   └── version.json             # API version info
│   │
│   ├── controllers/                  # Route handlers (business logic)
│   │   ├── authController.js        # Login, user management
│   │   ├── taskController.js        # Task CRUD and operations
│   │   ├── submissionController.js  # Submission review workflow
│   │   ├── messageController.js     # Chat messages
│   │   ├── analyticsController.js   # Leaderboards and stats
│   │   ├── appController.js         # App metadata (version)
│   │   └── superAdminController.js  # Multi-tenant management
│   │
│   ├── middleware/                   # Express middleware
│   │   ├── authMiddleware.js        # JWT verification
│   │   ├── roleMiddleware.js        # Role-based access control
│   │   ├── validationMiddleware.js  # Input validation (Joi)
│   │   ├── organizationMiddleware.js# Multi-tenant context
│   │   ├── securityHeadersMiddleware.js  # Security headers
│   │   ├── rateLimitMiddleware.js   # Rate limiting
│   │   ├── loggingMiddleware.js     # Request logging
│   │   ├── monitoringMiddleware.js  # Performance monitoring
│   │   └── cache.js                 # Response caching
│   │
│   ├── models/                       # Mongoose schemas
│   │   ├── User.js                  # User model with role
│   │   ├── Organization.js          # Organization metadata
│   │   ├── Task.js                  # Task with assignments
│   │   ├── Submission.js            # Work submission
│   │   └── Message.js               # Task discussion messages
│   │
│   ├── routes/                       # API route definitions
│   │   ├── authRoutes.js            # /api/v1/auth
│   │   ├── taskRoutes.js            # /api/v1/tasks
│   │   ├── submissionRoutes.js      # /api/v1/submissions
│   │   ├── messageRoutes.js         # /api/v1/messages
│   │   ├── analyticsRoutes.js       # /api/v1/analytics
│   │   ├── appRoutes.js             # /api/v1/app
│   │   ├── superAdminRoutes.js      # /api/v1/super-admin (multi-tenant)
│   │   └── performanceRoutes.js     # /api/v1/performance (monitoring)
│   │
│   ├── services/                     # External service integrations
│   │   ├── s3Service.js             # AWS S3 upload/download
│   │   └── notificationService.js   # Firebase FCM push notifications
│   │
│   ├── utils/                        # Helper utilities
│   │   ├── logger.js                # Winston structured logging
│   │   ├── errorHandler.js          # Global error middleware
│   │   ├── helpers.js               # Common helper functions
│   │   ├── databaseIndexes.js       # MongoDB index definitions
│   │   └── validateEnv.js           # Environment validation
│   │
│   ├── jobs/                         # Scheduled tasks
│   │   └── overdueTaskJob.js        # Cron job for overdue notifications
│   │
│   ├── scripts/                      # Database and utility scripts
│   │   ├── create-test-accounts.js  # Seed test users
│   │   ├── full-reset-db.js         # Full database reset
│   │   ├── clean-database.js        # Database cleanup
│   │   ├── set-super-admin.js       # Set super admin role
│   │   ├── reset-super-admin-password.js
│   │   └── archived/                # Legacy migration scripts
│   │       ├── migrate-roles.js     # Role system migration (legacy)
│   │       ├── migrate-to-multitenant.js # Multi-tenant migration (legacy)
│   │       └── migrate-username-to-email.js # Username to email (legacy)
│   │
│   ├── logs/                         # Application logs (git-ignored)
│   │   ├── combined-*.log           # All logs
│   │   ├── error-*.log              # Error logs only
│   │   ├── security-*.log           # Security events
│   │   └── pm2-*.log                # PM2 process logs
│   │
│   ├── node_modules/                 # Dependencies (git-ignored)
│   ├── test-*.js                    # Ad-hoc test scripts
│   ├── app.js                       # Express app setup
│   ├── server.js                    # Server entry point
│   ├── ecosystem.config.js          # PM2 configuration
│   ├── package.json                 # Dependencies and scripts
│   ├── package-lock.json            # Lock file
│   ├── .env                         # Environment variables (git-ignored)
│   ├── .env.example                 # Environment template
│   ├── .gitignore
│   ├── README.md
│   └── API_TEST_GUIDE.md            # Testing endpoints guide
│
├── frontend/                         # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart                # App entry point
│   │   │
│   │   ├── screens/                 # Full-page UI screens
│   │   │   ├── login_screen.dart
│   │   │   ├── task_list_screen.dart
│   │   │   ├── task_detail_screen.dart
│   │   │   ├── submission_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   └── [other screens]
│   │   │
│   │   ├── widgets/                 # Reusable UI components
│   │   │   ├── task_card.dart
│   │   │   ├── submission_item.dart
│   │   │   ├── message_bubble.dart
│   │   │   └── [other widgets]
│   │   │
│   │   ├── providers/               # Riverpod state management
│   │   │   ├── auth_provider.dart   # Authentication state
│   │   │   ├── task_provider.dart   # Task state
│   │   │   ├── submission_provider.dart
│   │   │   └── [other providers]
│   │   │
│   │   ├── services/                # API and external integrations
│   │   │   ├── api_service.dart     # REST API client (Dio)
│   │   │   ├── socket_service.dart  # Socket.IO real-time
│   │   │   ├── storage_service.dart # Local Hive storage
│   │   │   ├── notification_service.dart # FCM handling
│   │   │   └── file_service.dart    # File upload/download
│   │   │
│   │   ├── models/                  # Data models (Hive-compatible)
│   │   │   ├── user_model.dart
│   │   │   ├── task_model.dart
│   │   │   ├── submission_model.dart
│   │   │   └── [other models]
│   │   │
│   │   └── utils/                   # Helper functions
│   │       ├── constants.dart       # App constants and routes
│   │       ├── formatters.dart      # Date/time formatters
│   │       └── validators.dart      # Input validation
│   │
│   ├── .env                         # Flutter environment config
│   ├── pubspec.yaml                 # Dependencies and Flutter config
│   ├── pubspec.lock                 # Dependency lock file
│   ├── .gitignore
│   ├── README.md
│   └── [platform-specific: ios/, android/, web/]
│
├── docs/                             # Project documentation
│   ├── API_REFERENCE.md             # Complete API endpoint docs
│   ├── USER_GUIDE.md                # End-user manual
│   ├── TECHNICAL_DOCUMENTATION.md   # Architecture and design
│   ├── ROLES_AND_PERMISSIONS.md     # Permission matrix
│   ├── ROADMAP.md                   # Feature roadmap
│   └── QUICK_REFERENCE.md           # Quick lookup guide
│
├── .kiro/                            # Kiro AI configuration
│   └── steering/                     # AI guidance documents
│       ├── product.md               # Product overview
│       ├── tech.md                  # Tech stack and build system
│       └── structure.md             # This file
│
├── MULTI_TENANT_IMPLEMENTATION_PLAN.md    # Multi-tenant strategy
├── PHASE_*.md                              # Phase completion documents
├── IMPLEMENTATION_CHECKLIST.md             # Feature checklist
├── SESSION_CLEANUP_COMPLETE.md             # Session history
├── .gitignore                              # Git ignore patterns
└── README.md                               # Root project readme

```

---

## Key Organization Principles

### Backend Organization

**By Feature/Domain**
- Authentication & authorization
- Task management
- Submission workflow
- Messaging
- Analytics
- Multi-tenant administration

**By Layer**
- Controllers → Business logic (orchestration)
- Models → Data schemas
- Middleware → Cross-cutting concerns
- Services → External integrations
- Utils → Shared helpers

**Naming Conventions**
- Controllers: `{domain}Controller.js` (e.g., `taskController.js`)
- Models: PascalCase (e.g., `Task.js`, `User.js`)
- Routes: `{domain}Routes.js`
- Middleware: `{purpose}Middleware.js`
- Services: `{service}Service.js`

### Frontend Organization

**By Feature**
- Screens group related pages (task list, task detail, submissions, etc.)
- Widgets contain reusable UI components
- Providers manage state per feature

**By Layer**
- Services → API communication and local storage
- Providers → State management (Riverpod)
- Models → Data models with serialization
- Utils → Constants, formatters, validators

**Naming Conventions**
- Screens: `{page}_screen.dart` (e.g., `task_list_screen.dart`)
- Widgets: `{component}.dart` (e.g., `task_card.dart`)
- Providers: `{feature}_provider.dart`
- Models: `{entity}_model.dart`

---

## Multi-Tenant Collection Pattern

Collections follow organization-scoped naming to enable multi-tenancy:

**Organizations**
```
organizations
└── _id, name, slug, admin_username, is_active, is_system
```

**Per-Organization Collections**
```
users_ith              (ITH organization - always active)
tasks_ith
messages_ith
submissions_ith

users_companyA         (Client A)
tasks_companyA
messages_companyA
submissions_companyA

users_companyB         (Client B)
tasks_companyB
messages_companyB
submissions_companyB
```

**Organization Context**
- Extracted from JWT token claims
- Used in middleware to scope queries
- Passed to all database operations

---

## Development vs. Production Paths

### Backend Execution

**Development**
- Entry: `npm run dev` → nodemon watches `server.js`
- Logging: Morgan + Winston in verbose mode
- CORS: Open to all origins
- Rate Limiting: Relaxed for testing

**Production**
- Entry: `npm run pm2:start` → PM2 manages process
- Logging: Winston to daily-rotated files
- CORS: Strict (whitelist only approved origins)
- Rate Limiting: Enforced (100 req/15min per IP)
- Environment: `NODE_ENV=production`

### Frontend Execution

**Development**
- `flutter run` - Hot reload on file changes
- Logging: Debug console output
- API: Points to development backend (configurable `.env`)

**Production**
- `flutter build apk` / `flutter build ios` - Optimized builds
- Logging: Minimal, errors only
- API: Points to production backend URL

---

## Important Directories

### To Modify When Adding Features
1. **New API endpoint** → Route file + Controller
2. **New data type** → Model + Migration script
3. **New business logic** → Service or middleware
4. **New UI screen** → Screen + related widgets/providers
5. **New state** → Provider in Riverpod

### Do Not Modify Without Reason
- `/node_modules` - Regenerate via `npm install`
- `/logs` - Application generated
- `.env` - Use `.env.example` as template

### Keep Up-to-Date
- `docs/` - Update when API changes
- `.kiro/steering/` - Update when tech/process changes
- Root README files - Quarterly review

---

## File Naming Standards

### Backend
- JavaScript files: `camelCase.js` or `kebab-case.js` (consistent within folder)
- Controllers: Always PascalCase models in imports
- No spaces in filenames
- Database scripts: Start with purpose (e.g., `migrate-`, `reset-`, `create-`)

### Frontend (Dart)
- All files: `snake_case.dart`
- Classes: PascalCase (in file)
- Variables/functions: camelCase
- Constants: CONSTANT_CASE

### Documentation
- Markdown files: `SCREAMING_SNAKE_CASE.md` (docs) or descriptive-kebab-case.md
- Phase documents: `PHASE_*.md` with phase letter/number

---

## Git Ignore Strategy

**Backend Ignores**
- `node_modules/` - Reinstall via npm
- `.env` - Environment secrets
- `logs/` - Application generated
- `*.log` - Log files
- `.DS_Store` - macOS files

**Frontend Ignores**
- `build/` - Generated builds
- `.dart_tool/` - Dart cache
- `.fvm/` - Flutter Version Manager
- `.env` - Local configuration

**Root Ignores**
- `.DS_Store`
- System files
- IDE-specific files (`.vscode`, `.idea`)

---

## Testing & Validation

### Backend Test Files (Development Only)
Located in `backend/` root:
- `test-endpoints.js` - Main test suite
- `test-*.js` - Ad-hoc test scripts
- Used for manual validation before deployment
- Not part of CI/CD pipeline yet

### Frontend Testing
- Unit tests: `test/` directory
- Widget tests: Alongside widget files
- Run with: `flutter test`

---

## Environment-Specific Configuration

### `.env.example` Template
Located in `backend/.env.example` - provides all required variables with placeholder values.

### Configuration Hierarchy
1. `.env` file (highest priority, local machine)
2. PM2 `ecosystem.config.js` (environment-specific via `--env` flag)
3. Defaults in code (lowest priority)

### Sensitive Files (Never in Git)
- `.env` (local environment variables)
- Database backups
- SSL certificates
- API keys and secrets
