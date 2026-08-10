// ---------------------------------------------------------------------------
// securityHeadersMiddleware.js - Environment-specific security headers
// Fix 0.13: Add security headers based on environment (production vs development)
// ---------------------------------------------------------------------------

/**
 * Apply environment-specific security headers
 * Production: Strict security headers
 * Development: Relaxed for easier testing
 */
const securityHeaders = (req, res, next) => {
  const isProduction = process.env.NODE_ENV === 'production';

  if (isProduction) {
    // 🛡️ HSTS (HTTP Strict Transport Security)
    // Forces HTTPS for 1 year, prevents downgrade attacks
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');

    // 🛡️ X-Frame-Options
    // Prevents clickjacking attacks (can't embed in iframes)
    res.setHeader('X-Frame-Options', 'DENY');

    // 🛡️ X-Content-Type-Options
    // Prevents MIME type sniffing (file type confusion attacks)
    res.setHeader('X-Content-Type-Options', 'nosniff');

    // 🛡️ X-XSS-Protection
    // Enables browser XSS protection (older browsers)
    res.setHeader('X-XSS-Protection', '1; mode=block');

    // 🛡️ Referrer-Policy
    // Don't leak referrer to external sites
    res.setHeader('Referrer-Policy', 'no-referrer');

    // 🛡️ Content Security Policy (CSP)
    // Prevents inline scripts and limits script sources
    res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'");
  }

  next();
};

module.exports = { securityHeaders };
