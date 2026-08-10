/**
 * Super Admin Routes
 * 
 * All routes require super_admin role
 */

const express = require('express');
const router = express.Router();
const {
  createOrganization,
  getAllOrganizations,
  getOrganization,
  updateOrganization,
  deleteOrganization,
  toggleOrganizationStatus,
  getPlatformStats,
} = require('../controllers/superAdminController');

const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');

// All routes require super_admin role
router.use(protect);
router.use(authorize(['super_admin']));

// Organization management
router.route('/organizations')
  .post(createOrganization)      // Create organization
  .get(getAllOrganizations);     // List all organizations

router.route('/organizations/:id')
  .get(getOrganization)          // Get organization details
  .patch(updateOrganization)     // Update organization
  .delete(deleteOrganization);   // Delete organization

router.post('/organizations/:id/toggle', toggleOrganizationStatus); // Activate/deactivate

// Platform statistics
router.get('/stats', getPlatformStats);

module.exports = router;
