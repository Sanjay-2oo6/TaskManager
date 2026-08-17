const Submission = require('../models/Submission');
const Task = require('../models/Task');
const User = require('../models/User');
const s3Service = require('../services/s3Service');
const { transformSubmissionFiles, transformSubmissionsArray, isAdminOrSuperAdmin, getAdminUsers } = require('../utils/helpers');
const { 
  validateOrganizationAccessOrFail, 
  requireOrganizationContext,
  buildOrganizationFilter
} = require('../utils/multiTenantHelpers');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');
const { sanitizeText } = require('../utils/sanitizer');
const { parsePaginationParams, paginatedResponse } = require('../utils/pagination');

// ✅ DEDUPLICATION: Helper functions imported to eliminate repeated authorization checks

// ✅ SECURITY: Input sanitization for submission descriptions
// ✅ SECURITY: Pagination implemented to prevent DoS attacks


/**
 * Handle new task submission with proof images.
 * POST /api/v1/submissions
 */
exports.createSubmission = async (req, res) => {
  try {
    const { taskId, description } = req.body;
    const io = req.app.get('io');

    // SECURITY: Always use the authenticated user's ID — never trust userId from the client body
    const userId = req.user.id;
    
    // ✅ MULTI-TENANT: Validate user has organization context
    if (!requireOrganizationContext(res, req.user)) return;
    const organizationId = req.user.organizationId;

    const task = await Task.findById(taskId);
    const employee = await User.findById(userId);

    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });
    if (!employee) return res.status(404).json({ success: false, message: 'Employee not found' });

    // ✅ MULTI-TENANT: Validate task belongs to same organization
    if (!validateOrganizationAccessOrFail(res, task, organizationId, 'task')) return;

    // Verify the authenticated user is actually assigned to this task
    const isAssigned = task.assignedTo.some(id => id.toString() === userId.toString());
    if (!isAssigned) {
      return res.status(403).json({ success: false, message: 'You are not assigned to this task' });
    }

    // Guard: prevent duplicate pending submissions for the same task by the same user
    const existingPending = await Submission.findOne({ task: taskId, employee: userId, status: 'pending' });
    if (existingPending) {
      return res.status(409).json({ 
        success: false, 
        message: 'You already have a pending submission for this task. Wait for it to be reviewed before submitting again.' 
      });
    }

    // #12 — Detect resubmission (previous rejected submission exists)
    const wasRejected = await Submission.findOne({ task: taskId, employee: userId, status: 'rejected' });
    const isResubmission = !!wasRejected;

    // Parallel upload for S3 optimization (High speed internet benefit)
    const beforeFilesPromises = [];
    if (req.files && req.files.beforeFiles) {
      for (const file of req.files.beforeFiles) {
        beforeFilesPromises.push(s3Service.uploadToS3(file.buffer, file.originalname, file.mimetype));
      }
    }
    
    const afterFilesPromises = [];
    if (req.files && req.files.afterFiles) {
      for (const file of req.files.afterFiles) {
        afterFilesPromises.push(s3Service.uploadToS3(file.buffer, file.originalname, file.mimetype));
      }
    }

    const beforeFilesResults = await Promise.all(beforeFilesPromises);
    const afterFilesResults = await Promise.all(afterFilesPromises);
    
    // Extract keys and hashes (🛡️ Fix 0.12: Now returns object with key and hash)
    const beforeFilesKeys = beforeFilesResults.map(result => typeof result === 'string' ? result : result.key);
    const afterFilesKeys = afterFilesResults.map(result => typeof result === 'string' ? result : result.key);
    // Note: beforeFileHashes and afterFileHashes could be used for future integrity verification
    const beforeFileNames = (req.files && req.files.beforeFiles) ? req.files.beforeFiles.map(f => f.originalname) : [];
    const afterFileNames = (req.files && req.files.afterFiles) ? req.files.afterFiles.map(f => f.originalname) : [];

    const submission = await Submission.create({
      task: taskId,
      employee: userId,
      organizationId, // ✅ MULTI-TENANT: Add organizationId
      previousSubmissionId: isResubmission ? wasRejected._id : null, // ✅ FIX 8: Link to rejected submission
      taskTitle: task.title,
      employeeName: employee.name,
      beforeFiles: beforeFilesKeys,
      beforeFileNames: beforeFileNames,
      afterFiles: afterFilesKeys,
      afterFileNames: afterFileNames,
      description: sanitizeText(description || ''),
      status: 'pending'
    });

    // ✅ FIX: Always set task to 'submitted' when new submission created (handles resubmission after rejection)
    const updatedTask = await Task.findByIdAndUpdate(
      taskId, 
      { status: 'submitted', submission: submission._id },
      { new: true }
    ).populate('assignedTo createdBy', 'name username');

    console.log('✅ Task status updated to submitted:', { 
      taskId: taskId, 
      newStatus: updatedTask?.status,
      updatedTask: updatedTask?.toObject ? updatedTask.toObject() : updatedTask 
    });

    // Add history entry for resubmission
    if (updatedTask && isResubmission) {
      updatedTask.history.push({
        action: 'Resubmitted after rejection',
        user: userId,
        timestamp: new Date(),
        details: 'Employee resubmitted work after previous rejection'
      });
      await updatedTask.save();
    }

    // Emit real-time pulse with full data
    if (io) {
      const room = `org_${organizationId}`;
      console.log(`📡 Emitting task-updated to room: ${room}`, {
        taskId: taskId,
        status: 'submitted',
        taskObjectKeys: updatedTask ? Object.keys(updatedTask.toObject()) : []
      });
      io.to(room).emit('new-submission', { taskId, submissionId: submission._id, employeeName: employee.name, submission: submission.toObject() });
      io.to(room).emit('task-updated', { taskId, status: 'submitted', task: updatedTask.toObject() });
      console.log('✅ Socket events emitted successfully');
    }

    res.status(201).json({ success: true, data: submission, message: 'Mission evidence delivered successfully.' });

    // PERF: Notifications are fire-and-forget
    setImmediate(async () => {
      try {
        const reviewerIds = await getAdminUsers(User);
        notificationService.sendToMultiple(reviewerIds, {
          title: isResubmission ? '🔄 Task Resubmitted for Review' : '📋 New Submission Awaiting Review',
          body: `${employee.name} ${isResubmission ? 'resubmitted' : 'submitted'} proof for: "${task.title}"`,
          data: { taskId: taskId.toString(), submissionId: submission._id.toString(), type: isResubmission ? 'TASK_RESUBMITTED' : 'NEW_SUBMISSION' }
        });
  } catch (error) {
    logger.error('Submission notification error', { error: error.message });
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Get a specific submission with signed URLs for images.
 */
exports.getSubmission = async (req, res) => {
  try {
    const submission = await Submission.findById(req.params.id)
      .populate('employee', 'name');
    
    if (!submission) {
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, submission, req.user.organizationId, 'submission')) return;

    // ✅ SECURITY: Verify user has access to this submission
    const isAdmin = isAdminOrSuperAdmin(req.user.role);
    const isEmployee = submission.employee._id.toString() === req.user.id;
    
    if (!isAdmin && !isEmployee) {
      logger.security('Unauthorized submission access attempt', {
        userId: req.user.id,
        userRole: req.user.role,
        submissionId: req.params.id,
        ip: req.ip
      });
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this submission'
      });
    }

    // ✅ AUDIT LOG
    logger.debug('Submission accessed', {
      submissionId: req.params.id,
      userId: req.user.id,
      userRole: req.user.role
    });

    const result = await transformSubmissionFiles(submission, s3Service);
    res.status(200).json({ success: true, data: result });

  } catch (error) {
    logger.error('Get submission error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Get all pending submissions for admin review.
 * ✅ FIX 3: Added pagination to prevent DoS and performance issues
 */
exports.getPendingSubmissions = async (req, res) => {
  try {
    // ✅ SECURITY: Parse and validate pagination parameters
    const { page, limit, skip } = parsePaginationParams(req.query, {
      defaultPage: 1,
      defaultLimit: 20,
      maxLimit: 100
    });

    const filter = buildOrganizationFilter(req, { status: 'pending' });

    // Get total count for pagination metadata
    const totalCount = await Submission.countDocuments(filter);

    // Fetch paginated submissions
    const submissions = await Submission.find(filter)
      .populate('task', 'title description')
      .populate('employee', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const results = await transformSubmissionsArray(submissions, s3Service);

    // ✅ SECURITY: Return paginated response with metadata
    res.status(200).json(paginatedResponse(results, page, limit, totalCount));
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Admin updates submission status (Approve/Reject).
 */
exports.updateSubmissionStatus = async (req, res) => {
  try {
    const { status, adminFeedback } = req.body;
    const io = req.app.get('io');

    // Validate status value
    const allowedStatuses = ['approved', 'rejected'];
    if (!status || !allowedStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Status must be "approved" or "rejected"' });
    }

    // Role guard: only admins can review submissions
    if (!isAdminOrSuperAdmin(req.user.role)) {
      return res.status(403).json({ success: false, message: 'Forbidden: insufficient permissions' });
    }

    // ✅ SECURITY: Fetch submission BEFORE updating to validate organization access
    const submission = await Submission.findById(req.params.id);
    if (!submission) return res.status(404).json({ success: false, message: 'Submission not found' });
    
    // ✅ MULTI-TENANT: Validate organization access BEFORE updating
    if (!validateOrganizationAccessOrFail(res, submission, req.user.organizationId, 'submission')) return;

    // ✅ NOW update the submission after access check
    submission.status = status;
    submission.adminFeedback = adminFeedback;
    await submission.save();

    const taskStatus = status === 'approved' ? 'completed' : 'rejected';
    const task = await Task.findById(submission.task);
    if (task) {
      task.status = taskStatus;
      task.history.push({ action: `Submission ${status}`, user: req.user ? req.user.id : null, details: adminFeedback || `Admin ${status} verified submission.` });
      await task.save();
      console.log('✅ Task status updated to ' + taskStatus, {
        taskId: submission.task,
        newStatus: task.status,
        submissionStatus: status
      });
    } else {
      console.warn('⚠️ Task not found when updating submission status:', submission.task);
    }

    // Emit real-time pulse with full data
    if (io) {
      const transformedTask = task 
        ? await Task.findById(submission.task).populate('assignedTo createdBy', 'name username')
        : null;
      
      if (transformedTask) {
        const room = `org_${req.user.organizationId}`;
        console.log(`📡 Emitting submission-reviewed and task-updated to room: ${room}`, {
          status: status,
          taskStatus: taskStatus,
          taskId: submission.task
        });
        io.to(room).emit('submission-reviewed', { submissionId: submission._id, status, taskId: submission.task, task: transformedTask.toObject(), submission: submission.toObject() });
        io.to(room).emit('task-updated', { taskId: submission.task, status: taskStatus, task: transformedTask.toObject() });
        console.log('✅ Socket events emitted for submission review');
      } else {
        console.warn('⚠️ Transformed task is null - socket events not emitted');
      }

      // --- System Message for Chat Timeline ---
      const Message = require('../models/Message');
      const systemMsg = await Message.create({
        taskId: submission.task,
        organizationId: req.user.organizationId, // ✅ MULTI-TENANT: Add organizationId
        sender: req.user.id,
        text: `Submission ${status === 'approved' ? 'APPROVED' : 'REJECTED'} by Admin`,
        isSystem: true
      });
      const populatedSystemMsg = await Message.findById(systemMsg._id).populate('sender', 'name role');
      io.to(`task_${submission.task}`).emit('new-chat-message', populatedSystemMsg);

      // --- Push Notification to Employee (only if task still exists) ---
      if (task) {
        notificationService.sendToUser(submission.employee, {
          title: status === 'approved' ? '✅ Task Approved' : '❌ Task Rejected',
          body: status === 'approved' 
            ? `Your work on "${task.title}" has been approved.` 
            : `Review required for "${task.title}": ${adminFeedback || 'No feedback provided.'}`,
          data: { taskId: submission.task.toString(), submissionId: submission._id.toString(), type: 'SUBMISSION_REVIEWED' }
        });
      }

      // --- UNLOCK LOGIC: Find tasks waiting for this one ---
      if (status === 'approved') {
        const dependentTasks = await Task.find({ dependsOn: submission.task }).populate('dependsOn', 'status');
        for (const depTask of dependentTasks) {
          // Check if ALL dependencies for this task are now 'completed'
          const stillBlocked = depTask.dependsOn.some(d => d.status !== 'completed');
          if (!stillBlocked) {
            // Emit Unlock Alert to the specific operator
            io.emit('task-unlocked', { 
              taskId: depTask._id, 
              operatorId: depTask.assignedTo,
              message: `${task.title} is finished. Start working on ${depTask.title} now!`
            });
            // Push notification to all assignees of the newly unblocked task
            notificationService.sendToMultiple(depTask.assignedTo, {
              title: '🔓 Task Unlocked',
              body: `"${depTask.title}" is now available — "${task.title}" has been completed.`,
              data: { taskId: depTask._id.toString(), type: 'TASK_UNLOCKED' }
            });
          }
        }
      }
    }

    res.status(200).json({ success: true, data: submission, message: `Submission ${status} and relayed instantly.` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getSubmissionsByTaskId = async (req, res) => {
  try {
    const { taskId } = req.params;
    
    // ✅ SECURITY: Verify user has access to this task
    const task = await Task.findById(taskId);
    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Task not found'
      });
    }

    // Check authorization
    const isAdmin = isAdminOrSuperAdmin(req.user.role);
    const isAssigned = task.assignedTo.some(uid => 
      uid.toString() === req.user.id
    );
    
    if (!isAdmin && !isAssigned) {
      logger.security('Unauthorized submission view attempt', {
        userId: req.user.id,
        userRole: req.user.role,
        taskId: taskId,
        ip: req.ip
      });
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to view submissions for this task'
      });
    }

    // ✅ MULTI-TENANT: Validate task organization access
    if (!validateOrganizationAccessOrFail(res, task, req.user.organizationId, 'task')) return;

    // ✅ SECURITY: Parse pagination parameters
    const { page, limit, skip } = parsePaginationParams(req.query, {
      defaultPage: 1,
      defaultLimit: 10, // Fewer items for task-specific view
      maxLimit: 50
    });

    // Get total count
    const totalCount = await Submission.countDocuments({ task: taskId });

    const submissionFilter = buildOrganizationFilter(req, { task: taskId });

    // Fetch paginated submissions
    const submissions = await Submission.find(submissionFilter)
      .populate('employee', 'name email profilePicture')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const results = await transformSubmissionsArray(submissions, s3Service);

    // ✅ SECURITY: Return paginated response
    res.status(200).json(paginatedResponse(results, page, limit, totalCount));
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getAllSubmissions = async (req, res) => {
  try {
    // ✅ SECURITY: Parse and validate pagination parameters
    const { page, limit, skip } = parsePaginationParams(req.query, {
      defaultPage: 1,
      defaultLimit: 20,
      maxLimit: 100
    });

    const filter = buildOrganizationFilter(req, {});

    // Get total count
    const totalCount = await Submission.countDocuments(filter);

    // Fetch paginated submissions
    const submissions = await Submission.find(filter)
      .populate('task', 'title description')
      .populate('employee', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const results = await transformSubmissionsArray(submissions, s3Service);

    // ✅ SECURITY: Return paginated response
    res.status(200).json(paginatedResponse(results, page, limit, totalCount));
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Get submissions for the current member (their own submissions)
 * GET /api/v1/submissions/member/my
 * ✅ Allows members to view their own submission history
 */
exports.getMySubmissions = async (req, res) => {
  try {
    const { page, limit, skip } = parsePaginationParams(req.query, {
      defaultPage: 1,
      defaultLimit: 20,
      maxLimit: 100
    });

    // SECURITY: Always use authenticated user ID
    const userId = req.user.id;
    const organizationId = req.user.organizationId;

    // ✅ MULTI-TENANT: Filter by both user and organization
    const filter = {
      employee: userId,
      organizationId: organizationId
    };

    // Get total count
    const totalCount = await Submission.countDocuments(filter);

    // Fetch paginated submissions
    const submissions = await Submission.find(filter)
      .populate('task', 'title description priority status')
      .populate('employee', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const results = await transformSubmissionsArray(submissions, s3Service);

    // ✅ SECURITY: Return paginated response
    res.status(200).json(paginatedResponse(results, page, limit, totalCount));
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Add a comment to a submission (Private conversation between employee + reviewer)
 * POST /api/v1/submissions/:id/comments
 * ✅ Fixed: Removed duplicate definition
 */
exports.addSubmissionComment = async (req, res) => {
  try {
    const { id } = req.params;
    const { text } = req.body;
    const io = req.app.get('io');

    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Comment text is required' });
    }

    const submission = await Submission.findById(id);
    if (!submission) {
      return res.status(404).json({ success: false, message: 'Submission not found' });
    }

    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, submission, req.user.organizationId, 'submission')) return;

    // ✅ SECURITY: Authorization check
    // Only the employee who submitted OR admin can comment
    const isEmployee = submission.employee._id ? submission.employee._id.toString() === req.user.id : submission.employee.toString() === req.user.id;
    const isReviewer = isAdminOrSuperAdmin(req.user.role);
    
    if (!isEmployee && !isReviewer) {
      logger.security('Unauthorized comment attempt', {
        userId: req.user.id,
        userRole: req.user.role,
        submissionId: id,
        ip: req.ip
      });
      return res.status(403).json({ success: false, message: 'You are not authorized to comment on this submission' });
    }

    // ✅ INPUT SANITIZATION: Sanitize comment text
    const sanitizedText = sanitizeText(text.trim());

    // Add comment to submission
    const updatedSubmission = await Submission.findByIdAndUpdate(
      id,
      { $push: { comments: { user: req.user.id, text: sanitizedText } } },
      { new: true }
    ).populate('comments.user', 'name role');

    // ✅ AUDIT LOG
    logger.debug('Submission comment added', {
      submissionId: id,
      userId: req.user.id
    });

    // Emit real-time update
    if (io) {
      io.emit('submission-comment-added', { 
        submissionId: id, 
        taskId: submission.task,
        comment: updatedSubmission.comments[updatedSubmission.comments.length - 1]
      });

      // Push notification to employee if reviewer commented, or to reviewers if employee commented
      if (isReviewer) {
        // Reviewer commenting → notify employee
        notificationService.sendToUser(submission.employee, {
          title: '💬 Review Response on Your Submission',
          body: `${sanitizedText.substring(0, 80)}${sanitizedText.length > 80 ? '...' : ''}`,
          data: { submissionId: id.toString(), taskId: submission.task.toString(), type: 'SUBMISSION_COMMENT' }
        });
      } else {
        // Employee commenting → notify reviewers
        const reviewerIds = await getAdminUsers(User);
        notificationService.sendToMultiple(reviewerIds, {
          title: '💬 Employee Response to Review',
          body: `"${submission.taskTitle}": ${sanitizedText.substring(0, 80)}${sanitizedText.length > 80 ? '...' : ''}`,
          data: { submissionId: id.toString(), taskId: submission.task.toString(), type: 'SUBMISSION_COMMENT' }
        });
      }
    }

    res.status(201).json({ success: true, data: updatedSubmission });
  } catch (error) {
    logger.error('Add submission comment error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Get all comments for a submission
 * GET /api/v1/submissions/:id/comments
 * ✅ Fixed: Removed duplicate definition
 */
exports.getSubmissionComments = async (req, res) => {
  try {
    const { id } = req.params;

    const submission = await Submission.findById(id).populate('comments.user', 'name username role');
    if (!submission) {
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, submission, req.user.organizationId, 'submission')) return;

    // ✅ SECURITY: Verify user has access to this submission
    const isAdmin = isAdminOrSuperAdmin(req.user.role);
    const isEmployee = submission.employee._id ? submission.employee._id.toString() === req.user.id : submission.employee.toString() === req.user.id;

    if (!isAdmin && !isEmployee) {
      logger.security('Unauthorized comment access attempt', {
        userId: req.user.id,
        userRole: req.user.role,
        submissionId: id,
        ip: req.ip
      });
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this submission'
      });
    }

    // ✅ AUDIT LOG
    logger.debug('Submission comments accessed', {
      submissionId: id,
      userId: req.user.id,
      userRole: req.user.role
    });

    res.status(200).json({
      success: true,
      data: submission.comments || []
    });
  } catch (error) {
    logger.error('Get submission comments error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

