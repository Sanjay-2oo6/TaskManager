const Message = require('../models/Message');
const Task = require('../models/Task');
const logger = require('../utils/logger');
const { isAdminOrSuperAdmin } = require('../utils/helpers');
const { validateOrganizationAccessOrFail, buildOrganizationFilter } = require('../utils/multiTenantHelpers');

// ✅ SECURITY FIX 0.8: Authorization check on message access
// ✅ SECURITY FIX 0.11: Structured logging applied
// ✅ DEDUPLICATION: Helper functions imported to eliminate repeated role checks

exports.getMessagesByTask = async (req, res) => {
  try {
    const { taskId } = req.params;
    const { page = 1, limit = 50 } = req.query;  // ✅ Default 50 per page, allows loading older messages
    const userId = req.user.id;
    const userRole = req.user.role;

    // 🛡️ SECURITY FIX 0.8: Verify user has access to this task's messages
    // Only admin OR assigned employees can view messages
    const task = await Task.findById(taskId).select('assignedTo createdBy organizationId');
    
    if (!task) {
      return res.status(404).json({
        success: false,
        message: 'Task not found'
      });
    }

    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, task, req.user.organizationId, 'task')) return;

    // Check authorization: Admin OR assigned to task OR created the task
    const isAdmin = isAdminOrSuperAdmin(userRole);
    const isAssigned = task.assignedTo.some(id => id.toString() === userId);
    const isCreator = task.createdBy.toString() === userId;

    if (!isAdmin && !isAssigned && !isCreator) {
      logger.security('Unauthorized message access attempt', {
        userId,
        userRole,
        taskId,
        ip: req.ip
      });
      return res.status(403).json({
        success: false,
        message: 'Access denied. You are not assigned to this task.'
      });
    }

    // User is authorized - fetch messages with pagination
    const messageFilter = buildOrganizationFilter(req, { taskId });
    const pageNum = Math.max(1, parseInt(page) || 1);
    const pageLimit = Math.min(100, Math.max(1, parseInt(limit) || 50));
    const skip = (pageNum - 1) * pageLimit;

    const [messages, totalCount] = await Promise.all([
      Message.find(messageFilter)
        .populate('sender', 'name username role')
        .sort({ createdAt: -1 })  // ✅ Most recent first
        .skip(skip)
        .limit(pageLimit),
      Message.countDocuments(messageFilter)
    ]);

    logger.debug('Messages retrieved', {
      userId,
      userRole,
      taskId,
      messageCount: messages.length,
      page: pageNum,
      limit: pageLimit,
      totalCount
    });

    res.json({
      success: true,
      data: messages.reverse(),  // ✅ Reverse to show chronological order
      pagination: {
        page: pageNum,
        limit: pageLimit,
        totalPages: Math.ceil(totalCount / pageLimit),
        totalCount
      }
    });
  } catch (error) {
    logger.error('Get messages by task error', { error: error.message });
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { taskId } = req.params;
    const userId = req.user.id;

    // Edge case: Validate taskId
    if (!taskId || taskId === 'undefined' || taskId === 'null') {
      return res.status(400).json({ success: false, message: 'Invalid task ID' });
    }

    // Convert userId string to ObjectId for correct MongoDB comparison
    const mongoose = require('mongoose');
    let userObjectId;
    try {
      userObjectId = mongoose.Types.ObjectId.createFromHexString(userId);
    } catch (e) {
      return res.status(400).json({ success: false, message: 'Invalid user ID format' });
    }

    // Mark all unread messages in this task as read by this user
    // Use ObjectId for both comparisons so MongoDB matches correctly
    const updateFilter = buildOrganizationFilter(req, { 
      taskId,
      'readBy.user': { $ne: userObjectId },  // ObjectId comparison
      sender: { $ne: userObjectId }           // Don't mark own messages
    });

    const result = await Message.updateMany(
      updateFilter,
      { $addToSet: { readBy: { user: userObjectId, readAt: new Date() } } }  // ✅ Use $addToSet to prevent duplicates
    );

    logger.debug('Messages marked as read', {
      userId,
      taskId,
      markedCount: result.modifiedCount
    });

    res.json({ success: true, markedCount: result.modifiedCount });
  } catch (error) {
    logger.error('Mark as read error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

// NEW: Get unread message counts for all tasks the user cares about.
// Admins get counts for ALL tasks. Employees get counts for assigned tasks only.
exports.getUnreadCounts = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    // Convert to ObjectId once — used in all queries below
    const mongoose = require('mongoose');
    let userObjectId;
    try {
      userObjectId = mongoose.Types.ObjectId.createFromHexString(userId);
    } catch (e) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    // Step 1: Determine which tasks this user should see
    const taskFilter = buildOrganizationFilter(req, {});
    
    if (userRole !== 'admin' && userRole !== 'super_admin') {
      taskFilter.assignedTo = userObjectId;
    }

    const tasks = await Task.find(taskFilter).select('_id');
    const taskIds = tasks.map(t => t._id);

    if (taskIds.length === 0) {
      return res.json({ success: true, data: {} });
    }

    // Step 2: Aggregate unread counts — use ObjectId for both comparisons
    const matchFilter = {
      taskId: { $in: taskIds },
      'readBy.user': { $ne: userObjectId },  // ObjectId comparison — FIXED
      sender: { $ne: userObjectId }           // Don't count own messages — FIXED
    };
    
    // ✅ MULTI-TENANT: Add organizationId to aggregation filter
    if (req.user?.organizationId) {
      matchFilter.organizationId = mongoose.Types.ObjectId.createFromHexString(req.user.organizationId);
    }

    const pipeline = [
      {
        $match: matchFilter
      },
      {
        $group: {
          _id: '$taskId',
          count: { $sum: 1 }
        }
      }
    ];

    const results = await Message.aggregate(pipeline);

    // Step 3: Convert to { taskId: count } map, only include > 0
    const unreadMap = {};
    for (const r of results) {
      if (r.count > 0) {
        unreadMap[r._id.toString()] = r.count;
      }
    }

    logger.debug('Unread counts retrieved', {
      userId,
      userRole,
      taskCount: taskIds.length,
      unreadTasks: Object.keys(unreadMap).length
    });
    res.json({ success: true, data: unreadMap });
  } catch (error) {
    logger.error('getUnreadCounts error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

