const rateLimit = require('express-rate-limit');

// ✅ SECURITY: Rate limiting to prevent brute force and DoS attacks

// Login endpoint: 100 attempts per 15 minutes per IP (for unauthenticated users)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 attempts per window (protects against brute force)
  message: 'Too many login attempts from this IP. Please try again in 15 minutes.',
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  // ✅ FIX 13: Skip rate limiting for OPTIONS (preflight) requests
  skip: (req) => {
    // Don't rate limit preflight requests
    if (req.method === 'OPTIONS') return true;
    // Don't rate limit authenticated admin users (for testing)
    return req.user?.role === 'admin';
  },
  // Use IP-based key for unauthenticated login attempts (brute force protection)
  handler: (req, res) => {
    console.warn(`🚨 RATE_LIMIT: Login - IP: ${req.ip} - Exceeded 100 attempts`);
    res.status(429).json({
      success: false,
      message: 'Too many login attempts. Please try again in 15 minutes.',
      retryAfter: Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000)
    });
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

// General API: 500 requests per minute per authenticated user / IP
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 500, // 500 requests per minute
  message: 'Too many requests. Please slow down.',
  standardHeaders: true,
  legacyHeaders: false,
  // ✅ FIX 13: Skip rate limiting for OPTIONS (preflight) requests
  skip: (req) => {
    if (req.method === 'OPTIONS') return true;
    // Skip for admin users
    return req.user?.role === 'admin';
  },
  // ✅ ENHANCEMENT: Use user ID for authenticated requests (fixes WiFi sharing issue)
  // For authenticated users: rate limit per user ID (so 15 users on same WiFi = 15 separate limits)
  // For unauthenticated users: rate limit per IP (brute force protection)
  keyGenerator: (req) => {
    if (req.user?.id) {
      // Authenticated: use user ID (each user gets own limit bucket)
      return `user:${req.user.id}`;
    }
    // Unauthenticated: use IP (fallback to default IP generator)
    return undefined;
  },
  handler: (req, res) => {
    const key = req.user?.id ? `user:${req.user.id}` : req.ip;
    console.warn(`🚨 RATE_LIMIT: API - ${key} - Exceeded 500 req/min on ${req.path}`);
    res.status(429).json({
      success: false,
      message: 'Too many requests. Please slow down.',
      retryAfter: Math.ceil((req.rateLimit.resetTime - Date.now()) / 1000)
    });
  }
});

// Submission endpoint: 5 submissions per hour per authenticated user
const submissionLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // 5 submissions per hour
  // ✅ FIX 13: Skip rate limiting for OPTIONS (preflight) requests
  skip: (req) => {
    if (req.method === 'OPTIONS') return true;
    // Skip for admin users
    return req.user?.role === 'admin';
  },
  // ✅ ENHANCEMENT: Use user ID for per-user submission limits
  keyGenerator: (req) => {
    // Authenticated: use user ID (each user gets own bucket)
    if (req.user?.id) {
      return `user:${req.user.id}`;
    }
    // Fallback: use IP
    return undefined;
  },
  handler: (req, res) => {
    const key = req.user?.id ? `user:${req.user.id}` : req.ip;
    console.warn(`🚨 RATE_LIMIT: Submission - ${key} - Exceeded 5 submissions/hour`);
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
