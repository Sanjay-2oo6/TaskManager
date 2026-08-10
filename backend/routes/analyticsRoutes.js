const express = require('express');
const router = express.Router();
const { getSystemStats, getLeaderboard, getTeamActivity } = require('../controllers/analyticsController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');

// Define specific routes
router.get('/stats', protect, authorize(['admin']), getSystemStats);
router.get('/leaderboard', protect, getLeaderboard);
router.get('/activity', protect, getTeamActivity);

module.exports = router;
