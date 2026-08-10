const s3Service = require('../services/s3Service');

/**
 * Check if a user is admin or super admin
 * @param {string} role - User role
 * @returns {boolean} - True if admin or super_admin
 */
const isAdminOrSuperAdmin = (role) => {
  return ['admin', 'super_admin'].includes(role);
};

/**
 * Check if user is super admin only
 * @param {string} role - User role
 * @returns {boolean} - True if super_admin
 */
const isSuperAdmin = (role) => {
  return role === 'super_admin';
};

/**
 * Get all admin users (organization admins)
 * @param {Model} User - Mongoose User model
 * @returns {Promise<Array>} - Array of admin user IDs
 */
const getAdminUsers = async (User) => {
  const admins = await User.find({ role: 'admin' }).select('_id');
  return admins.map(r => r._id);
};

/**
 * Safely parse a JSON array from a string or return an array from other types.
 * @param {any} val - The value to parse
 * @returns {Array} - The parsed array or empty array
 */
const parseJsonArray = (val) => {
  if (!val) return [];
  if (typeof val === 'string') {
    const trimmed = val.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        return JSON.parse(trimmed);
      } catch (e) {
        try {
          return JSON.parse(trimmed.replace(/'/g, '"'));
        } catch (e2) {
          return trimmed
            .replace(/[\[\]'"]/g, '')
            .split(',')
            .map(s => s.trim())
            .filter(s => s.length > 0);
        }
      }
    }
    return [trimmed];
  }
  return Array.isArray(val) ? val : (val ? [val] : []);
};

/**
 * Transform task files by generating signed S3 URLs.
 * @param {Object} task - The task object
 * @returns {Object} - The transformed task object
 */
const transformTaskFiles = async (task) => {
  try {
    if (task.adminFiles && task.adminFiles.length > 0) {
      task.adminFiles = await Promise.all(task.adminFiles.map(async (file) => {
        if (!file || file === 'null' || file === '') return null;
        if (file.startsWith('http')) return file;
        try {
          return await s3Service.getSignedImageUrl(file);
        } catch (e) {
          return null;
        }
      }));
      task.adminFiles = task.adminFiles.filter(f => f !== null);
    }
  } catch (e) {
    // Suppress errors to ensure response delivery
  }
  return task;
};

/**
 * Transform submission keys into signed S3 URLs.
 */
const transformSubmissionFiles = async (submission, s3Service) => {
  // Support both Mongoose documents (.toObject()) and plain objects
  const plain = typeof submission.toObject === 'function' ? submission.toObject() : { ...submission };
  const beforeFilesUrls = await Promise.all((plain.beforeFiles || []).map(k => {
    if (!k || k.startsWith('http')) return k || null;
    return s3Service.getSignedImageUrl(k).catch(() => null);
  }));
  const afterFilesUrls = await Promise.all((plain.afterFiles || []).map(k => {
    if (!k || k.startsWith('http')) return k || null;
    return s3Service.getSignedImageUrl(k).catch(() => null);
  }));
  return { 
    ...plain, 
    beforeFilesUrls: beforeFilesUrls.filter(Boolean), 
    afterFilesUrls: afterFilesUrls.filter(Boolean) 
  };
};

/**
 * Transform an array of submissions.
 */
const transformSubmissionsArray = async (submissions, s3Service) => {
  return await Promise.all(submissions.map(sub => transformSubmissionFiles(sub, s3Service)));
};

module.exports = {
  isAdminOrSuperAdmin,
  isSuperAdmin,
  getAdminUsers,
  parseJsonArray,
  transformTaskFiles,
  transformSubmissionFiles,
  transformSubmissionsArray
};
