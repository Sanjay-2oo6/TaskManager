const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  assignedTo: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }],
  assignedToNames: [String],
  assignedToUsernames: [String],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  organizationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Organization',
    required: true,
    index: true,
  },
  status: {
    type: String,
    enum: ['pending', 'in-progress', 'submitted', 'completed', 'rejected', 'waiting'],
    default: 'pending'
  },
  dueDate: {
    type: Date,
    required: true
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'extreme'],
    default: 'medium'
  },
  notes: {
    type: String,
    trim: true,
    default: ''
  },
  adminNote: {
    type: String,
    trim: true,
    default: ''
  },
  adminFiles: [{
    type: String
  }],
  adminFileNames: [{
    type: String
  }],
  dependsOn: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task'
  }],
  parentTaskId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task',
    default: null
  },
  comments: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    text: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
  }],
  history: [{
    action: { type: String, required: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    timestamp: { type: Date, default: Date.now },
    details: String
  }]
}, {
  timestamps: true
});

// ─── Indexes for fast queries ─────────────────────────────────────────────────
// Multi-tenant: organizationId index (MOST IMPORTANT for data isolation)
taskSchema.index({ organizationId: 1 });
taskSchema.index({ organizationId: 1, status: 1 });
taskSchema.index({ organizationId: 1, assignedTo: 1 });
// Most common query: tasks for a specific user (task list screen)
taskSchema.index({ assignedTo: 1, status: 1 });
// Admin view: all tasks sorted by creation date
taskSchema.index({ createdAt: -1 });
// Overdue job: tasks past their due date with active statuses
taskSchema.index({ dueDate: 1, status: 1 });
// Parent task lookups
taskSchema.index({ parentTaskId: 1 });

// ✅ FIX 6.1: Cap history to 500 items to prevent unbounded growth (DoS protection)
// ✅ FIX 6.2: Circular dependency detection (pre-save validation)
taskSchema.pre('save', async function (next) {
  // CAP HISTORY: If history exceeds 500 items, remove oldest entries
  if (this.history && this.history.length > 500) {
    const excessCount = this.history.length - 500;
    this.history.splice(0, excessCount);
  }

  // Only validate dependencies if dependsOn was modified
  if (!this.isModified('dependsOn') || !this.dependsOn || this.dependsOn.length === 0) {
    return next();
  }

  const visited = new Set();
  const checkCircular = async (taskId) => {
    const taskIdStr = taskId.toString();
    
    // If we've already visited this task in our traversal, we have a cycle
    if (visited.has(taskIdStr)) {
      throw new Error(`❌ Circular dependency detected: Task would create a dependency cycle`);
    }
    visited.add(taskIdStr);

    // Find this task and check its dependencies
    const depTask = await mongoose.model('Task').findById(taskId).select('dependsOn');
    if (!depTask) return; // Task doesn't exist, will be caught elsewhere

    // Recursively check all dependencies
    for (const nestedDepId of (depTask.dependsOn || [])) {
      await checkCircular(nestedDepId);
    }
  };

  try {
    // Start checking from each dependency of this task
    for (const depId of this.dependsOn) {
      await checkCircular(depId);
    }
    next();
  } catch (err) {
    next(err);
  }
});

module.exports = mongoose.model('Task', taskSchema);