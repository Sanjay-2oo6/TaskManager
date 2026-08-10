const express = require('express');
const { createUser, login, getMe, getUsers, deleteUser, updatePassword, changeMyProfile, updateFcmToken } = require('../controllers/authController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { loginLimiter, createUserLimiter } = require('../middleware/rateLimitMiddleware');
const { validateRequest, validateParams } = require('../middleware/validationMiddleware');

const router = express.Router();

// ✅ SECURITY: Apply rate limiting + validation to auth endpoints
router.post('/users', protect, authorize(['admin']), createUserLimiter, validateRequest('createUser'), createUser);
router.post('/login', loginLimiter, validateRequest('login'), login);
router.get('/me', protect, getMe);
router.put('/me/profile', protect, validateRequest('updateProfile'), changeMyProfile);
router.get('/users', protect, authorize(['admin']), getUsers);
router.delete('/users/:id', protect, authorize(['admin']), deleteUser);
router.put('/users/:id/password', protect, authorize(['admin']), validateRequest('updatePassword'), updatePassword);
router.put('/fcm-token', protect, validateRequest('updateFcmToken'), updateFcmToken);


router.get('/admin', protect, authorize('admin'), (req, res) => {
  res.json({
    success: true,
    data: { message: 'Admin access granted' },
    message: 'Authorized admin endpoint',
  });
});

module.exports = router;
