const logger = require('./logger');

/**
 * ERROR RESPONSE HANDLER - Security & Privacy
 * 
 * Purpose: Hide sensitive error details from users
 * - Development: Show detailed errors (file path, line number, database name)
 * - Production: Show generic errors (never reveal internals)
 * 
 * Why? Error messages leak system information:
 * - "Cannot find /opt/server/controllers/userController.js" tells attacker project structure
 * - "MongoError: users.username already exists" tells attacker database schema
 * - "SQL syntax error at line 42" tells attacker how to exploit SQL injection
 * 
 * Solution: Log detailed errors internally, return generic messages to users
 */

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
  }
}

/**
 * Sanitize error response based on environment
 * Development: Return full details for debugging
 * Production: Return generic message only
 */
const sanitizeErrorResponse = (error, environment = 'development') => {
  // Log full error internally
  if (environment === 'production') {
    logger.error('Internal Server Error:', {
      message: error.message,
      stack: error.stack,
      code: error.code,
      type: error.constructor.name
    });
  }

  // Return to client
  if (environment === 'production') {
    // Production: Generic message
    return {
      statusCode: error.statusCode || 500,
      message: getPublicMessage(error.statusCode || 500),
      // Never include: error.message, error.stack, error.path, error.details
    };
  } else {
    // Development: Detailed message for debugging
    return {
      statusCode: error.statusCode || 500,
      message: error.message,
      error: error.stack // Only in development
    };
  }
};

/**
 * Get user-friendly error message
 * Generic messages don't reveal system internals
 */
const getPublicMessage = (statusCode) => {
  const messages = {
    400: 'Invalid request. Please check your input.',
    401: 'You are not authenticated. Please log in.',
    403: 'You do not have permission to access this resource.',
    404: 'The requested resource was not found.',
    409: 'Conflict. This resource already exists.',
    429: 'Too many requests. Please try again later.',
    500: 'Server error. Please try again later.',
    503: 'Service temporarily unavailable. Please try again later.'
  };
  return messages[statusCode] || 'An error occurred. Please try again later.';
};

/**
 * Express error handling middleware
 * Use: app.use(errorHandler);
 */
const errorHandler = (err, req, res, next) => {
  const environment = process.env.NODE_ENV || 'development';
  const statusCode = err.statusCode || 500;

  // Log error for investigation
  logger.error('Unhandled error:', {
    message: err.message,
    path: req.path,
    method: req.method,
    userId: req.user?.id || 'anonymous',
    ip: req.ip,
    timestamp: new Date().toISOString()
  });

  // Send response
  const response = sanitizeErrorResponse(err, environment);
  res.status(statusCode).json({
    success: false,
    message: response.message,
    ...(environment === 'development' && { error: response.error })
  });
};

/**
 * Async route wrapper to catch errors
 * Usage: router.get('/route', asyncHandler(async (req, res) => { ... }))
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch((err) => {
    // Convert to AppError if needed
    const appError = err instanceof AppError 
      ? err 
      : new AppError(
          err.message || 'Internal server error',
          err.statusCode || 500
        );
    next(appError);
  });
};

/**
 * Common error helper functions
 */
const createError = {
  badRequest: (message = 'Bad request') => 
    new AppError(message, 400),

  unauthorized: (message = 'Unauthorized') => 
    new AppError(message, 401),

  forbidden: (message = 'Forbidden') => 
    new AppError(message, 403),

  notFound: (message = 'Not found') => 
    new AppError(message, 404),

  conflict: (message = 'Conflict') => 
    new AppError(message, 409),

  tooManyRequests: (message = 'Too many requests') => 
    new AppError(message, 429),

  internalError: (message = 'Internal server error') => 
    new AppError(message, 500)
};

module.exports = {
  AppError,
  sanitizeErrorResponse,
  getPublicMessage,
  errorHandler,
  asyncHandler,
  createError
};
