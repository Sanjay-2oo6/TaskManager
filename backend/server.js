const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const app = require('./app');
const { startOverdueTaskJob } = require('./jobs/overdueTaskJob');
const { sanitizeText } = require('./utils/sanitizer');

// ✅ SECURITY: Input sanitization for Socket.IO messages

// Load environment variables
dotenv.config();

const port = process.env.PORT || 5000;
const mongoUri = process.env.MONGODB_URI;

// --- Initialize Server & Socket.io ---
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : "*",
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"]
  }
});

// --- Socket.IO JWT Authentication Middleware ---
io.use(async (socket, next) => {
  const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];
  if (!token) {
    return next(new Error('Authentication required: no token provided'));
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // Fetch user name from DB so we don't trust client-supplied names
    const User = require('./models/User');
    const user = await User.findById(decoded.id).select('name role organizationId');
    socket.user = { 
      id: decoded.id, 
      role: decoded.role,
      organizationId: decoded.organizationId || user?.organizationId, // ✅ Add organizationId
      name: user ? user.name : 'Unknown'
    };
    next();
  } catch (err) {
    return next(new Error('Authentication failed: invalid token'));
  }
});

// Attach io to app so it's accessible in routes/controllers
app.set('io', io);

// Track which users are currently viewing which task chat
// Map: userId -> taskId
const activeViewers = new Map();

io.on('connection', (socket) => {
  console.log(`📡 Real-time Client Connected: ${socket.id} (user: ${socket.user.id})`);
  
  // Chat Room Logic
  socket.on('join-task', async (taskId) => {
    try {
      const Task = require('./models/Task');
      const task = await Task.findById(taskId).select('organizationId assignedTo createdBy');
      
      // ✅ Validate organization access before joining room
      if (!task) {
        console.warn(`⚠️ join-task blocked: Task ${taskId} not found`);
        socket.emit('error', { message: 'Task not found' });
        return;
      }
      
      if (task.organizationId !== socket.user.organizationId) {
        console.warn(`🚨 SECURITY: Cross-org access attempt - User ${socket.user.id} (org: ${socket.user.organizationId}) tried to join task from org: ${task.organizationId}`);
        socket.emit('error', { message: 'Unauthorized: task belongs to different organization' });
        return;
      }
      
      socket.join(`task_${taskId}`);
      activeViewers.set(socket.user.id, taskId);
      const room = `task_${taskId}`;
      const clients = io.sockets.adapter.rooms.get(room);
      console.log(`💬 User ${socket.user.id} joined Chat Room: ${room} (Total: ${clients ? clients.size : 0})`);
    } catch (err) {
      console.error('Error in join-task:', err);
      socket.emit('error', { message: 'Failed to join room' });
    }
  });

  socket.on('leave-task', (taskId) => {
    socket.leave(`task_${taskId}`);
    // Remove from active viewers
    if (activeViewers.get(socket.user.id) === taskId) {
      activeViewers.delete(socket.user.id);
    }
    console.log(`🚶 User ${socket.user.id} left Chat Room: task_${taskId}`);
  });

  socket.on('send-message', async (data) => {
    try {
      // SECURITY: Always use the authenticated socket user — never trust senderId from the client
      const senderId = socket.user.id;

      if (!data.taskId || !data.text || !data.text.trim()) {
        console.warn('⚠️ Incoming message blocked: Missing taskId or text');
        return;
      }

      const Message = require('./models/Message');
      const Task = require('./models/Task');

      // Authorization: verify sender is assigned to the task (or is admin)
      const task = await Task.findById(data.taskId).select('assignedTo');
      if (!task) {
        console.warn(`⚠️ send-message blocked: Task ${data.taskId} not found`);
        return;
      }
      const isAssigned = task.assignedTo.some(uid => uid.toString() === senderId);
      const isPrivileged = ['admin', 'super_admin'].includes(socket.user.role);
      if (!isAssigned && !isPrivileged) {
        console.warn(`⚠️ send-message blocked: User ${senderId} not assigned to task ${data.taskId}`);
        return;
      }
      
      // ✅ SECURITY: Sanitize message text to prevent XSS
      const sanitizedText = sanitizeText(data.text.trim());
      
      const newMessage = await Message.create({
        taskId: data.taskId,
        organizationId: socket.user.organizationId, // ✅ MULTI-TENANT: Add organizationId
        sender: senderId,
        text: sanitizedText
      });

      const [populatedMessage, taskForAlert] = await Promise.all([
        Message.findById(newMessage._id).populate('sender', 'name role'),
        Task.findById(data.taskId).select('assignedTo title')
      ]);

      const room = `task_${data.taskId}`;
      const clients = io.sockets.adapter.rooms.get(room);
      console.log(`📡 Sending chat message to ${room} (${clients ? clients.size : 0} clients in room)`);

      // 1. Broadcast to everyone in the room (currently viewing the chat) — EXCLUDING sender
      socket.to(room).emit('new-chat-message', populatedMessage);

      // 2. Echo back to sender so they get the confirmed server message
      socket.emit('new-chat-message', populatedMessage);

      // 3. For assignees NOT in the room — emit directly so they don't miss messages
      //    This ensures message reliability across multiple assignees
      const assigneeIds = taskForAlert ? taskForAlert.assignedTo.map(id => id.toString()) : [];
      const roomSockets = clients ? [...clients] : [];

      // Find socket IDs for each assignee who is NOT in the room
      const allSockets = await io.fetchSockets();
      for (const assigneeId of assigneeIds) {
        if (assigneeId === senderId) continue; // sender already got echo above
        
        // Find this assignee's socket(s)
        const assigneeSockets = allSockets.filter(s => s.user?.id === assigneeId);
        for (const assigneeSocket of assigneeSockets) {
          // Skip if already in the room (they got it via socket.to(room) above)
          if (!roomSockets.includes(assigneeSocket.id)) {
            assigneeSocket.emit('new-chat-message', populatedMessage);
            console.log(`📨 Direct delivery to offline-from-room user: ${assigneeId}`);
          }
        }
      }

      // 4. Global alert for dashboard badges — exclude the sender
      socket.broadcast.emit('global-chat-alert', {
        taskId: data.taskId,
        senderName: populatedMessage.sender.name,
        text: populatedMessage.text,
        assignedTo: assigneeIds
      });

      // 5. Push notifications — skip for users actively viewing this chat (WhatsApp behaviour)
      const notificationService = require('./services/notificationService');
      const User = require('./models/User');

      const adminUsers = await User.find({ role: 'admin' }).select('_id');
      const adminIds = adminUsers.map(u => u._id.toString());

      // All potential recipients: assignees + admins, excluding sender
      const allRecipients = [...new Set([...assigneeIds, ...adminIds])]
        .filter(id => id !== senderId);

      // Filter out users who are actively viewing THIS task's chat right now
      const pushRecipients = allRecipients.filter(id => {
        const viewingTaskId = activeViewers.get(id);
        return viewingTaskId !== data.taskId; // Only push if NOT viewing this chat
      });

      const taskTitle = taskForAlert?.title || 'a task';

      if (pushRecipients.length > 0) {
        // ✅ FIX 8.1: Truncate to 80 chars for proper notification formatting
        // Push notification body has 100-120 char limit across platforms
        const MAX_NOTIF_LENGTH = 80;
        const truncatedText = populatedMessage.text.length > MAX_NOTIF_LENGTH 
          ? populatedMessage.text.substring(0, MAX_NOTIF_LENGTH) + '…' 
          : populatedMessage.text;

        notificationService.sendToMultiple(pushRecipients, {
          title: `💬 ${populatedMessage.sender.name}`,
          body: `${taskTitle}: ${truncatedText}`,
          data: { 
            taskId: data.taskId, 
            type: 'CHAT_MESSAGE',
            senderName: populatedMessage.sender.name
          }
        });
        console.log(`🔔 Push sent to ${pushRecipients.length} users (${allRecipients.length - pushRecipients.length} suppressed — chat open)`);
      }
    } catch (error) {
      console.error('❌ Chat Error:', error);
    }
  });

  socket.on('mark-read', async (data) => {
    try {
      if (!data || !data.taskId) { console.warn('⚠️ mark-read: Missing taskId'); return; }
      const taskId = data.taskId;
      if (taskId === 'undefined' || taskId === 'null' || typeof taskId !== 'string') {
        console.warn('⚠️ mark-read: Invalid taskId format:', taskId); return;
      }

      const userId = socket.user.id;
      const Message = require('./models/Message');
      const mongoose = require('mongoose');

      // Convert to ObjectId for correct MongoDB comparison
      let userObjectId;
      try {
        userObjectId = mongoose.Types.ObjectId.createFromHexString(userId);
      } catch (e) {
        console.warn('⚠️ mark-read: Invalid userId format'); return;
      }

      // ✅ FIX 5.1: Use $addToSet instead of $push to prevent duplicate read receipts
      // $addToSet is atomic and prevents duplicate entries in the array
      const result = await Message.updateMany(
        { 
          taskId,
          'readBy.user': { $ne: userObjectId },  // ObjectId — FIXED
          sender: { $ne: userObjectId }           // Don't mark own messages — FIXED
        },
        { $addToSet: { readBy: { user: userObjectId, readAt: new Date() } } }
      );

      console.log(`✅ Socket mark-read: ${result.modifiedCount} messages marked for user ${userId} in task ${taskId}`);

      io.to(`task_${taskId}`).emit('messages-read', { taskId, readerId: userId });
    } catch (error) {
      console.error('❌ Mark-Read Error:', error);
    }
  });

  socket.on('typing', (data) => {
    if (!data.taskId) return;
    // SECURITY: Use the authenticated user's name from DB, not client-supplied userName
    socket.to(`task_${data.taskId}`).emit('user-typing', { 
      taskId: data.taskId, 
      userName: socket.user.name || 'Someone' // server-side name, not client-supplied
    });
  });

  socket.on('stop-typing', (data) => {
    socket.to(`task_${data.taskId}`).emit('user-stop-typing', { 
      taskId: data.taskId 
    });
  });

  // ✅ FIX 1: Handle submission comment events
  socket.on('submission-comment-added', (data) => {
    try {
      if (!data || !data.submissionId) {
        console.warn('⚠️ submission-comment: Missing submissionId');
        return;
      }
      
      // Broadcast comment to both employee and reviewers
      io.emit('submission-comment-updated', {
        submissionId: data.submissionId,
        taskId: data.taskId,
        comment: data.comment
      });
      console.log(`💬 Submission comment broadcast: ${data.submissionId}`);
    } catch (error) {
      console.error('❌ Submission Comment Error:', error);
    }
  });

  socket.on('disconnect', () => {
    // Remove from active viewers on disconnect
    activeViewers.delete(socket.user.id);
    console.log(`📴 Client Disconnected: ${socket.id}`);
  });
});

// --- Database Connection ---
const { createIndexes } = require('./utils/databaseIndexes');
const connectDB = require('./config/db');

// ✅ PERFORMANCE: Connect to MongoDB with optimized pooling
connectDB().then(async () => {
  // Stale Index Cleanup
  try {
    await mongoose.connection.db.collection('users').dropIndex('email_1');
    console.log('🗑️ Successfully removed legacy email index.');
  } catch (err) {}

  // 🛡️ SECURITY FIX 0.15: Create database indexes for security & performance
  await createIndexes();

  // ✅ PERFORMANCE: Signal PM2 that app is ready (for zero-downtime reloads)
  if (process.send) {
    process.send('ready');
  }

  // Start Server
  server.listen(port, () => {
    console.log(`🚀 Radiant Server running on port ${port}`);
    console.log(`⚡ Real-time Socket Portal ready.`);
    console.log(`🔧 Process ID: ${process.pid}`);
    if (process.env.NODE_APP_INSTANCE) {
      console.log(`📦 Cluster Instance: ${process.env.NODE_APP_INSTANCE}`);
    }
    // Start background jobs
    startOverdueTaskJob();
  });
}).catch((err) => {
  console.error('❌ MongoDB Connection Error:', err.message);
  process.exit(1);
});

process.on('unhandledRejection', (err) => {
  console.log('❌ UNHANDLED REJECTION! Shutting down...');
  console.error(err);
  server.close(() => {
    process.exit(1);
  });
});

// ✅ PERFORMANCE: Graceful shutdown for PM2 clustering
process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);

function gracefulShutdown() {
  console.log('📴 Received shutdown signal, closing server gracefully...');
  
  server.close(() => {
    console.log('✅ HTTP server closed');
    
    mongoose.connection.close(false, () => {
      console.log('✅ MongoDB connection closed');
      process.exit(0);
    });
  });
  
  // Force close after 10 seconds if graceful shutdown fails
  setTimeout(() => {
    console.error('⚠️ Forcing shutdown after timeout');
    process.exit(1);
  }, 10000);
}

// Restart trigger: 2026-08-02 22:37:45