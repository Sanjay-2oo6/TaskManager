const express = require('express');
const multer = require('multer');
const submissionController = require('../controllers/submissionController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validateRequest } = require('../middleware/validationMiddleware');

const router = express.Router();

// Configure Multer for buffer-based uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: { fileSize: 20 * 1024 * 1024 } // 20MB per file
});

/**
 * @route POST /api/v1/submissions
 * @desc Create a new submission with before/after images
 * @access Private (members only)
 */
router.post(
  '/',
  protect,
  upload.fields([
    { name: 'beforeFiles', maxCount: 20 },
    { name: 'afterFiles', maxCount: 20 },
    { name: 'beforeImage', maxCount: 1 },
    { name: 'afterImage', maxCount: 1 }
  ]),
  validateRequest('createSubmission'),
  submissionController.createSubmission
);

/**
 * @route GET /api/v1/submissions/pending
 * @desc Get all pending submissions (Admin only)
 * @access Private/Admin
 */
router.get('/pending', protect, authorize(['admin']), submissionController.getPendingSubmissions);

/**
 * @route GET /api/v1/submissions/member/my
 * @desc Get current member's own submissions
 * @access Private (all authenticated users)
 */
router.get('/member/my', protect, submissionController.getMySubmissions);

router.get('/admin/all', protect, authorize(['admin']), submissionController.getAllSubmissions);

/**
 * @route PATCH /api/v1/submissions/:id/status
 * @desc Approve or Reject a submission (Admin only)
 * @access Private/Admin
 */
router.patch('/:id/status', protect, authorize(['admin']), validateRequest('updateSubmissionStatus'), submissionController.updateSubmissionStatus);

/**
 * @route GET /api/v1/submissions/task/:taskId
 * @desc Get all submissions for a specific task
 * @access Private
 */
router.get('/task/:taskId', protect, submissionController.getSubmissionsByTaskId);

/**
 * @route GET /api/v1/submissions/:id
 * @desc Get submission details with protected image URLs
 * @access Private
 */
router.get('/:id', protect, submissionController.getSubmission);

/**
 * @route POST /api/v1/submissions/:id/comments
 * @desc Add a comment to a submission (Employee or Admin only)
 * @access Private
 */
router.post('/:id/comments', protect, validateRequest('addSubmissionComment'), submissionController.addSubmissionComment);

/**
 * @route GET /api/v1/submissions/:id/comments
 * @desc Get all comments for a submission (Employee or Admin only)
 * @access Private
 */
router.get('/:id/comments', protect, submissionController.getSubmissionComments);

module.exports = router;
