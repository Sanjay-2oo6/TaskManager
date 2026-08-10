# Technology Stack & Build System

## Backend

### Runtime & Framework
- **Node.js** (v16+) - Server runtime
- **Express.js** (v4.18+) - Web framework and routing
- **MongoDB** (v4.4+) - NoSQL document database
- **Mongoose** (v8.1+) - MongoDB ODM/ORM

### Authentication & Security
- **jsonwebtoken** (JWT) - Stateless authentication
- **bcryptjs** - Password hashing and verification
- **helmet** - Security headers middleware
- **express-rate-limit** - Rate limiting and DDoS protection
- **joi** - Schema validation and input sanitization
- **sanitize-html** - XSS protection for user content

### Real-time Communication
- **Socket.IO** (v4.8+) - WebSocket library for real-time events
- Events: task-assigned, task-updated, new-chat-message, submission-updated

### External Services & APIs
- **AWS SDK S3** (@aws-sdk/client-s3) - File uploads and storage
- **Firebase Admin SDK** - Cloud messaging for push notifications
- **node-fetch** / **axios** - HTTP requests to external APIs

### File & Data Handling
- **multer** - File upload middleware
- **form-data** - Multipart form data for S3
- **compression** - Gzip compression for response bodies

### Logging & Monitoring
- **winston** - Structured logging
- **winston-daily-rotate-file** - Log rotation
- **morgan** - HTTP request logging
- Custom monitoring middleware for security and performance tracking

### Development Tools
- **nodemon** - Auto-reload during development
- **dotenv** - Environment variable management
- **PM2** - Process manager for production (configured in ecosystem.config.js)

---

## Frontend

### Framework & Language
- **Flutter** (SDK >=3.2.0 <4.0.0) - UI framework for cross-platform mobile
- **Dart** - Programming language

### State Management
- **flutter_riverpod** (v2.5+) - Reactive state management with providers

### Local Storage & Offline Support
- **hive** & **hive_flutter** - Fast, local key-value storage for offline-first
- **shared_preferences** - Simple persistent storage for app settings
- **file_picker** - Local file selection

### Networking & Real-time
- **dio** (v5.4+) - HTTP client with interceptors and retry logic
- **socket_io_client** (v3.1+) - Socket.IO client for real-time events
- **http** - Backup HTTP library

### Firebase Integration
- **firebase_core** - Firebase initialization
- **firebase_messaging** - Push notifications (FCM)
- **flutter_local_notifications** - Local notification handling

### Connectivity & Device Info
- **connectivity_plus** - Check internet connectivity status
- **package_info_plus** - App version and package information
- **ota_update** - Over-the-air app updates

### UI/UX Utilities
- **image_picker** - Camera and gallery image selection
- **url_launcher** - Open URLs and external apps
- **intl** - Internationalization and date formatting
- **logger** - Development logging

### Code Generation
- **hive_generator** - Generate Hive adapters
- **build_runner** - Run code generation during development

---

## Development Environment

### Node.js Backend

**Start Development Server**
```bash
npm run dev
# Runs: nodemon server.js
# Auto-restarts on file changes
# Server: http://localhost:5000
```

**Start Production Server**
```bash
npm start
# Runs: node server.js
```

**Run Tests**
```bash
npm test
# Runs: node test-endpoints.js
```

**PM2 Management**
```bash
npm run pm2:start     # Start with PM2
npm run pm2:dev       # Start in development mode
npm run pm2:stop      # Stop process
npm run pm2:restart   # Restart process
npm run pm2:logs      # View logs
npm run pm2:monit     # Monitor resources
npm run pm2:status    # Check status
```

### Flutter Frontend

**Development Build & Run**
```bash
flutter pub get              # Install dependencies
flutter run                  # Run on emulator/device
flutter run -d chrome        # Run in Chrome (web)
```

**Code Generation**
```bash
dart run build_runner build              # Generate Hive adapters and code
dart run build_runner watch              # Watch mode for development
dart run build_runner clean              # Clean generated files
```

**Build for Production**
```bash
flutter build apk              # Android APK
flutter build ios              # iOS app
flutter build web              # Web version
```

---

## Configuration Management

### Environment Variables (Backend `.env`)

**Core Server**
- `PORT` - Server port (default: 5000)
- `NODE_ENV` - `development` or `production`
- `FRONTEND_URL` - Frontend domain for CORS

**Database**
- `MONGO_URI` - MongoDB connection string

**Authentication**
- `JWT_SECRET` - Secret key for JWT signing
- `JWT_EXPIRES_IN` - Token expiration (default: 7d)

**AWS S3**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_S3_BUCKET`

**Firebase**
- `FCM_SERVER_KEY` - Server key for push notifications

**Admin**
- `MASTER_ADMIN_USERNAME` - Super admin username

### Environment Variables (Frontend `.env`)

**API Configuration**
- `BACKEND_URL` - Backend API base URL
- `API_VERSION` - API version (default: v1)

**Firebase**
- `FIREBASE_PROJECT_ID`
- `FIREBASE_API_KEY`
- (Platform-specific keys in google-services.json and GoogleService-Info.plist)

---

## Code Organization Standards

### Backend Patterns
- **Controllers** - Request handlers, delegate to services/models
- **Models** - Mongoose schemas defining data structure
- **Routes** - Express route definitions with middleware
- **Middleware** - Cross-cutting concerns (auth, validation, logging)
- **Services** - External integrations (S3, FCM)
- **Utils** - Helper functions and shared utilities
- **Jobs** - Cron jobs and scheduled tasks

### Frontend Structure (Flutter)
- **lib/screens** - Full-page UI screens
- **lib/widgets** - Reusable UI components
- **lib/providers** - Riverpod state management
- **lib/services** - API and external service integrations
- **lib/models** - Data models with Hive adapters
- **lib/utils** - Helper functions and constants

---

## Database Schema

**Collections with Organization Prefix** (multi-tenant pattern):
- `organizations` - Org metadata (super admin only)
- `users_{org}` - Users in organization
- `tasks_{org}` - Tasks and assignments
- `messages_{org}` - Chat/discussion messages
- `submissions_{org}` - Work submissions and reviews

**Special Organization:** `ith` (parent organization with full system access)

---

## API Versioning

- **Base URL:** `/api/v1`
- **Health Check:** `GET /health`
- **Routes:** All API routes prefixed with `/api/v1/`
  - `/api/v1/auth` - Authentication
  - `/api/v1/tasks` - Task management
  - `/api/v1/submissions` - Submission tracking
  - `/api/v1/messages` - Real-time messaging
  - `/api/v1/analytics` - Reporting and stats
  - `/api/v1/super-admin` - Multi-tenant administration

---

## Security Conventions

- **Password Hashing** - bcryptjs with salt rounds
- **Input Validation** - Joi schemas enforced on all endpoints
- **CORS** - Environment-specific (strict in production, open in dev)
- **Rate Limiting** - 100 requests per 15 minutes per IP
- **JWT Tokens** - Bearer token in Authorization header
- **File Uploads** - Size limit 2MB per request
- **SQL Injection** - Not applicable (MongoDB), but injection via NoSQL still prevented
- **XSS Protection** - HTML sanitization on user content
- **HTTPS** - Enforced in production via proxy

---

## Performance Considerations

- **Response Compression** - Gzip enabled (threshold: 1KB)
- **Body Size Limit** - 2MB to prevent abuse
- **Database Indexes** - Defined in `utils/databaseIndexes.js`
- **Caching** - APICache for read-heavy endpoints
- **Real-time Events** - Namespace-based Socket.IO rooms to limit message scope
- **Monitoring** - Performance middleware tracks response times and detects anomalies
