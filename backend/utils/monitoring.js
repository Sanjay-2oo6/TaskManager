const logger = require('./logger');

/**
 * MONITORING & ALERTS - Detection & Response
 * 
 * Purpose: Track application metrics and alert when something is wrong
 * - Failed logins (potential brute force)
 * - Slow response times (performance degradation)
 * - Error spikes (something broken)
 * - Unusual access patterns (potential attack)
 * 
 * Why? Can't defend against attacks you don't know are happening!
 * Examples:
 * - 100 failed logins in 1 hour? → Brute force attack detected!
 * - Sudden spike in 500 errors? → Something crashed!
 * - User downloading 100MB in seconds? → Data exfiltration attempt!
 * 
 * Solution: Track metrics, set thresholds, alert when exceeded
 */

class MetricsTracker {
  constructor() {
    this.metrics = {
      failedLogins: {},        // { userId: count }
      apiErrors: {},           // { endpoint: count }
      slowRequests: {},        // { endpoint: count }
      dataTransfer: {},        // { userId: bytes }
      unauthorizedAttempts: {} // { userId: count }
    };
    
    // Clear metrics every hour
    setInterval(() => this.resetMetrics(), 60 * 60 * 1000);
  }

  /**
   * Track failed login attempt
   * Alert if user exceeds threshold
   */
  trackFailedLogin(username) {
    if (!this.metrics.failedLogins[username]) {
      this.metrics.failedLogins[username] = 0;
    }
    this.metrics.failedLogins[username]++;

    // Alert if more than 10 failed logins in an hour
    if (this.metrics.failedLogins[username] > 10) {
      logger.security('⚠️ ALERT: Potential brute force attack detected', {
        username,
        failedAttempts: this.metrics.failedLogins[username],
        action: 'Consider blocking this user temporarily'
      });
    }
  }

  /**
   * Track API errors by endpoint
   * Alert if error rate is too high
   */
  trackApiError(endpoint, statusCode) {
    const key = `${endpoint}-${statusCode}`;
    if (!this.metrics.apiErrors[key]) {
      this.metrics.apiErrors[key] = 0;
    }
    this.metrics.apiErrors[key]++;

    // Alert if more than 20 errors from same endpoint in an hour
    if (this.metrics.apiErrors[key] > 20) {
      logger.error('⚠️ ALERT: High error rate detected', {
        endpoint,
        statusCode,
        errorCount: this.metrics.apiErrors[key],
        action: 'Check server logs and fix the issue'
      });
    }
  }

  /**
   * Track slow requests
   * Alert if request takes too long
   */
  trackSlowRequest(endpoint, responseTime) {
    // Alert if request takes more than 5 seconds
    if (responseTime > 5000) {
      if (!this.metrics.slowRequests[endpoint]) {
        this.metrics.slowRequests[endpoint] = 0;
      }
      this.metrics.slowRequests[endpoint]++;

      logger.warn('⚠️ ALERT: Slow request detected', {
        endpoint,
        responseTime: `${responseTime}ms`,
        action: 'Check database queries and optimize'
      });
    }
  }

  /**
   * Track data transfer by user
   * Alert if user downloads suspiciously large amount
   */
  trackDataTransfer(userId, bytes) {
    if (!this.metrics.dataTransfer[userId]) {
      this.metrics.dataTransfer[userId] = 0;
    }
    this.metrics.dataTransfer[userId] += bytes;

    // Alert if user transfers more than 500MB in an hour
    if (this.metrics.dataTransfer[userId] > 500 * 1024 * 1024) {
      logger.security('⚠️ ALERT: Suspicious data transfer detected', {
        userId,
        transferredBytes: this.metrics.dataTransfer[userId],
        transferredMB: Math.round(this.metrics.dataTransfer[userId] / (1024 * 1024)),
        action: 'Possible data exfiltration attempt'
      });
    }
  }

  /**
   * Track unauthorized access attempts
   * Alert if user repeatedly tries accessing resources they shouldn't
   */
  trackUnauthorizedAttempt(userId, resource) {
    if (!this.metrics.unauthorizedAttempts[userId]) {
      this.metrics.unauthorizedAttempts[userId] = 0;
    }
    this.metrics.unauthorizedAttempts[userId]++;

    // Alert if more than 5 unauthorized attempts in an hour
    if (this.metrics.unauthorizedAttempts[userId] > 5) {
      logger.security('⚠️ ALERT: Repeated unauthorized access attempts', {
        userId,
        resource,
        attemptCount: this.metrics.unauthorizedAttempts[userId],
        action: 'User may be trying to access unauthorized resources'
      });
    }
  }

  /**
   * Get current metrics (for admin dashboard)
   */
  getMetrics() {
    return {
      failedLogins: this.metrics.failedLogins,
      apiErrors: this.metrics.apiErrors,
      slowRequests: this.metrics.slowRequests,
      dataTransfer: this.metrics.dataTransfer,
      unauthorizedAttempts: this.metrics.unauthorizedAttempts,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Reset metrics every hour
   */
  resetMetrics() {
    logger.info('📊 Hourly metrics reset');
    this.metrics = {
      failedLogins: {},
      apiErrors: {},
      slowRequests: {},
      dataTransfer: {},
      unauthorizedAttempts: {}
    };
  }

  /**
   * Get system health status
   */
  getHealthStatus() {
    const failedLoginCount = Object.values(this.metrics.failedLogins)
      .reduce((sum, count) => sum + count, 0);
    
    const errorCount = Object.values(this.metrics.apiErrors)
      .reduce((sum, count) => sum + count, 0);

    const slowRequestCount = Object.values(this.metrics.slowRequests)
      .reduce((sum, count) => sum + count, 0);

    return {
      status: this.getOverallStatus(failedLoginCount, errorCount, slowRequestCount),
      failedLoginCount,
      errorCount,
      slowRequestCount,
      alerts: this.getActiveAlerts()
    };
  }

  /**
   * Determine overall status based on metrics
   */
  getOverallStatus(failedLogins, errors, slowRequests) {
    if (failedLogins > 20 || errors > 50) {
      return 'critical'; // Active attack or serious issue
    }
    if (failedLogins > 10 || errors > 20 || slowRequests > 5) {
      return 'warning'; // Potential issue
    }
    return 'healthy';
  }

  /**
   * Get list of active alerts
   */
  getActiveAlerts() {
    const alerts = [];
    
    const failedLoginCount = Object.values(this.metrics.failedLogins)
      .reduce((sum, count) => sum + count, 0);
    
    if (failedLoginCount > 10) {
      alerts.push({
        type: 'brute_force_attempts',
        severity: 'high',
        message: `${failedLoginCount} failed login attempts detected`
      });
    }

    const errorCount = Object.values(this.metrics.apiErrors)
      .reduce((sum, count) => sum + count, 0);
    
    if (errorCount > 20) {
      alerts.push({
        type: 'high_error_rate',
        severity: 'high',
        message: `${errorCount} API errors detected in the last hour`
      });
    }

    const slowRequestCount = Object.values(this.metrics.slowRequests)
      .reduce((sum, count) => sum + count, 0);
    
    if (slowRequestCount > 5) {
      alerts.push({
        type: 'performance_degradation',
        severity: 'medium',
        message: `${slowRequestCount} slow requests detected`
      });
    }

    return alerts;
  }
}

// Singleton instance
const metricsTracker = new MetricsTracker();

module.exports = metricsTracker;
