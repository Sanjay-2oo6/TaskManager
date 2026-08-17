const express = require('express');
const router = express.Router();
const {
  createTask,
  getUserTasks,
  getAllTasks,
  getTaskById,
  updateTask,
  deleteTask,
  assignTask,
  addTaskComment,
  bulkUpdateTasks,
  getFileProxy
} = require('../controllers/taskController');

// Assuming middleware exists
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validateRequest } = require('../middleware/validationMiddleware');

const { upload } = require('../utils/upload');

// ✅ PERFORMANCE: Import caching middleware
const { cacheShort, cacheMedium, invalidateCache } = require('../middleware/cache');

// ✅ FIX: File proxy endpoint for localhost development (CORS bypass)
router.get('/file-proxy', protect, getFileProxy);

// Create task (admin only)
// Upload middleware must come BEFORE validation so req.body is populated
router.post('/', protect, authorize(['admin']), upload.array('adminFiles', 10), validateRequest('createTask'), invalidateCache(['tasks']), createTask);

// Get user's tasks (cache for 1 minute - frequently updated)
router.get('/my', protect, cacheShort, getUserTasks);

// Get all tasks (NO CACHE - caching is broken for this endpoint)
router.get('/', protect, getAllTasks);

// Bulk update tasks (admin only) (clear cache after bulk update) - MUST come before /:id routes
router.put('/bulk/update', protect, authorize(['admin']), invalidateCache(['tasks']), bulkUpdateTasks);

// Get a single task by ID (NO CACHE - file URLs must be fresh)
// Signed URLs expire, and files can be added/deleted, so caching would cause stale data
router.get('/:id', protect, getTaskById);

// Update task (clear cache after update)
// ⚠️ NOTE: For multipart requests with files, validation happens in the controller
// because form data comes as strings and needs custom parsing before validation
router.put('/:id', protect, authorize(['admin']), upload.array('adminFiles', 10), invalidateCache(['tasks']), updateTask);

// Delete task (clear cache after delete)
router.delete('/:id', protect, authorize(['admin']), invalidateCache(['tasks']), deleteTask);

// Assign task to user (admin only) (clear cache after assign)
router.put('/:id/assign', protect, authorize(['admin']), validateRequest('assignTask'), invalidateCache(['tasks']), assignTask);

// Add task comment (clear cache after comment)
router.post('/:id/comments', protect, validateRequest('addComment'), invalidateCache(['tasks']), addTaskComment);

module.exports = router;