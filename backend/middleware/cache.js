/**
 * API Response Caching Middleware
 * 
 * Caches GET requests to improve performance and reduce database load.
 * Uses in-memory caching (apicache).
 * 
 * For production with multiple servers, consider Redis caching.
 */

const apicache = require('apicache');

// Create cache instance
const cache = apicache.middleware;

// Cache configuration
const cacheConfig = {
  // Default cache duration
  defaultDuration: '5 minutes',
  
  // Cache success only (skip errors)
  statusCodes: {
    include: [200],
  },
  
  // Add debug logging in development
  debug: process.env.NODE_ENV === 'development',
  
  // Append key based on request
  appendKey: (req, res) => {
    // Include user ID and role in cache key for user-specific data
    const userId = req.user?.id || 'guest';
    const role = req.user?.role || 'none';
    return `${userId}:${role}`;
  },
  
  // Skip caching for certain conditions
  shouldCacheResponse: (req, res) => {
    // Only cache GET requests
    if (req.method !== 'GET') return false;
    
    // Don't cache if response is not successful
    if (res.statusCode !== 200) return false;
    
    // Don't cache if explicitly disabled
    if (req.headers['cache-control'] === 'no-cache') return false;
    
    return true;
  },
};

/**
 * Cache durations for different endpoints
 */
const cacheDurations = {
  // Short cache (1 minute) - frequently changing data
  short: '1 minute',
  
  // Medium cache (5 minutes) - moderately changing data
  medium: '5 minutes',
  
  // Long cache (15 minutes) - rarely changing data
  long: '15 minutes',
  
  // Very long cache (1 hour) - static or reference data
  veryLong: '1 hour',
};

/**
 * Apply cache with default duration
 */
const cacheMiddleware = cache(cacheConfig.defaultDuration, undefined, cacheConfig);

/**
 * Apply cache with custom duration
 * @param {string} duration - Cache duration (e.g., '5 minutes', '1 hour')
 */
const cacheWithDuration = (duration) => {
  return cache(duration, undefined, cacheConfig);
};

/**
 * Clear specific cache entries
 * @param {string} target - Cache key or pattern to clear
 */
const clearCache = (target) => {
  if (target) {
    apicache.clear(target);
  } else {
    apicache.clear(); // Clear all cache
  }
};

/**
 * Get cache performance stats
 */
const getCacheStats = () => {
  return apicache.getPerformance();
};

/**
 * Middleware to clear cache on data modification
 * Use this after POST, PUT, PATCH, DELETE operations
 */
const invalidateCache = (patterns = []) => {
  return (req, res, next) => {
    // Store original send function
    const originalSend = res.send;
    
    // Override send function
    res.send = function(data) {
      // If operation was successful, clear relevant cache
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (patterns.length > 0) {
          patterns.forEach(pattern => clearCache(pattern));
        } else {
          // Clear all cache if no specific patterns provided
          clearCache();
        }
      }
      
      // Call original send
      originalSend.call(this, data);
    };
    
    next();
  };
};

module.exports = {
  cache: cacheMiddleware,
  cacheShort: cacheWithDuration(cacheDurations.short),
  cacheMedium: cacheWithDuration(cacheDurations.medium),
  cacheLong: cacheWithDuration(cacheDurations.long),
  cacheVeryLong: cacheWithDuration(cacheDurations.veryLong),
  cacheWithDuration,
  clearCache,
  getCacheStats,
  invalidateCache,
  cacheDurations,
};
