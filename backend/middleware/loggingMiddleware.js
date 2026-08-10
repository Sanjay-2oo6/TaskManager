// ---------------------------------------------------------------------------
// loggingMiddleware.js - Automatic API request logging
// Fix 0.11: Log all API requests with timing and context
// ---------------------------------------------------------------------------

const logger = require('../utils/logger');

/**
 * Middleware to log all API requests with response time
 */
const requestLogger = (req, res, next) => {
  const startTime = Date.now();

  // Capture the original res.json to log response
  const originalJson = res.json.bind(res);
  
  res.json = function (body) {
    // ✅ FIX: Check if headers already sent to prevent double-response
    if (res.headersSent) {
      return;
    }

    const duration = Date.now() - startTime;
    const statusCode = res.statusCode;
    
    // Extract context
    const context = logger.getRequestContext(req);
    
    try {
      // Log the request
      logger.api(req.method, req.path, statusCode, duration, context);
    } catch (e) {
      // Silently ignore logging errors
      console.warn('Logging error (non-critical):', e.message);
    }
    
    // Call original json method
    return originalJson(body);
  };

  next();
};

module.exports = { requestLogger };
