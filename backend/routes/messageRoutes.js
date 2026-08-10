const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');
const { protect } = require('../middleware/authMiddleware');

// IMPORTANT: Put specific routes BEFORE parameterized routes
router.get('/unread-counts', protect, messageController.getUnreadCounts);
router.get('/:taskId', protect, messageController.getMessagesByTask);
router.post('/:taskId/read', protect, messageController.markAsRead);

module.exports = router;
