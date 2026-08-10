const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema({
  task: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Task',
    required: true
  },
  employee: {
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
  taskTitle: {
    type: String,
    required: true
  },
  employeeName: {
    type: String,
    required: true
  },
  beforeImage: {
    type: String, // Legacy S3 URL
    required: false
  },
  afterImage: {
    type: String, // Legacy S3 URL
    required: false
  },
  beforeFiles: [{
    type: String
  }],
  beforeFileNames: [{
    type: String
  }],
  afterFiles: [{
    type: String
  }],
  afterFileNames: [{
    type: String
  }],
  description: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  adminFeedback: {
    type: String,
    trim: true
  },
  comments: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    text: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
  }]
}, { timestamps: true });

module.exports = mongoose.model('Submission', submissionSchema);
