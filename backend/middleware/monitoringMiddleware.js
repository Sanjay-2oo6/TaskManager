const metricsTracker = require('../utils/monitoring');
const logger = require('../utils/logger');

/**
 * MONITORING MIDDLEWARE - Track API performance and attacks
 * 
 * Tracks:
 * - Response times (slow requests)
 * - Error rates (endpoint failures)
 * - Data transfer (possible exfiltration)
 * - Unauthorized attempts (access violations)
 */

const monitoringMiddleware = (req, res, next) => {
  const startTime = Date.now();

  // Override res.json to track response status
  const originalJson = res.json.bind(res);
  res.json = function(data) {
    // ✅ FIX: Check if headers already sent to prevent double-response
    if (res.headersSent) {
      return;
    }

    const responseTime = Date.now() - startTime;
    const statusCode = res.statusCode;
    const endpoint = `${req.method} ${req.baseUrl}${req.path}`;

    try {
      // Track slow requests (> 5 seconds)
      if (responseTime > 5000) {
        metricsTracker.trackSlowRequest(endpoint, responseTime);
      }

      // Track API errors
      if (statusCode >= 400) {
        metricsTracker.trackApiError(endpoint, statusCode);
      }

      // Track unauthorized attempts (403)
      if (statusCode === 403 && req.user) {
        metricsTracker.trackUnauthorizedAttempt(req.user.id, req.path);
      }

      // Log endpoint metrics (every 100 requests or if slow)
      if (responseTime > 1000) {
        logger.info('⏱️ Slow endpoint detected', {
          endpoint,
          method: req.method,
          statusCode,
          responseTime: `${responseTime}ms`,
          userId: req.user?.id || 'anonymous',
          ip: req.ip
        });
      }

      // Track data transfer
      if (req.user && res.get('Content-Length')) {
        const contentLength = parseInt(res.get('Content-Length'), 10);
        if (!isNaN(contentLength)) {
          metricsTracker.trackDataTransfer(req.user.id, contentLength);
        }
      }
    } catch (e) {
      // Silently ignore tracking errors
      console.warn('Monitoring tracking error (non-critical):', e.message);
    }

    return originalJson(data);
  };

  next();
};

/**
 * Health status endpoint middleware
 * Usage: app.get('/health/metrics', healthStatusMiddleware, (req, res) => { ... })
 * Returns current system health and alerts
 */
const healthStatusMiddleware = (req, res, next) => {
  const health = metricsTracker.getHealthStatus();
  
  // Only admins can view health status
  if (req.user?.role !== 'admin') {
    logger.security('Unauthorized access to health metrics', {
      userId: req.user?.id,
      role: req.user?.role,
      ip: req.ip
    });
    return res.status(403).json({
      success: false,
      message: 'Admin access required'
    });
  }

  res.status(200).json({
    success: true,
    health
  });
};

module.exports = {
  monitoringMiddleware,
  healthStatusMiddleware
};
