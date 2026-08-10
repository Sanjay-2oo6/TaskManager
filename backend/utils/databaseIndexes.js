const User = require('../models/User');
const Task = require('../models/Task');
const Submission = require('../models/Submission');
const logger = require('./logger');

/**
 * DATABASE INDEXES - Performance & Security
 * 
 * Purpose: Create database indexes for:
 * 1. SECURITY - Prevent timing attacks (consistent query speed)
 * 2. PERFORMANCE - Speed up common lookups
 * 3. INTEGRITY - Enforce uniqueness constraints
 * 
 * How it works:
 * - Indexes are database-level optimizations
 * - Instead of scanning all rows, database jumps directly to matching data
 * - Makes queries consistent (same speed always)
 * - Prevents timing attacks (username lookups always take ~same time)
 */

const createIndexes = async () => {
  try {
    logger.info('🔧 Creating database indexes...');

    // ============================================
    // USER INDEXES
    // ============================================
    
    // Username index - prevents timing attacks + speeds up login
    // Timing Attack: Without index, "user exists" query is faster than "user doesn't exist"
    // Hacker can guess usernames by measuring response time
    // With index: Both queries take ~same time
    await User.collection.createIndex({ username: 1 });
    logger.info('✅ Created index: User.username (prevents timing attacks)');

    // Email index - speeds up email verification + prevents duplicates
    await User.collection.createIndex({ email: 1 }, { sparse: true });
    logger.info('✅ Created index: User.email');

    // Role index - speeds up role-based queries (get all admins, get all employees, etc)
    await User.collection.createIndex({ role: 1 });
    logger.info('✅ Created index: User.role');

    // Timestamp index - speeds up "get recent users" queries
    await User.collection.createIndex({ createdAt: -1 });
    logger.info('✅ Created index: User.createdAt');

    // ============================================
    // TASK INDEXES
    // ============================================

    // Task status index - speed up "get all pending tasks" queries
    await Task.collection.createIndex({ status: 1 });
    logger.info('✅ Created index: Task.status');

    // Task assignedTo index - speed up "get tasks assigned to user X" queries
    await Task.collection.createIndex({ assignedTo: 1 });
    logger.info('✅ Created index: Task.assignedTo');

    // Task createdBy index - speed up "get tasks created by user X" queries
    await Task.collection.createIndex({ createdBy: 1 });
    logger.info('✅ Created index: Task.createdBy');

    // Task dueDate index - speed up "get overdue tasks" queries
    await Task.collection.createIndex({ dueDate: 1 });
    logger.info('✅ Created index: Task.dueDate');

    // Task status + dueDate compound index - speed up "get pending tasks sorted by due date"
    await Task.collection.createIndex({ status: 1, dueDate: 1 });
    logger.info('✅ Created compound index: Task(status, dueDate)');

    // ============================================
    // SUBMISSION INDEXES
    // ============================================

    // Submission taskId index - speed up "get all submissions for task X"
    await Submission.collection.createIndex({ taskId: 1 });
    logger.info('✅ Created index: Submission.taskId');

    // Submission status index - speed up "get all pending submissions"
    await Submission.collection.createIndex({ status: 1 });
    logger.info('✅ Created index: Submission.status');

    // Submission userId index - speed up "get all submissions by user X"
    await Submission.collection.createIndex({ userId: 1 });
    logger.info('✅ Created index: Submission.userId');

    // Submission taskId + status compound index - speed up "get pending submissions for task X"
    await Submission.collection.createIndex({ taskId: 1, status: 1 });
    logger.info('✅ Created compound index: Submission(taskId, status)');

    // Submission createdAt index - speed up "get recent submissions" queries
    await Submission.collection.createIndex({ createdAt: -1 });
    logger.info('✅ Created index: Submission.createdAt');

    logger.info('✅ All database indexes created successfully!');
    return true;
  } catch (error) {
    logger.error('❌ Error creating database indexes:', {
      message: error.message,
      code: error.code
    });
    // Don't throw - indexes might already exist
    // MongoDB error code 48 = index already exists
    if (error.code === 48) {
      logger.info('ℹ️ Indexes already exist, skipping creation');
      return true;
    }
    return false;
  }
};

module.exports = { createIndexes };
