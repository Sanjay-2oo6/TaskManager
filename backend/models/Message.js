const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  taskId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task',
    required: true,
    index: true
  },
  sender: {
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
  text: {
    type: String,
    required: true,
    trim: true
  },
  readBy: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    readAt: { type: Date, default: Date.now }
  }],
  isSystem: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Index for fast history loading
messageSchema.index({ taskId: 1, createdAt: 1 });
// Fast unread count aggregation
messageSchema.index({ taskId: 1, sender: 1, 'readBy.user': 1 });

module.exports = mongoose.model('Message', messageSchema);
