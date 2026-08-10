/**
 * Performance Monitoring Routes
 * 
 * Provides endpoints to monitor server performance, cache stats, and health.
 */

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { getCacheStats } = require('../middleware/cache');
const os = require('os');

/**
 * @route   GET /api/v1/performance/health
 * @desc    Health check endpoint
 * @access  Public
 */
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
  });
});

/**
 * @route   GET /api/v1/performance/stats
 * @desc    Get server performance statistics
 * @access  Private/Admin
 */
router.get('/stats', protect, authorize(['admin', 'super_admin']), (req, res) => {
  const stats = {
    // Process info
    process: {
      pid: process.pid,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage(),
      version: process.version,
      platform: process.platform,
    },
    
    // System info
    system: {
      hostname: os.hostname(),
      platform: os.platform(),
      arch: os.arch(),
      cpus: os.cpus().length,
      totalMemory: os.totalmem(),
      freeMemory: os.freemem(),
      usedMemory: os.totalmem() - os.freemem(),
      memoryUsagePercent: ((os.totalmem() - os.freemem()) / os.totalmem() * 100).toFixed(2),
      loadAverage: os.loadavg(),
      uptime: os.uptime(),
    },
    
    // Cache stats
    cache: getCacheStats(),
    
    // Timestamp
    timestamp: new Date().toISOString(),
  };
  
  res.json({
    success: true,
    data: stats,
  });
});

/**
 * @route   GET /api/v1/performance/cache
 * @desc    Get cache statistics
 * @access  Private/Admin
 */
router.get('/cache', protect, authorize(['admin', 'super_admin']), (req, res) => {
  const cacheStats = getCacheStats();
  
  res.json({
    success: true,
    data: cacheStats,
  });
});

module.exports = router;
