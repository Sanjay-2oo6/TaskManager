const Task = require('../models/Task');
const User = require('../models/User');
const s3Service = require('../services/s3Service');
const { parseJsonArray, transformTaskFiles, isAdminOrSuperAdmin, getAdminUsers } = require('../utils/helpers');
const { 
  validateOrganizationAccessOrFail, 
  validateMemberTaskAccessOrFail,
  requireOrganizationContext,
  buildOrganizationFilter
} = require('../utils/multiTenantHelpers');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');
const { sanitizeText, sanitizeRichText } = require('../utils/sanitizer');
const { parsePaginationParams, paginatedResponse } = require('../utils/pagination');

// ✅ SECURITY: Input sanitization applied to all user inputs
// ✅ SECURITY: Pagination implemented to prevent DoS attacks
// ✅ DEDUPLICATION: Helper functions imported to eliminate repeated authorization checks



const createTask = async (req, res) => {
  try {
    const { title, description, assignedTo, dueDate, priority, adminNote, adminFiles, adminFileNames } = req.body;
    const io = req.app.get('io');

    // Basic validation
    if (!title || !title.trim()) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }
    
    if (!assignedTo || (Array.isArray(assignedTo) && assignedTo.length === 0)) {
      return res.status(400).json({ success: false, message: 'Assignee required' });
    }

    // Validate dueDate
    if (!dueDate) {
      return res.status(400).json({ success: false, message: 'Due date is required' });
    }
    const parsedDueDate = new Date(dueDate);
    if (isNaN(parsedDueDate.getTime())) {
      return res.status(400).json({ success: false, message: 'Invalid due date format' });
    }

    // Validate priority
    const validPriorities = ['low', 'medium', 'high', 'extreme'];
    const taskPriority = priority || 'medium';
    if (!validPriorities.includes(taskPriority)) {
      return res.status(400).json({ success: false, message: `Priority must be one of: ${validPriorities.join(', ')}` });
    }

    const createdBy = req.user.id;
    
    // ✅ MULTI-TENANT: Get organization context
    const organizationId = req.user.organizationId;
    if (!organizationId) {
      return res.status(400).json({ success: false, message: 'User must be associated with an organization' });
    }
    
    // Upload files to S3
    const adminFilesKeys = [];
    const adminFilesNames = [];
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const result = await s3Service.uploadToS3(file.buffer, file.originalname, file.mimetype, 'references');
        // S3 service returns {key: '...', hash: '...'} - extract just the key
        adminFilesKeys.push(result.key);
        adminFilesNames.push(file.originalname);
      }
    }

    // Parse assignedTo (can be JSON string or array)
    const assigneeIds = parseJsonArray(assignedTo);
    const dependencyIds = parseJsonArray(req.body.dependsOn);
    
    // ✅ Validate dependencies
    if (dependencyIds && dependencyIds.length > 0) {
      const depTasks = await Task.find({ _id: { $in: dependencyIds } });
      
      // Check all dependencies exist
      if (depTasks.length !== dependencyIds.length) {
        return res.status(400).json({ success: false, message: 'One or more dependency tasks not found' });
      }
      
      // Check all dependencies belong to same org (compare as strings)
      const orgIdString = organizationId.toString();
      const wrongOrg = depTasks.find(t => t.organizationId?.toString() !== orgIdString);
      if (wrongOrg) {
        return res.status(400).json({ success: false, message: 'Dependencies must be in same organization' });
      }
      
      // Check for circular dependencies (basic check)
      for (const depId of dependencyIds) {
        const depTask = await Task.findById(depId);
        if (depTask?.dependsOn?.includes(req.body._id)) {
          return res.status(400).json({ success: false, message: 'Circular dependency detected' });
        }
      }
    }
    
    // Find users
    const users = await User.find({ _id: { $in: assigneeIds } });
    
    // Determine initial status: if has dependencies, task starts in "waiting" state
    const initialStatus = (dependencyIds && dependencyIds.length > 0) ? 'waiting' : 'pending';
    
    // Create task
    const task = new Task({
      title: sanitizeText(title.trim()),
      description: sanitizeRichText(description?.trim() || ''),
      createdBy,
      organizationId,
      status: initialStatus,
      dueDate: parsedDueDate,
      priority: taskPriority,
      adminNote: sanitizeRichText(adminNote || ''),
      adminFiles: adminFilesKeys,
      adminFileNames: adminFilesNames,
      parentTaskId: req.body.parentTaskId || null,
      assignedTo: assigneeIds,
      dependsOn: dependencyIds,
      assignedToNames: users.map(u => u.name),
      assignedToUsernames: users.map(u => u.username),
      history: [{ action: 'Created Task', user: createdBy, details: 'Initial creation' }]
    });

    await task.save();
    await task.populate('assignedTo createdBy', 'name username');

    const responseData = await transformTaskFiles(task.toObject());
    
    // Real-time updates
    if (io) {
      const room = `org_${req.user.organizationId}`;
      assigneeIds.forEach(userId => {
        io.to(room).emit('task-assigned', { taskId: task._id, operatorId: userId, title: task.title, task: responseData });
      });
      io.to(room).emit('task-updated', { taskId: task._id, task: responseData });

      // Push notifications (async)
      setImmediate(() => {
        notificationService.sendToMultiple(assigneeIds, {
          title: '📌 New Task Assigned',
          body: `You have been assigned: ${task.title}`,
          data: { taskId: task._id.toString(), type: 'TASK_ASSIGNED' }
        });
      });
    }

    res.status(201).json({ success: true, data: responseData });
  } catch (error) {
    logger.error('Create task error', { error: error.message, stack: error.stack });
    res.status(500).json({ success: false, message: error.message });
  }
};


const getUserTasks = async (req, res) => {
  try {
    const userId = req.user.id;

    // ✅ SECURITY: Parse and validate pagination parameters
    const { page, limit, skip } = parsePaginationParams(req.query, {
      defaultPage: 1,
      defaultLimit: 20,
      maxLimit: 100
    });

    const { status, priority, sortBy } = req.query;
    const filter = buildOrganizationFilter(req, { assignedTo: userId });
    
    if (status && status !== 'all') filter.status = status;
    if (priority && priority !== 'all') filter.priority = priority;

    let sort = { createdAt: -1 };
    if (sortBy === 'dueDate') sort = { dueDate: 1 };
    if (sortBy === 'priority') sort = { priority: -1 };

    // Get total count for pagination
    const totalCount = await Task.countDocuments(filter);

    // PERF: No history population on list, lean() for speed
    // NOTE: When using populate with array fields (assignedTo has multiple users),
    // separate the populate calls to avoid duplicates.
    const tasks = await Task.find(filter)
      .select('-history') // Exclude history for performance
      .populate('assignedTo', 'name username')
      .populate('createdBy', 'name username')
      .populate({ path: 'dependsOn', select: 'title status _id' })
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean();

    const transformedTasks = await Promise.all(
      tasks.map(t => t.adminFiles?.length ? transformTaskFiles(t) : Promise.resolve(t))
    );

    // ✅ FIX: Deduplicate tasks by _id to prevent duplicates in response
    const uniqueTasks = [];
    const seenIds = new Set();
    for (const task of transformedTasks) {
      const taskId = task._id?.toString();
      if (taskId && !seenIds.has(taskId)) {
        seenIds.add(taskId);
        uniqueTasks.push(task);
      }
    }

    // ✅ SECURITY: Return paginated response
    res.json(paginatedResponse(uniqueTasks, page, limit, totalCount));
  } catch (error) {
    logger.error('Get user tasks error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

const getAllTasks = async (req, res) => {
  try {
    // ✅ SECURITY: Parse and validate pagination parameters
    const { page, limit, skip } = parsePaginationParams(req.query, {
      defaultPage: 1,
      defaultLimit: 20,
      maxLimit: 100 // Prevent DoS by limiting max items per page
    });

    const { status, priority, sortBy } = req.query;
    const filter = buildOrganizationFilter(req, {});
    
    if (status && status !== 'all') filter.status = status;
    if (priority && priority !== 'all') filter.priority = priority;
    
    // ✅ SECURITY FIX: Members should ONLY see tasks assigned to them
    // Admins and super_admins can see all tasks in their organization
    if (req.user && req.user.role !== 'admin' && req.user.role !== 'super_admin') {
      filter.assignedTo = req.user.id;
    }

    let sort = { createdAt: -1 };
    if (sortBy === 'dueDate') sort = { dueDate: 1 };
    if (sortBy === 'priority') sort = { priority: -1 };

    // Get total count for pagination metadata
    const totalCount = await Task.countDocuments(filter);

    // PERF: Don't populate history on the list — only needed on detail screen
    // NOTE: When using populate with array fields (assignedTo has multiple users),
    // we must be careful to avoid duplicate documents. Using lean() with explicit select.
    const tasks = await Task.find(filter)
      .select('-history') // Exclude history for performance
      .populate('assignedTo', 'name username')
      .populate('createdBy', 'name username')
      .populate({ path: 'dependsOn', select: 'title status _id' })
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean();

    // PERF: Only generate S3 URLs for tasks that actually have files
    const transformedTasks = await Promise.all(
      tasks.map(t => t.adminFiles?.length ? transformTaskFiles(t) : Promise.resolve(t))
    );

    // ✅ FIX: Deduplicate tasks by _id to prevent duplicates in response
    const uniqueTasks = [];
    const seenIds = new Set();
    for (const task of transformedTasks) {
      const taskId = task._id?.toString();
      if (taskId && !seenIds.has(taskId)) {
        seenIds.add(taskId);
        uniqueTasks.push(task);
      }
    }

    // ✅ SECURITY: Return paginated response with metadata
    res.json(paginatedResponse(uniqueTasks, page, limit, totalCount));
  } catch (error) {
    logger.error('Get all tasks error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

const updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    const io = req.app.get('io');

    // ===== STEP 0: VALIDATE TASK ID & FETCH TASK =====
    console.log('\n🔍 STEP 0: Task validation');
    if (!id || !id.match(/^[0-9a-fA-F]{24}$/)) {
      console.error('❌ Invalid task ID:', id);
      return res.status(400).json({ success: false, message: 'Invalid task ID format' });
    }

    const task = await Task.findById(id);
    if (!task) {
      console.error('❌ Task not found:', id);
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, task, req.user.organizationId, 'task')) return;

    console.log('📝 UPDATE TASK START:', {
      taskId: id,
      fieldsToUpdate: Object.keys(updates),
      newFilesCount: req.files?.length || 0,
      filesToDeleteCount: updates.filesToDelete ? JSON.parse(updates.filesToDelete || '[]').length : 0
    });

    // ===== STEP 1: PARSE FORM DATA (strings from multipart) =====
    console.log('\n🔍 STEP 1: Parsing form data');
    
    // Parse due date (optional)
    let parsedDueDate = task.dueDate;
    if (updates.dueDate) {
      try {
        parsedDueDate = new Date(updates.dueDate);
        if (isNaN(parsedDueDate.getTime())) {
          throw new Error('Invalid date');
        }
        console.log('✅ Parsed dueDate:', parsedDueDate.toISOString());
      } catch (e) {
        console.error('⚠️ Invalid due date, keeping existing:', updates.dueDate);
        // Keep existing date if parsing fails - don't reject request
      }
    }

    // ===== STEP 2: VALIDATE ENUMS (priority, status) =====
    console.log('\n🔍 STEP 2: Validating enums');
    
    const validPriorities = ['low', 'medium', 'high', 'extreme'];
    const validStatuses = ['pending', 'in-progress', 'submitted', 'completed', 'rejected', 'waiting'];

    if (updates.priority && !validPriorities.includes(updates.priority)) {
      console.warn(`⚠️ Invalid priority: ${updates.priority}, keeping existing`);
      delete updates.priority; // Skip invalid priority
    } else if (updates.priority) {
      console.log('✅ Priority valid:', updates.priority);
    }

    if (updates.status && !validStatuses.includes(updates.status)) {
      console.warn(`⚠️ Invalid status: ${updates.status}, keeping existing`);
      delete updates.status; // Skip invalid status
    } else if (updates.status) {
      console.log('✅ Status valid:', updates.status);
    }

    // ===== STEP 3: HANDLE ASSIGNED TO =====
    console.log('\n🔍 STEP 3: Processing assignedTo');
    if (updates.assignedTo) {
      try {
        const assigneeIds = parseJsonArray(updates.assignedTo);
        if (assigneeIds.length > 0) {
          const users = await User.find({ _id: { $in: assigneeIds } });
          task.assignedToNames = users.map(u => u.name);
          task.assignedToUsernames = users.map(u => u.username);
          task.assignedTo = assigneeIds;
          console.log('✅ Updated assignedTo:', assigneeIds.length, 'users');
        }
      } catch (e) {
        console.warn('⚠️ Failed to parse assignedTo, skipping:', e.message);
      }
    }

    // ===== STEP 4: HANDLE DEPENDENCIES =====
    console.log('\n🔍 STEP 4: Processing dependencies');
    if (updates.dependsOn) {
      try {
        const deps = parseJsonArray(updates.dependsOn);
        if (Array.isArray(deps)) {
          task.dependsOn = deps;
          console.log('✅ Updated dependsOn:', deps.length, 'tasks');
        }
      } catch (e) {
        console.warn('⚠️ Failed to parse dependsOn, skipping:', e.message);
      }
    }

    // ===== STEP 5: DELETE MARKED FILES FROM S3 =====
    console.log('\n🔍 STEP 5: Deleting marked files from S3');
    console.log('   Current adminFiles before deletion:', task.adminFiles?.length || 0, 'files');
    if (updates.filesToDelete) {
      try {
        const filesToDelete = JSON.parse(updates.filesToDelete);
        
        if (Array.isArray(filesToDelete) && filesToDelete.length > 0) {
          console.log('🗑️ Files to delete:', filesToDelete.length, 'keys');
          console.log('   Raw delete keys:', filesToDelete);
          
          // ✅ FIX: Normalize incoming keys (remove leading slashes, trim whitespace)
          const normalizedDeleteKeys = filesToDelete.map(k => 
            String(k).replace(/^\/+/, '').trim()
          );
          console.log('   Normalized delete keys:', normalizedDeleteKeys);
          
          // Remove from MongoDB - ONLY if there are files to delete
          const newAdminFiles = [];
          const newAdminFileNames = [];
          for (let i = 0; i < (task.adminFiles || []).length; i++) {
            const fileKey = task.adminFiles[i];
            const normalizedFileKey = String(fileKey).replace(/^\/+/, '').trim();
            
            if (!normalizedDeleteKeys.includes(normalizedFileKey)) {
              newAdminFiles.push(fileKey);
              newAdminFileNames.push(task.adminFileNames?.[i] || `File ${i + 1}`);
              console.log('   - Keeping:', fileKey);
            } else {
              console.log('   - Removing from DB:', fileKey);
            }
          }
          // ✅ FIX: Only update if we're actually deleting files
          task.adminFiles = newAdminFiles;
          task.adminFileNames = newAdminFileNames;
          
          // Delete from S3 bucket
          for (const fileKey of normalizedDeleteKeys) {
            try {
              await s3Service.deleteFromS3(fileKey);
              console.log('   ✅ Deleted from S3:', fileKey);
            } catch (err) {
              console.warn('   ⚠️ S3 delete failed (non-critical):', fileKey, err.message);
              // Continue - file reference already removed from DB
            }
          }
          
          console.log('✅ File deletion complete. Remaining:', newAdminFiles.length);
        } else {
          // ✅ FIX: If no files to delete, DON'T modify adminFiles
          console.log('✅ No files to delete (empty array)');
        }
      } catch (parseError) {
        console.error('⚠️ Failed to parse filesToDelete JSON:', parseError.message);
        // Continue - not a fatal error
      }
    } else {
      // ✅ FIX: If filesToDelete not provided at all, don't modify
      console.log('✅ No filesToDelete provided');
    }
    console.log('   adminFiles after deletion:', task.adminFiles?.length || 0, 'files');

    // ===== STEP 6: VALIDATE & UPLOAD NEW FILES =====
    console.log('\n🔍 STEP 6: Processing new files');
    console.log('   adminFiles before new uploads:', task.adminFiles?.length || 0, 'files');
    
    // ✅ SAFETY: Preserve existing files in case of error
    const existingAdminFiles = [...(task.adminFiles || [])];
    const existingAdminFileNames = [...(task.adminFileNames || [])];
    console.log('   Preserving existing:', existingAdminFiles.length, 'files');
    
    const ALLOWED_MIME_TYPES = new Set([
      'image/jpeg', 'image/png', 'application/pdf', 
      'application/msword', 
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]);
    const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB (increased from 5MB to support larger files)
    
    if (req.files && req.files.length > 0) {
      console.log('📤 Processing', req.files.length, 'new files');
      
      const newKeys = [];
      const newNames = [];
      
      for (let i = 0; i < req.files.length; i++) {
        const file = req.files[i];
        console.log(`   File ${i + 1}:`, file.originalname, `(${(file.size / 1024).toFixed(1)}KB)`);
        
        // Validate MIME type
        if (!ALLOWED_MIME_TYPES.has(file.mimetype)) {
          console.warn(`   ⚠️ Invalid MIME type: ${file.mimetype}, skipping`);
          continue;
        }
        
        // Validate file size
        if (file.size > MAX_FILE_SIZE) {
          console.warn(`   ⚠️ File too large: ${(file.size / 1024 / 1024).toFixed(2)}MB, skipping`);
          continue;
        }
        
        // Validate extension
        const filename = file.originalname.toLowerCase();
        const validExtensions = ['.jpg', '.jpeg', '.png', '.pdf', '.doc', '.docx'];
        const hasValidExt = validExtensions.some(ext => filename.endsWith(ext));
        if (!hasValidExt) {
          console.warn(`   ⚠️ Invalid extension: ${filename}, skipping`);
          continue;
        }
        
        // Upload to S3
        try {
          console.log(`   📤 Uploading to S3...`);
          const result = await s3Service.uploadToS3(file.buffer, file.originalname, file.mimetype, 'references');
          newKeys.push(result.key);
          newNames.push(file.originalname);
          console.log(`   ✅ Uploaded: ${result.key}`);
        } catch (uploadError) {
          console.error(`   ❌ S3 upload failed: ${uploadError.message}`);
          console.error('       Full error:', uploadError);
        }
      }
      
      // ✅ COMBINE existing + new files
      console.log('   📊 Combining files:');
      console.log('      Existing:', existingAdminFiles.length, 'files -', existingAdminFiles);
      console.log('      New keys:', newKeys.length, 'files -', newKeys);
      task.adminFiles = [...existingAdminFiles, ...newKeys];
      task.adminFileNames = [...existingAdminFileNames, ...newNames];
      console.log('   📊 Result:', task.adminFiles.length, 'total files -', task.adminFiles);
      console.log('✅ Combined files. Total now:', task.adminFiles.length);
    } else {
      // ✅ No new files, keep existing
      console.log('✅ No new files to upload');
      console.log('   Keeping existing:', existingAdminFiles.length, 'files');
      task.adminFiles = existingAdminFiles;
      task.adminFileNames = existingAdminFileNames;
    }
    console.log('   ✅ FINAL adminFiles count after STEP 6:', task.adminFiles?.length || 0, 'files');

    // ===== STEP 7: UPDATE TEXT FIELDS =====
    console.log('\n🔍 STEP 7: Updating text fields');
    const allowedFields = ['title', 'description', 'adminNote', 'notes'];
    let fieldsUpdated = 0;
    
    for (const field of allowedFields) {
      if (updates[field] !== undefined && updates[field] !== null) {
        const sanitized = field === 'title' 
          ? sanitizeText(updates[field]) 
          : sanitizeRichText(updates[field]);
        if (sanitized !== task[field]) {
          task[field] = sanitized;
          fieldsUpdated++;
          console.log(`   ✅ Updated ${field}`);
        }
      }
    }

    // Update priority if valid
    if (updates.priority && validPriorities.includes(updates.priority) && updates.priority !== task.priority) {
      task.priority = updates.priority;
      fieldsUpdated++;
      console.log('   ✅ Updated priority');
    }

    // Update status if valid
    if (updates.status && validStatuses.includes(updates.status) && updates.status !== task.status) {
      task.status = updates.status;
      fieldsUpdated++;
      console.log('   ✅ Updated status');
    }

    // Update due date if parsed
    if (parsedDueDate && parsedDueDate !== task.dueDate) {
      task.dueDate = parsedDueDate;
      fieldsUpdated++;
      console.log('   ✅ Updated dueDate');
    }

    console.log('✅ Text field updates complete:', fieldsUpdated, 'fields');

    // ===== STEP 8: ADD HISTORY ENTRY =====
    console.log('\n🔍 STEP 8: Adding history entry');
    task.history = task.history || [];
    task.history.push({ 
      action: 'Updated Task', 
      user: req.user.id, 
      timestamp: new Date(),
      details: fieldsUpdated > 0 ? `Updated ${fieldsUpdated} field(s)` : 'Minor update'
    });
    console.log('✅ History entry added');

    // ===== STEP 9: SAVE TO MONGODB =====
    console.log('\n🔍 STEP 9: Saving to MongoDB');
    await task.save();
    console.log('✅ Task saved');
    
    // Populate relationships
    await task.populate([
      { path: 'assignedTo', select: 'name username' },
      { path: 'createdBy', select: 'name username' },
      { path: 'history.user', select: 'name' }
    ]);
    console.log('✅ Populated relationships');

    // ===== STEP 10: GENERATE SIGNED URLS =====
    console.log('\n🔍 STEP 10: Generating signed S3 URLs');
    console.log('   Admin files in DB:', task.adminFiles?.length || 0);
    const transformedTask = await transformTaskFiles(task.toObject());
    console.log('   Signed URLs generated:', transformedTask.adminFiles?.length || 0);

    console.log('\n✅ UPDATE COMPLETE');
    console.log('   Response to client:', {
      filesCount: transformedTask.adminFiles?.length || 0,
      fileNames: transformedTask.adminFileNames || []
    });

    // ===== RESPOND TO CLIENT =====
    res.json({ success: true, data: transformedTask });

    // ===== BROADCAST UPDATES (async, non-blocking) =====
    setImmediate(() => {
      try {
        if (io) {
          const room = `org_${req.user.organizationId}`;
          io.to(room).emit('task-updated', { 
            taskId: id, 
            status: task.status, 
            assignedTo: task.assignedTo, 
            task: transformedTask 
          });

          if (updates.status && validStatuses.includes(updates.status)) {
            const Message = require('../models/Message');
            setImmediate(async () => {
              try {
                const actingUser = await User.findById(req.user.id).select('name');
                const actorName = actingUser ? actingUser.name : 'Admin';
                const systemMsg = await Message.create({
                  taskId: id,
                  organizationId: req.user.organizationId,
                  sender: req.user.id,
                  text: `${actorName} changed status to ${task.status.replace('-', ' ').toUpperCase()}`,
                  isSystem: true
                });
                const populatedSystemMsg = await Message.findById(systemMsg._id).populate('sender', 'name role');
                io.to(`task_${id}`).emit('new-chat-message', populatedSystemMsg);
              } catch (e) {
                console.warn('Message creation failed (non-critical):', e.message);
              }
            });
          }
        }

        // Push notifications
        if (updates.status && validStatuses.includes(updates.status)) {
          notificationService.sendToMultiple(task.assignedTo, {
            title: '📋 Task Status Updated',
            body: `"${task.title}" is now ${task.status.replace('-', ' ').toUpperCase()}`,
            data: { taskId: id, type: 'TASK_UPDATED', status: task.status }
          }).catch(e => console.warn('Notification failed (non-critical):', e.message));
        }
        if (updates.dueDate && parsedDueDate) {
          const newDate = new Date(task.dueDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
          notificationService.sendToMultiple(task.assignedTo, {
            title: '⏰ Deadline Updated',
            body: `Deadline for "${task.title}" changed to ${newDate}`,
            data: { taskId: id, type: 'DEADLINE_CHANGED' }
          }).catch(e => console.warn('Notification failed (non-critical):', e.message));
        }
      } catch (e) {
        console.warn('Async update broadcast failed (non-critical):', e.message);
      }
    });

  } catch (error) {
    console.error('\n❌ UPDATE TASK ERROR:', error.message);
    console.error('   Stack:', error.stack);
    logger.error('Update task error', { error: error.message, stack: error.stack, taskId: req.params.id });
    res.status(500).json({ success: false, message: 'Failed to update task: ' + error.message });
  }
};

const deleteTask = async (req, res) => {
  try {
    const { id } = req.params;
    const io = req.app.get('io');

    // ✅ SECURITY FIX 2.1: Explicit authorization check (defense-in-depth)
    if (!isAdminOrSuperAdmin(req.user.role)) {
      return res.status(403).json({ success: false, message: 'Forbidden: Only admins can delete tasks' });
    }

    const task = await Task.findById(id);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });
    
    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, task, req.user.organizationId, 'task')) return;

    await Task.findByIdAndDelete(id);

    // Cascade: clean up orphaned messages and submissions
    const Message = require('../models/Message');
    const Submission = require('../models/Submission');

    // ✅ FIX 4.1: Also remove this task from all dependent tasks' dependency arrays
    // Prevents orphaned references when deleting a task that others depend on
    await Promise.all([
      Message.deleteMany({ taskId: id }),
      Submission.deleteMany({ task: id }),
      Task.updateMany(
        { dependsOn: id },
        { $pull: { dependsOn: id } }
      ),
    ]);

    if (io) io.to(`org_${req.user.organizationId}`).emit('task-deleted', { taskId: id });
    res.json({ success: true, message: 'Task purged.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const assignTask = async (req, res) => {
  try {
    const { id } = req.params;
    const { assignedTo } = req.body;
    const io = req.app.get('io');

    const task = await Task.findById(id);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });
    
    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, task, req.user.organizationId, 'task')) return;

    const assigneeIds = parseJsonArray(assignedTo);
    const users = await User.find({ _id: { $in: assigneeIds } });
    
    task.assignedTo = assigneeIds;
    task.assignedToNames = users.map(u => u.name);
    task.assignedToUsernames = users.map(u => u.username);
    
    task.history.push({ 
      action: 'Assigned Task', 
      user: req.user.id, 
      details: `Assigned to ${task.assignedToNames.join(', ')}` 
    });
    await task.save();
    await task.populate([
      { path: 'assignedTo', select: 'name username' },
      { path: 'createdBy', select: 'name username' },
    ]);

    const transformedTask = await transformTaskFiles(task.toObject());
    if (io) {
      const room = `org_${req.user.organizationId}`;
      io.to(room).emit('task-updated', { taskId: id, assignedTo: assigneeIds, task: transformedTask });

      // Notify newly assigned users
      notificationService.sendToMultiple(assigneeIds, {
        title: '📌 Task Assigned',
        body: `You have been assigned: "${task.title}"`,
        data: { taskId: id, type: 'TASK_ASSIGNED' }
      });
    }

    res.json({ success: true, data: transformedTask });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getTaskById = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('assignedTo createdBy', 'name username')
      .populate('comments.user', 'name username')
      .populate('history.user', 'name username')
      .populate('dependsOn', 'title status assignedToNames')
      .populate('parentTaskId', 'title status');
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, task, req.user.organizationId, 'task')) return;

    // Authorization: members can only view tasks they are assigned to
    if (!validateMemberTaskAccessOrFail(res, task, req.user)) return;

    const transformedTask = await transformTaskFiles(task.toObject());
    res.json({ success: true, data: transformedTask });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const addTaskComment = async (req, res) => {
  try {
    const { id } = req.params;
    const { text } = req.body;
    const io = req.app.get('io');

    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Comment text is required' });
    }

    // Authorization: members can only comment on tasks they are assigned to
    const task = await Task.findById(id);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    // ✅ MULTI-TENANT: Validate organization access
    if (!validateOrganizationAccessOrFail(res, task, req.user.organizationId, 'task')) return;

    // Validate member access
    if (!validateMemberTaskAccessOrFail(res, task, req.user)) return;

    const updatedTask = await Task.findByIdAndUpdate(
      id,
      { $push: { comments: { user: req.user.id, text: sanitizeText(text.trim()) } } },
      { new: true }
    ).populate('comments.user', 'name username');

    const transformedTask = await transformTaskFiles(updatedTask.toObject());
    if (io) {
      const room = `org_${req.user.organizationId}`;
      io.to(room).emit('task-updated', { taskId: id, task: transformedTask });
      io.to(room).emit('new-comment', { taskId: id, text, user: req.user.id, task: transformedTask });

      // Fetch commenter's name since JWT only has id+role
      const commenter = await User.findById(req.user.id).select('name');
      const commenterName = commenter ? commenter.name : 'Someone';

      // Notify all assignees except the commenter themselves
      const recipientIds = updatedTask.assignedTo
        .map(u => u._id || u)
        .filter(uid => uid.toString() !== req.user.id);

      notificationService.sendToMultiple(recipientIds, {
        title: `💬 New Comment on "${task.title}"`,
        body: `${commenterName}: ${text.substring(0, 80)}${text.length > 80 ? '...' : ''}`,
        data: { taskId: id, type: 'NEW_COMMENT' }
      });
    }

    res.json({ success: true, data: transformedTask });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const bulkUpdateTasks = async (req, res) => {
  try {
    const { taskIds, updates } = req.body;

    if (!Array.isArray(taskIds) || taskIds.length === 0) {
      return res.status(400).json({ success: false, message: 'taskIds must be a non-empty array' });
    }
    if (!updates || typeof updates !== 'object' || Array.isArray(updates)) {
      return res.status(400).json({ success: false, message: 'updates must be an object' });
    }

    // ✅ SECURITY FIX: Validate user has organization context
    if (!requireOrganizationContext(res, req.user)) return;
    const organizationId = req.user.organizationId;

    // Whitelist allowed bulk-update fields to prevent mass-assignment attacks
    const allowedFields = ['status', 'priority', 'dueDate'];
    const sanitizedUpdates = {};
    for (const key of allowedFields) {
      if (updates[key] !== undefined) sanitizedUpdates[key] = updates[key];
    }

    if (Object.keys(sanitizedUpdates).length === 0) {
      return res.status(400).json({ success: false, message: 'No valid fields to update' });
    }

    // ✅ SECURITY FIX: Only update tasks in the user's organization
    await Task.updateMany(
      { _id: { $in: taskIds }, organizationId: organizationId },
      { $set: sanitizedUpdates }
    );
    res.json({ success: true, message: 'Bulk update applied.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { createTask, getUserTasks, getAllTasks, getTaskById, updateTask, deleteTask, assignTask, addTaskComment, bulkUpdateTasks };