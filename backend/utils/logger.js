// ---------------------------------------------------------------------------
// logger.js - Structured logging with Winston
// Fix 0.11: Centralized logging for security events, errors, and audit trail
// ---------------------------------------------------------------------------

const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const path = require('path');

// Determine log level based on environment
const logLevel = process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug');

// Custom format for readable logs
const customFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let log = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    
    // Add metadata if present
    if (Object.keys(meta).length > 0) {
      // Remove empty or undefined fields
      const cleanMeta = Object.fromEntries(
        Object.entries(meta).filter(([_, v]) => v != null && v !== '')
      );
      if (Object.keys(cleanMeta).length > 0) {
        log += ` ${JSON.stringify(cleanMeta)}`;
      }
    }
    
    return log;
  })
);

// Daily rotating file for all logs
const combinedFileTransport = new DailyRotateFile({
  filename: path.join(__dirname, '../logs/combined-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '14d', // Keep logs for 14 days
  level: 'debug'
});

// Daily rotating file for errors only
const errorFileTransport = new DailyRotateFile({
  filename: path.join(__dirname, '../logs/error-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '30d', // Keep error logs for 30 days
  level: 'error'
});

// Daily rotating file for security events
const securityFileTransport = new DailyRotateFile({
  filename: path.join(__dirname, '../logs/security-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '90d', // Keep security logs for 90 days (compliance)
  level: 'warn'
});

// Create the logger
const logger = winston.createLogger({
  level: logLevel,
  format: customFormat,
  transports: [
    combinedFileTransport,
    errorFileTransport,
    securityFileTransport
  ],
  // Don't exit on uncaught exceptions
  exitOnError: false
});

// Console transport for development (colored output)
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      customFormat
    )
  }));
}

// ─── Specialized Logging Functions ────────────────────────────────────────

/**
 * Log security events (unauthorized access, suspicious activity)
 */
logger.security = (message, context = {}) => {
  logger.warn(message, {
    ...context,
    type: 'SECURITY_EVENT'
  });
};

/**
 * Log authentication events (login, logout, password change)
 */
logger.auth = (message, context = {}) => {
  logger.info(message, {
    ...context,
    type: 'AUTH_EVENT'
  });
};

/**
 * Log admin actions (user creation, task deletion, etc.)
 */
logger.admin = (message, context = {}) => {
  logger.info(message, {
    ...context,
    type: 'ADMIN_ACTION'
  });
};

/**
 * Log API requests with timing
 */
logger.api = (method, path, statusCode, duration, context = {}) => {
  const level = statusCode >= 500 ? 'error' : statusCode >= 400 ? 'warn' : 'info';
  logger[level](`${method} ${path} ${statusCode}`, {
    ...context,
    duration: `${duration}ms`,
    type: 'API_REQUEST'
  });
};

/**
 * Log database operations
 */
logger.db = (operation, collection, context = {}) => {
  logger.debug(`Database ${operation} on ${collection}`, {
    ...context,
    type: 'DB_OPERATION'
  });
};

// ─── Helper to Extract Request Context ─────────────────────────────────────

/**
 * Extract useful context from Express request object
 * @param {Object} req - Express request object
 * @returns {Object} Context object with user, IP, etc.
 */
logger.getRequestContext = (req) => {
  return {
    userId: req.user?.id,
    userRole: req.user?.role,
    username: req.user?.username,
    ip: req.ip || req.connection?.remoteAddress,
    userAgent: req.get('user-agent'),
    method: req.method,
    path: req.path
  };
};

// ─── Startup Message ───────────────────────────────────────────────────────

logger.info('Logger initialized', {
  level: logLevel,
  environment: process.env.NODE_ENV || 'development',
  logDirectory: path.join(__dirname, '../logs')
});

module.exports = logger;
