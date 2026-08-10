const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,                    // ✅ Global unique constraint
      lowercase: true,                 // ✅ Auto-lowercase for consistency
      trim: true,                      // ✅ Auto-trim whitespace
      match: [
        /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
        'Please provide a valid email address'
      ],                               // ✅ Email format validation
      sparse: true,                    // ✅ Allows null values during migration
    },
    username: {
      type: String,
      // DEPRECATED: Username no longer used for login (email replaces it)
      // Kept for backward compatibility and display purposes only
      lowercase: true,
      trim: true,
      default: null,
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: 6,
      select: false,
    },
    role: {
      type: String,
      enum: ['member', 'admin', 'super_admin'],
      default: 'member',
    },
    organizationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      default: null,
      // Super admin has null organizationId
      // Admin and member must have organizationId
    },
    fcmToken: {
      type: String,
      default: null,
    },
    lastLoginTimestamp: {
      type: Date,
      default: null,
    },
    emailVerified: {
      type: Boolean,
      default: false,                  // ✅ For future email verification feature
    },

  },
  {
    timestamps: true,
  }
);

// Indexes
userSchema.index({ email: 1 });                           // ✅ Email lookup for login
userSchema.index({ organizationId: 1 });
userSchema.index({ role: 1 });
userSchema.index({ organizationId: 1, role: 1 });
userSchema.index({ organizationId: 1, email: 1 });      // ✅ Org-specific email lookup

// Validation: Admin and member must have organizationId
userSchema.pre('save', function(next) {
  if (this.role !== 'super_admin' && !this.organizationId) {
    return next(new Error('Admin and member users must have an organizationId'));
  }
  if (this.role === 'super_admin' && this.organizationId) {
    return next(new Error('Super admin cannot have an organizationId'));
  }
  next();
});

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  return bcrypt.compare(enteredPassword, this.password);
};

userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
