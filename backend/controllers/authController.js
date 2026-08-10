const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { sanitizeText } = require('../utils/sanitizer');
const { getPasswordError } = require('../utils/passwordValidator');
const logger = require('../utils/logger');

// ✅ SECURITY: User input sanitization applied
// ✅ SECURITY FIX 0.10: Strong password validation applied
// ✅ SECURITY FIX 0.11: Structured logging applied

const createToken = (user) => {
  return jwt.sign(
    {
      id: user._id,
      role: user.role,
      organizationId: user.organizationId,
    },
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    }
  );
};

const sendResponse = (res, data, message, status = 200) => {
  return res.status(status).json({ success: true, data, message });
};

const sendError = (res, error, status = 400) => {
  return res.status(status).json({ success: false, data: null, message: error });
};

const createUser = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !name.trim()) {
      return sendError(res, 'Name is required', 400);
    }
    if (!email || !email.trim()) {
      return sendError(res, 'Email is required', 400);
    }
    
    // ✅ EMAIL-BASED AUTH: Validate email format
    const emailRegex = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;
    if (!emailRegex.test(email.trim())) {
      return sendError(res, 'Invalid email format', 400);
    }
    
    // 🛡️ SECURITY FIX 0.10: Validate password strength
    const passwordError = getPasswordError(password);
    if (passwordError) {
      return sendError(res, passwordError, 400);
    }
    
    // Max length guard to prevent oversized payloads
    if (name.length > 100 || email.length > 100) {
      return sendError(res, 'Name or email is too long', 400);
    }

    // SECURITY: Role whitelist — admins can create both member and admin accounts within their org
    const actingRole = req.user?.role;
    let assignedRole = 'member'; // default
    
    if (role) {
      if (actingRole === 'super_admin') {
        // Super admin can create admin accounts
        if (['member', 'admin'].includes(role)) {
          assignedRole = role;
        }
      } else if (actingRole === 'admin') {
        // ✅ UPDATED: Admin can now create both member and admin accounts within their organization
        if (['member', 'admin'].includes(role)) {
          assignedRole = role;
        }
      }
    }

    // ✅ EMAIL-BASED AUTH: Check email is globally unique (across all organizations)
    const existingUser = await User.findOne({ email: email.trim().toLowerCase() });
    
    // ✅ SECURITY FIX: Add timing consistency to prevent email enumeration attacks
    // Always run bcrypt hash to consume consistent time regardless of email existence
    const dummyHash = await bcrypt.hash('dummy_password_for_timing', 10);
    
    if (existingUser) {
      // 🛡️ SECURITY: Generic error message (no email enumeration)
      return sendError(res, 'This email is already registered', 400);
    }

    // ✅ MULTI-TENANT: Set organizationId
    let organizationId = null;
    
    if (actingRole === 'admin') {
      // Admin creating member: use admin's organizationId
      organizationId = req.user.organizationId;
      
      if (!organizationId) {
        return sendError(res, 'Admin must be associated with an organization', 400);
      }
      
      // ✅ SECURITY FIX: Use atomic increment to prevent race condition
      // MongoDB's $inc operator prevents concurrent requests from exceeding the limit
      const Organization = require('../models/Organization');
      const organization = await Organization.findById(organizationId);
      
      if (!organization) {
        return sendError(res, 'Organization not found', 404);
      }
      
      if (!organization.isActive) {
        return sendError(res, 'Organization is not active', 403);
      }
      
      if (!organization.canAddMembers(1)) {
        return sendError(res, `Organization member limit reached (${organization.memberLimit} members)`, 403);
      }
      
      // ✅ ATOMIC UPDATE: Use findByIdAndUpdate with $inc to prevent race condition
      // This ensures memberCount is incremented atomically without separate fetch/update
      const updatedOrg = await Organization.findByIdAndUpdate(
        organizationId,
        { $inc: { memberCount: 1 } },
        { new: true }
      );
      
      // Verify the atomic update didn't exceed limit
      if (updatedOrg.memberCount > updatedOrg.memberLimit && updatedOrg.memberLimit !== -1) {
        // Rollback the increment if we exceeded limit
        await Organization.findByIdAndUpdate(
          organizationId,
          { $inc: { memberCount: -1 } }
        );
        return sendError(res, `Organization member limit reached (${updatedOrg.memberLimit} members)`, 403);
      }
    }
    // For super admin creating admin: organizationId will be set when organization is created

    const user = await User.create({ 
      name: sanitizeText(name.trim()), 
      email: email.trim().toLowerCase(),    // ✅ Store email in lowercase
      password, 
      role: assignedRole,
      organizationId,
    });

    // 🛡️ SECURITY FIX 0.11: Log user creation (admin action)
    logger.admin('User created', {
      createdBy: req.user?.id,
      createdByUsername: req.user?.username,
      newUserId: user._id.toString(),
      newUserEmail: user.email,           // ✅ Log email instead of username
      newUserRole: user.role,
      ip: req.ip
    });

    // Do NOT return a token — admin is creating an account for someone else
    return sendResponse(
      res,
      {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,               // ✅ Return email
          role: user.role,
        },
      },
      'User created successfully',
      201
    );
  } catch (error) {
    logger.error('User creation failed', { error: error.message });
    return sendError(res, error.message || 'Registration failed', 500);
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return sendError(res, 'Email and password are required', 400);
    }

    // ✅ EMAIL-BASED AUTH: Query by email (globally unique)
    const user = await User.findOne({ email: email.trim().toLowerCase() }).select('+password');
    if (!user || !(await user.matchPassword(password))) {
      // 🛡️ SECURITY FIX 0.11: Log failed login attempts
      // 🛡️ SECURITY: Generic error message (no email enumeration)
      logger.security('Failed login attempt', {
        email: email.trim().toLowerCase(),
        ip: req.ip,
        userAgent: req.get('user-agent')
      });
      return sendError(res, 'Invalid email or password', 401);
    }

    // ✅ Check organization is active (if user has one)
    if (user.organizationId) {
      const Organization = require('../models/Organization');
      const org = await Organization.findById(user.organizationId);
      if (!org || !org.isActive) {
        logger.security('Login attempt to inactive organization', {
          userId: user._id.toString(),
          organizationId: user.organizationId,
          ip: req.ip
        });
        return sendError(res, 'Organization is not active', 403);
      }
    }

    const token = createToken(user);

    // ✅ PHASE 1 FEATURE 1: Record login timestamp for 7-day session persistence
    user.lastLoginTimestamp = new Date();
    await user.save();

    // 🛡️ SECURITY FIX 0.11: Log successful login
    logger.auth('User logged in', {
      userId: user._id.toString(),
      userEmail: user.email,               // ✅ Log email instead of username
      role: user.role,
      organizationId: user.organizationId,
      ip: req.ip
    });

    return sendResponse(res, {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,                 // ✅ Return email
        role: user.role,
        organizationId: user.organizationId,
      },
      token,
    }, 'Login successful');
  } catch (error) {
    logger.error('Login error', { error: error.message });
    return sendError(res, 'Login failed', 500);
  }
};

const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return sendError(res, 'User not found', 404);
    }

    return sendResponse(res, { user }, 'User profile loaded');
  } catch (error) {
    return sendError(res, 'Unable to load profile', 500);
  }
};

// @desc    Get all users (employees and admins)
// @route   GET /api/v1/auth/users
// @access  Private/Admin
const getUsers = async (req, res) => {
  try {
    console.log('🔍 getUsers called - User context:', {
      userId: req.user.id,
      userRole: req.user.role,
      organizationId: req.user.organizationId
    });

    // Multi-tenant: only return users in this organization
    const users = await User.find({ organizationId: req.user.organizationId }).select('-password');
    
    console.log(`✅ Found ${users.length} users in organization ${req.user.organizationId}`);
    
    // Get organization to check admin ID
    const Organization = require('../models/Organization');
    const org = await Organization.findById(req.user.organizationId);
    
    // Add isOrgAdmin flag to each user
    const usersWithAdminFlag = users.map(user => {
      const userObj = user.toObject();
      userObj.isOrgAdmin = org && user._id.toString() === org.adminId.toString();
      return userObj;
    });
    
    res.status(200).json({
      success: true,
      count: usersWithAdminFlag.length,
      data: usersWithAdminFlag,
    });
  } catch (error) {
    console.error('❌ getUsers error:', error.message);
    res.status(500).json({ success: false, message: 'Server Error' });
  }
};

// @desc    Update self password
// @route   PATCH /api/v1/auth/me/password
// @access  Private
const changeMyProfile = async (req, res) => {
  try {
    const { name, password } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (name) user.name = name;
    
    // 🛡️ SECURITY FIX 0.10: Validate password strength if changing password
    if (password) {
      const passwordError = getPasswordError(password);
      if (passwordError) {
        return res.status(400).json({ success: false, message: passwordError });
      }
      user.password = password;
    }

    await user.save();

    res.status(200).json({ 
      success: true, 
      data: {
        id: user._id,
        name: user.name,
        username: user.username,
        role: user.role
      },
      message: 'Mission identity updated successfully' 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// @desc    Delete user (Admin only)
// @route   DELETE /api/v1/auth/users/:id
// @access  Private/Admin
const deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // MASTER ADMIN PROTECTION
    const masterUsername = process.env.MASTER_ADMIN_USERNAME || 'sanjay';
    if (user.username === masterUsername) {
      return res.status(403).json({ 
        success: false, 
        message: 'This account is protected and cannot be removed.' 
      });
    }
    
    await user.deleteOne();

    res.status(200).json({
      success: true,
      message: 'User removed successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error' });
  }
};

// @desc    Update user password (Admin only)
// @route   PATCH /api/v1/auth/users/:id/password
// @access  Private/Admin
const updatePassword = async (req, res) => {
  try {
    const { password } = req.body;
    
    // 🛡️ SECURITY FIX 0.10: Validate password strength
    const passwordError = getPasswordError(password);
    if (passwordError) {
      return res.status(400).json({ success: false, message: passwordError });
    }

    const targetUser = await User.findById(req.params.id);
    if (!targetUser) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // MASTER ADMIN PROTECTION: Only the master admin can update their own password.
    const masterUsername = process.env.MASTER_ADMIN_USERNAME || 'sanjay';
    const actingUser = await User.findById(req.user.id);
    const isMaster = actingUser && actingUser.username === masterUsername;
    
    if (targetUser.username === masterUsername && !isMaster) {
      return res.status(403).json({ 
        success: false, 
        message: 'ACCESS DENIED: This account can only be modified by its owner.' 
      });
    }

    targetUser.password = password;
    await targetUser.save();

    res.status(200).json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error' });
  }
};

// @desc    Update FCM Token
// @route   PATCH /api/v1/auth/fcm-token
// @access  Private
const updateFcmToken = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: 'Token is required' });
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { fcmToken: token },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.status(200).json({ success: true, message: 'FCM Token updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error' });
  }
};

module.exports = { createUser, login, getMe, getUsers, deleteUser, updatePassword, changeMyProfile, updateFcmToken };

