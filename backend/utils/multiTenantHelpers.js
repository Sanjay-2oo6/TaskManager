/**
 * Multi-Tenant Helper Functions
 * 
 * Centralized utilities for multi-tenant operations to eliminate code duplication.
 * These functions handle common patterns across controllers:
 * - Organization validation
 * - Organization filtering
 * - Access control checks
 */

const logger = require('./logger');

/**
 * Validate that a resource belongs to the user's organization
 * @param {Object} resource - The resource to validate (task, submission, message, etc.)
 * @param {String} userOrganizationId - The authenticated user's organizationId
 * @param {String} resourceName - Name of resource for error messages (e.g., 'task', 'submission')
 * @returns {Object} { valid: boolean, error: object|null }
 */
const validateOrganizationAccess = (resource, userOrganizationId, resourceName = 'resource') => {
  if (!userOrganizationId) {
    // Super admin has no organization - skip validation
    return { valid: true, error: null };
  }

  if (!resource) {
    return {
      valid: false,
      error: {
        status: 404,
        message: `${resourceName.charAt(0).toUpperCase() + resourceName.slice(1)} not found`
      }
    };
  }

  if (resource.organizationId.toString() !== userOrganizationId.toString()) {
    logger.security('Cross-organization access attempt', {
      userOrganizationId,
      resourceOrganizationId: resource.organizationId,
      resourceName,
      resourceId: resource._id
    });

    return {
      valid: false,
      error: {
        status: 403,
        message: `Access denied: ${resourceName} belongs to different organization`
      }
    };
  }

  return { valid: true, error: null };
};

/**
 * Build organization filter for queries
 * Automatically adds organizationId to filter if user belongs to an organization
 * @param {Object} req - Express request object with authenticated user
 * @param {Object} baseFilter - Base filter object (optional)
 * @returns {Object} Filter object with organizationId added if applicable
 */
const buildOrganizationFilter = (req, baseFilter = {}) => {
  const mongoose = require('mongoose');
  const filter = { ...baseFilter };

  // ✅ MULTI-TENANT: Add organizationId filter for admin/member users
  if (req.user && req.user.organizationId) {
    // Convert to ObjectId if it's a string - fixes Issue #3 (Organization context issue)
    filter.organizationId = mongoose.Types.ObjectId.isValid(req.user.organizationId) 
      ? mongoose.Types.ObjectId.createFromHexString(req.user.organizationId)
      : req.user.organizationId;
  }

  return filter;
};

/**
 * Validate organization access and return standardized error response
 * Use this in controllers to reduce boilerplate
 * @param {Object} res - Express response object
 * @param {Object} resource - The resource to validate
 * @param {String} userOrganizationId - The authenticated user's organizationId
 * @param {String} resourceName - Name of resource for error messages
 * @returns {Boolean} true if valid, false if error response was sent
 */
const validateOrganizationAccessOrFail = (res, resource, userOrganizationId, resourceName = 'resource') => {
  const { valid, error } = validateOrganizationAccess(resource, userOrganizationId, resourceName);

  if (!valid) {
    res.status(error.status).json({
      success: false,
      message: error.message
    });
    return false;
  }

  return true;
};

/**
 * Check if user is assigned to a task (for members)
 * Handles both populated objects and raw ObjectIds
 * @param {Object} task - Task object with assignedTo array
 * @param {String} userId - User ID to check
 * @returns {Boolean} true if assigned, false otherwise
 */
const isAssignedToTask = (task, userId) => {
  if (!task.assignedTo || task.assignedTo.length === 0) {
    return false;
  }
  
  const userIdStr = String(userId).trim();
  
  const isAssigned = task.assignedTo.some(assignee => {
    // Handle both cases: populated user object or raw ObjectId
    const assigneeId = assignee._id ? String(assignee._id).trim() : String(assignee).trim();
    return assigneeId === userIdStr;
  });
  
  if (!isAssigned) {
    console.log(`⚠️ User ${userIdStr} NOT assigned to task. Task assignedTo IDs:`, 
      task.assignedTo.map(a => a._id ? String(a._id) : String(a)));
  }
  
  return isAssigned;
};

/**
 * Validate member access to task
 * - Members can only access tasks assigned to them
 * - Members CANNOT access locked tasks (status='waiting' with unmet prerequisites)
 * - Admins can access any task in their organization (including locked tasks)
 * @param {Object} res - Express response object
 * @param {Object} task - Task object with assignedTo, status, dependsOn fields
 * @param {Object} user - Authenticated user object with id and role
 * @returns {Boolean} true if authorized, false if error response was sent
 */
const validateMemberTaskAccessOrFail = (res, task, user) => {
  if (user.role === 'member') {
    // First check: member must be assigned to this task
    if (!isAssignedToTask(task, user.id)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: you are not assigned to this task'
      });
    }
    
    // Second check: member cannot access locked tasks (waiting with unmet prerequisites)
    if (task.status === 'waiting' && task.dependsOn && task.dependsOn.length > 0) {
      return res.status(403).json({
        success: false,
        message: 'Task is locked: complete prerequisite tasks first',
        isLocked: true
      });
    }
  }
  return true;
};

/**
 * Create organization-aware message data
 * Adds organizationId to message data object
 * @param {Object} messageData - Base message data
 * @param {String} organizationId - Organization ID to add
 * @returns {Object} Message data with organizationId
 */
const createMessageData = (messageData, organizationId) => {
  return {
    ...messageData,
    organizationId: organizationId || null
  };
};

/**
 * Validate and build filter with organization context
 * Combines validation and filter building in one step
 * @param {Object} req - Express request object
 * @param {Object} baseFilter - Base filter object
 * @returns {Object} Filter with organization context
 */
const buildValidatedFilter = (req, baseFilter = {}) => {
  const filter = { ...baseFilter };

  // Add organizationId for admin/member users
  if (req.user?.organizationId) {
    filter.organizationId = req.user.organizationId;
  }

  return filter;
};

/**
 * Check if user has organization context
 * @param {Object} user - Authenticated user object
 * @returns {Boolean} true if user has organizationId
 */
const hasOrganizationContext = (user) => {
  return !!(user && user.organizationId);
};

/**
 * Ensure user has organization (for operations requiring it)
 * @param {Object} res - Express response object
 * @param {Object} user - Authenticated user object
 * @returns {Boolean} true if has organization, false if error response was sent
 */
const requireOrganizationContext = (res, user) => {
  if (!hasOrganizationContext(user)) {
    res.status(400).json({
      success: false,
      message: 'User must be associated with an organization'
    });
    return false;
  }
  return true;
};

/**
 * Convert organizationId to MongoDB ObjectId for aggregation pipelines
 * @param {String} organizationId - Organization ID string
 * @returns {Object} MongoDB ObjectId
 */
const toOrganizationObjectId = (organizationId) => {
  const mongoose = require('mongoose');
  return mongoose.Types.ObjectId.createFromHexString(organizationId);
};

/**
 * Build aggregation match stage with organization filter
 * @param {Object} req - Express request object
 * @param {Object} baseMatch - Base match criteria
 * @returns {Object} Match stage with organizationId filter
 */
const buildAggregationMatch = (req, baseMatch = {}) => {
  const match = { ...baseMatch };

  if (req.user?.organizationId) {
    match.organizationId = toOrganizationObjectId(req.user.organizationId);
  }

  return match;
};

module.exports = {
  validateOrganizationAccess,
  buildOrganizationFilter,
  validateOrganizationAccessOrFail,
  isAssignedToTask,
  validateMemberTaskAccessOrFail,
  createMessageData,
  buildValidatedFilter,
  hasOrganizationContext,
  requireOrganizationContext,
  toOrganizationObjectId,
  buildAggregationMatch
};
