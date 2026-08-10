const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// 🛡️ SECURITY FIX 0.13: Validate required environment variables before starting
const { validateEnvironmentVariables } = require('./utils/validateEnv');
validateEnvironmentVariables();

// 🛡️ SECURITY FIX 0.18: Error handling middleware
const { errorHandler } = require('./utils/errorHandler');

// 🛡️ SECURITY FIX 0.17: Monitoring middleware for attacks/performance
const { monitoringMiddleware } = require('./middleware/monitoringMiddleware');

const submissionRoutes = require('./routes/submissionRoutes');
const authRoutes = require('./routes/authRoutes');
const taskRoutes = require('./routes/taskRoutes');  // ✅ BACK TO ORIGINAL
const analyticsRoutes = require('./routes/analyticsRoutes');
const messageRoutes = require('./routes/messageRoutes');
const appRoutes = require('./routes/appRoutes');
const { apiLimiter } = require('./middleware/rateLimitMiddleware');
const { requestLogger } = require('./middleware/loggingMiddleware');
const { securityHeaders } = require('./middleware/securityHeadersMiddleware');
const logger = require('./utils/logger');

const app = express();

// ✅ Add Request ID for tracing
app.use((req, res, next) => {
  const { v4: uuid } = require('uuid');
  req.id = uuid();
  res.setHeader('X-Request-ID', req.id);
  next();
});

// --- Global Middleware ---
app.use(helmet());

// ✅ PERFORMANCE: Gzip compression with optimized settings
app.use(compression({
  // Compression level (0-9): 6 is good balance between speed and size
  level: 6,
  
  // Only compress responses larger than 1KB
  threshold: 1024,
  
  // Filter what to compress
  filter: (req, res) => {
    // Don't compress if client doesn't accept encoding
    if (req.headers['x-no-compression']) {
      return false;
    }
    // Use compression's default filter
    return compression.filter(req, res);
  },
}));

// 🛡️ SECURITY FIX 0.13: Environment-specific CORS configuration
if (process.env.NODE_ENV === 'production') {
  // Production: Strict CORS - only allow our domain
  const allowedOrigins = [
    process.env.FRONTEND_URL || 'https://yourdomain.com',
  ];
  
  app.use(cors({
    origin: function(origin, callback) {
      // Allow requests with no origin (like mobile apps)
      if (!origin) return callback(null, true);
      
      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        logger.security('CORS rejected request', { 
          origin,
          path: '/api',
          reason: 'Origin not in whitelist'
        });
        callback(new Error('CORS not allowed'));
      }
    },
    credentials: true
  }));
} else {
  // Development: Allow all origins for easy testing
  app.use(cors());
  logger.info('CORS: Development mode - all origins allowed');
}

// 🛡️ SECURITY FIX 0.13: Add security headers based on environment
app.use(securityHeaders);

// 🛡️ SECURITY FIX 0.11: Structured logging for all API requests
app.use(requestLogger);

// 🛡️ SECURITY FIX 0.17: Monitor requests for performance and attacks
app.use(monitoringMiddleware);

// Only log requests in development — morgan adds latency in production
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}
// PERF: Limit body size to prevent abuse and reduce parsing overhead
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: false, limit: '2mb' }));

// ✅ SECURITY: Apply general rate limiting to all API routes
app.use('/api/', apiLimiter);

// --- API Routes ---
const performanceRoutes = require('./routes/performanceRoutes');
const superAdminRoutes = require('./routes/superAdminRoutes');

// ✅ Add API version headers to all responses
app.use('/api/', (req, res, next) => {
  res.setHeader('API-Version', 'v1');
  res.setHeader('X-API-Version', '1.3.0');
  next();
});

app.use('/api/v1/performance', performanceRoutes); // ✅ PERFORMANCE: Monitoring endpoints
app.use('/api/v1/super-admin', superAdminRoutes); // ✅ MULTI-TENANT: Super admin endpoints
app.use('/api/v1/submissions', submissionRoutes);
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/v1/messages', messageRoutes);
app.use('/api/v1/app', appRoutes);
// Direct legacy fallback for older app versions still looking for this exact path
app.get('/v1/app/version', require('./controllers/appController').getLatestVersion);
app.use('/v1/app', appRoutes); // Catch-all bridge for other potential v1 paths

// --- Health Check ---
app.get('/health', (req, res) => {
  res.status(200).json({ success: true, message: 'Server is healthy.' });
});

// --- 404 Handler ---
app.use('*', (req, res) => {
  res.status(404).json({ success: false, message: 'Route not found.' });
});

// 🛡️ SECURITY FIX 0.18: Error handling middleware (must be last)
app.use(errorHandler);

module.exports = app;
