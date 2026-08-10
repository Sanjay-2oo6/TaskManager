const rateLimit = require('express-rate-limit');

// ✅ SECURITY: Rate limiting to prevent brute force and DoS attacks

// Login endpoint: 100 attempts per 15 minutes per IP (increased for testing)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 attempts per window (increased from 5 for testing)
  message: 'Too many login attempts from this IP. Please try again in 15 minutes.',
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  // Use default IP-based key generator (handles IPv4 and IPv6 properly)
  handler: (req, res) => {
    console.warn(`🚨 RATE_LIMIT: Login - IP: ${req.ip} - Exceeded 5 attempts`);
    res.status(429).json({
      success: false,
      message: 'Too many login attempts. Please try again in 15 minutes.',
      retryAfter: Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000)
    });
  },
  skip: (req) => {
    // Don't rate limit authenticated admin users (for testing)
    return req.user?.role === 'admin';
  }
});

// Create user endpoint: 10 accounts per hour per authenticated user
const createUserLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // 10 accounts per hour
  message: 'Too many accounts created. Please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  // For authenticated users, use user ID; fallback to IP handled by default
  keyGenerator: (req) => {
    // If authenticated, use user ID, otherwise default IP-based limiting applies
    if (req.user?.id) {
      return `user:${req.user.id}`;
    }
    // For non-authenticated, return undefined to use default IP generator
    return undefined;
  },
  handler: (req, res) => {
    console.warn(`🚨 RATE_LIMIT: Create User - User: ${req.user?.id} - Exceeded 10 accounts/hour`);
    res.status(429).json({
      success: false,
      message: 'Too many accounts created. Please try again in an hour.',
      retryAfter: Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000)
    });
  }
});

// General API: 500 requests per minute per IP (increased for testing)
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 500, // 500 requests per minute (increased from 100 for testing)
  message: 'Too many requests from this IP. Please slow down.',
  standardHeaders: true,
  legacyHeaders: false,
  // Use default IP-based key generator (handles IPv4 and IPv6 properly)
  handler: (req, res) => {
    console.warn(`🚨 RATE_LIMIT: API - IP: ${req.ip} - Exceeded 100 req/min on ${req.path}`);
    res.status(429).json({
      success: false,
      message: 'Too many requests. Please slow down.',
      retryAfter: Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000)
    });
  }
});

// Submission endpoint: 5 submissions per hour per user
const submissionLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // 5 submissions per hour
  keyGenerator: (req) => {
    // If authenticated, use user ID, otherwise return undefined for default IP limiting
    if (req.user?.id) {
      return `user:${req.user.id}`;
    }
    return undefined;
  },
  handler: (req, res) => {
    console.warn(`🚨 RATE_LIMIT: Submission - User: ${req.user?.id} - Exceeded 5 submissions/hour`);
    res.status(429).json({
      success: false,
      message: 'Too many submissions. Please try again later.',
      retryAfter: Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000)
    });
  }
});

module.exports = {
  loginLimiter,
  createUserLimiter,
  apiLimiter,
  submissionLimiter
};
