/**
 * Organization Model
 * 
 * Represents a tenant organization in the multi-tenant system.
 * Each organization has its own admin and members.
 */

const mongoose = require('mongoose');

const organizationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Organization name is required'],
      trim: true,
      maxlength: [100, 'Organization name cannot exceed 100 characters'],
    },
    
    slug: {
      type: String,
      required: [true, 'Organization slug is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^[a-z0-9-]+$/, 'Slug can only contain lowercase letters, numbers, and hyphens'],
      maxlength: [50, 'Slug cannot exceed 50 characters'],
    },
    
    adminId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Organization must have an admin'],
    },
    
    memberLimit: {
      type: Number,
      required: true,
      default: 10,
      validate: {
        validator: function(value) {
          // Allow -1 for unlimited, otherwise must be >= 1
          return value === -1 || value >= 1;
        },
        message: 'Member limit must be -1 (unlimited) or at least 1',
      },
    },
    
    memberCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    
    isActive: {
      type: Boolean,
      default: true,
    },
    
    logo: {
      type: String,
      default: null,
      // S3 URL for organization logo
    },
    
    banner: {
      type: String,
      default: null,
      // S3 URL for organization banner
    },
    
    welcomeMessage: {
      type: String,
      default: 'Welcome to our organization!',
      maxlength: [500, 'Welcome message cannot exceed 500 characters'],
    },
    
    themeColor: {
      type: String,
      default: '#FF6B6B',
      match: [/^#[0-9A-Fa-f]{6}$/, 'Theme color must be a valid hex color'],
    },
    
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Creator (super admin) is required'],
    },
    
    // ITH organization special flag
    isSpecial: {
      type: Boolean,
      default: false,
      // ITH organization: always active, unlimited members, cannot be deleted
    },
    
    // Subscription/billing info (for future use)
    subscriptionTier: {
      type: String,
      enum: ['free', 'starter', 'professional', 'enterprise', 'custom'],
      default: 'free',
    },
    
    subscriptionExpiresAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
organizationSchema.index({ slug: 1 });
organizationSchema.index({ adminId: 1 });
organizationSchema.index({ isActive: 1 });
organizationSchema.index({ createdBy: 1 });

// Virtual for checking if unlimited members
organizationSchema.virtual('hasUnlimitedMembers').get(function() {
  return this.memberLimit === -1;
});

// Virtual for checking if limit reached
organizationSchema.virtual('isAtCapacity').get(function() {
  if (this.memberLimit === -1) return false; // Unlimited
  return this.memberCount >= this.memberLimit;
});

// Virtual for available slots
organizationSchema.virtual('availableSlots').get(function() {
  if (this.memberLimit === -1) return Infinity;
  return Math.max(0, this.memberLimit - this.memberCount);
});

// Method to check if can add more members
organizationSchema.methods.canAddMembers = function(count = 1) {
  if (this.memberLimit === -1) return true; // Unlimited
  return (this.memberCount + count) <= this.memberLimit;
};

// Method to increment member count
organizationSchema.methods.incrementMemberCount = async function(count = 1) {
  if (!this.canAddMembers(count)) {
    throw new Error('Organization member limit reached');
  }
  this.memberCount += count;
  await this.save();
};

// Method to decrement member count
organizationSchema.methods.decrementMemberCount = async function(count = 1) {
  this.memberCount = Math.max(0, this.memberCount - count);
  await this.save();
};

// Pre-save hook: Validate special organizations
organizationSchema.pre('save', function(next) {
  // ITH organization must always be active and unlimited
  if (this.isSpecial && this.slug === 'ith') {
    this.isActive = true;
    this.memberLimit = -1;
  }
  next();
});

// Pre-remove hook: Prevent deletion of special organizations
organizationSchema.pre('deleteOne', { document: true, query: false }, function(next) {
  if (this.isSpecial) {
    return next(new Error('Cannot delete special organization (ITH)'));
  }
  next();
});

// Static method to get ITH organization
organizationSchema.statics.getITH = async function() {
  return await this.findOne({ slug: 'ith', isSpecial: true });
};

// Static method to create ITH organization
organizationSchema.statics.createITH = async function(superAdminId) {
  const existing = await this.getITH();
  if (existing) return existing;
  
  return await this.create({
    name: 'INNO TECH HUB',
    slug: 'ith',
    adminId: superAdminId,
    memberLimit: -1, // Unlimited
    isActive: true,
    isSpecial: true,
    welcomeMessage: 'Welcome to INNO TECH HUB - Where Innovation Meets Excellence!',
    themeColor: '#FF6B6B',
    createdBy: superAdminId,
    subscriptionTier: 'custom',
  });
};

// JSON transformation: Include virtuals
organizationSchema.set('toJSON', { 
  virtuals: true,
  transform: function(doc, ret) {
    delete ret.__v;
    return ret;
  }
});

organizationSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Organization', organizationSchema);
