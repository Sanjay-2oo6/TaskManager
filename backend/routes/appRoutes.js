const express = require('express');
const router = express.Router();
const { getLatestVersion, updateAppVersion, getUsers } = require('../controllers/appController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { upload } = require('../utils/upload');

// Public route to check for updates
router.get('/version', getLatestVersion);

// Admin route to deploy new version (Accepts one APK file)
router.put('/version', protect, authorize(['admin', 'super_admin']), upload.single('apk'), updateAppVersion);

// Get all users in organization
router.get('/users', protect, getUsers);

module.exports = router;
