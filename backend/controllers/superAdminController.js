/**
 * Super Admin Controller
 * 
 * Handles organization management for super admin users.
 * Super admin can:
 * - Create organizations
 * - Create admin accounts for organizations
 * - Manage organization settings
 * - View platform statistics
 * 
 * Super admin CANNOT:
 * - Access organization data (tasks, members, messages)
 */

const mongoose = require('mongoose');
const Organization = require('../models/Organization');
const User = require('../models/User');
const Task = require('../models/Task');
const Submission = require('../models/Submission');
const { sanitizeText } = require('../utils/sanitizer');
const { getPasswordError } = require('../utils/passwordValidator');
const logger = require('../utils/logger');

/**
 * @desc    Create a new organization
 * @route   POST /api/v1/super-admin/organizations
 * @access  Private/Super Admin
 */
const createOrganization = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();
  
  try {
    const { name, slug, memberLimit, adminName, adminEmail, adminPassword } = req.body;
    
    // Validation
    if (!name || !slug) {
      await session.abortTransaction();
      return res.status(400).json({ success: false, message: 'Organization name and slug are required' });
    }
    
    if (!adminName || !adminEmail || !adminPassword) {
      await session.abortTransaction();
      return res.status(400).json({ success: false, message: 'Admin details (name, email, password) are required' });
    }
    
    // Validate password strength
    const passwordError = getPasswordError(adminPassword);
    if (passwordError) {
      await session.abortTransaction();
      return res.status(400).json({ success: false, message: passwordError });
    }
    
    // Check if slug already exists
    const existingOrg = await Organization.findOne({ slug: slug.toLowerCase().trim() }).session(session);
    if (existingOrg) {
      await session.abortTransaction();
      return res.status(400).json({ success: false, message: 'Organization slug already exists' });
    }
    
    // Check if admin email already exists
    const existingUser = await User.findOne({ email: adminEmail.toLowerCase().trim() }).session(session);
    if (existingUser) {
      await session.abortTransaction();
      return res.status(400).json({ success: false, message: 'Admin email already exists' });
    }
    
    // ✅ SECURITY FIX: Use transaction for atomicity
    const tempOrgId = new mongoose.Types.ObjectId();
    
    const admin = await User.create([{
      name: sanitizeText(adminName.trim()),
      email: sanitizeText(adminEmail.toLowerCase().trim()),
      password: adminPassword,
      role: 'admin',
      organizationId: tempOrgId,
    }], { session });
    
    const organization = await Organization.create([{
      name: sanitizeText(name.trim()),
      slug: slug.toLowerCase().trim(),
      adminId: admin[0]._id,
      memberLimit: memberLimit || 10,
      memberCount: 1,
      createdBy: req.user.id,
    }], { session });
    
    admin[0].organizationId = organization[0]._id;
    await admin[0].save({ session });
    
    await session.commitTransaction();
    
    logger.admin('Organization created', {
      superAdminId: req.user.id,
      organizationId: organization[0]._id,
      organizationSlug: organization[0].slug,
      adminId: admin[0]._id,
      adminEmail: admin[0].email,
    });
    
    // ✅ SECURITY: Don't expose admin password hash in response
    const adminSafe = admin[0].toObject();
    delete adminSafe.password;  // Remove password hash before sending to client
    
    res.status(201).json({
      success: true,
      data: {
        organization: organization[0],
        admin: adminSafe,  // ✅ Password removed
      },
      message: 'Organization created successfully',
    });
  } catch (error) {
    await session.abortTransaction();
    res.status(500).json({ success: false, message: error.message });
  } finally {
    await session.endSession();
  }
};

/**
 * @desc    Get all organizations
 * @route   GET /api/v1/super-admin/organizations
 * @access  Private/Super Admin
 */
const getAllOrganizations = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, isActive, sortBy = 'createdAt', order = 'desc' } = req.query;
    
    // Build filter
    const filter = {};
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { slug: { $regex: search, $options: 'i' } },
      ];
    }
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }
    
    // Build sort
    const sort = {};
    sort[sortBy] = order === 'desc' ? -1 : 1;
    
    // Pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    // Query
    const [organizations, totalCount] = await Promise.all([
      Organization.find(filter)
        .populate('adminId', 'name username email')  // ✅ Include email
        .populate('createdBy', 'name username')
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Organization.countDocuments(filter),
    ]);
    
    res.json({
      success: true,
      data: organizations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(totalCount / parseInt(limit)),
        totalCount,
      },
    });
    
  } catch (error) {
    logger.error('Get organizations error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    Get single organization details
 * @route   GET /api/v1/super-admin/organizations/:id
 * @access  Private/Super Admin
 */
const getOrganization = async (req, res) => {
  try {
    const organization = await Organization.findById(req.params.id)
      .populate('adminId', 'name username createdAt')
      .populate('createdBy', 'name username');
    
    if (!organization) {
      return res.status(404).json({ success: false, message: 'Organization not found' });
    }
    
    // Get member count (actual count from User model)
    const actualMemberCount = await User.countDocuments({ 
      organizationId: organization._id,
      role: { $in: ['member', 'admin'] },
    });
    
    // Sync if different
    if (actualMemberCount !== organization.memberCount) {
      organization.memberCount = actualMemberCount;
      await organization.save();
    }
    
    res.json({
      success: true,
      data: {
        ...organization.toJSON(),
        actualMemberCount,
      },
    });
    
  } catch (error) {
    logger.error('Get organization error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    Update organization
 * @route   PATCH /api/v1/super-admin/organizations/:id
 * @access  Private/Super Admin
 */
const updateOrganization = async (req, res) => {
  try {
    const { name, memberLimit, logo, banner, welcomeMessage, themeColor } = req.body;
    
    const organization = await Organization.findById(req.params.id);
    if (!organization) {
      return res.status(404).json({ success: false, message: 'Organization not found' });
    }
    
    // Prevent updating ITH organization's critical fields
    if (organization.isSpecial && organization.slug === 'ith') {
      // Only allow branding updates for ITH
      if (memberLimit !== undefined) {
        return res.status(403).json({ success: false, message: 'Cannot change member limit for ITH organization' });
      }
    }
    
    // Update allowed fields
    if (name) organization.name = sanitizeText(name.trim());
    if (memberLimit !== undefined) organization.memberLimit = memberLimit;
    if (logo !== undefined) organization.logo = logo;
    if (banner !== undefined) organization.banner = banner;
    if (welcomeMessage) organization.welcomeMessage = sanitizeText(welcomeMessage.trim());
    if (themeColor) organization.themeColor = themeColor;
    
    await organization.save();
    
    logger.admin('Organization updated', {
      superAdminId: req.user.id,
      organizationId: organization._id,
      updates: Object.keys(req.body),
    });
    
    res.json({
      success: true,
      data: organization,
      message: 'Organization updated successfully',
    });
    
  } catch (error) {
    logger.error('Update organization error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    Delete organization
 * @route   DELETE /api/v1/super-admin/organizations/:id
 * @access  Private/Super Admin
 */
const deleteOrganization = async (req, res) => {
  try {
    const organization = await Organization.findById(req.params.id);
    if (!organization) {
      return res.status(404).json({ success: false, message: 'Organization not found' });
    }
    
    // Prevent deletion of ITH organization
    if (organization.isSpecial && organization.slug === 'ith') {
      return res.status(403).json({ success: false, message: 'Cannot delete ITH organization' });
    }
    
    // Delete all associated data
    await Promise.all([
      User.deleteMany({ organizationId: organization._id }),
      Task.deleteMany({ organizationId: organization._id }),
      Submission.deleteMany({ organizationId: organization._id }),
      // Add more models as needed
    ]);
    
    await organization.deleteOne();
    
    logger.admin('Organization deleted', {
      superAdminId: req.user.id,
      organizationId: organization._id,
      organizationSlug: organization.slug,
    });
    
    res.json({
      success: true,
      message: 'Organization and all associated data deleted successfully',
    });
    
  } catch (error) {
    logger.error('Delete organization error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    Toggle organization active status
 * @route   POST /api/v1/super-admin/organizations/:id/toggle
 * @access  Private/Super Admin
 */
const toggleOrganizationStatus = async (req, res) => {
  try {
    const organization = await Organization.findById(req.params.id);
    if (!organization) {
      return res.status(404).json({ success: false, message: 'Organization not found' });
    }
    
    // Prevent deactivating ITH organization
    if (organization.isSpecial && organization.slug === 'ith') {
      return res.status(403).json({ success: false, message: 'Cannot deactivate ITH organization' });
    }
    
    organization.isActive = !organization.isActive;
    await organization.save();
    
    logger.admin('Organization status toggled', {
      superAdminId: req.user.id,
      organizationId: organization._id,
      newStatus: organization.isActive,
    });
    
    res.json({
      success: true,
      data: organization,
      message: `Organization ${organization.isActive ? 'activated' : 'deactivated'} successfully`,
    });
    
  } catch (error) {
    logger.error('Toggle organization status error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * @desc    Get platform statistics
 * @route   GET /api/v1/super-admin/stats
 * @access  Private/Super Admin
 */
const getPlatformStats = async (req, res) => {
  try {
    const [
      totalOrganizations,
      activeOrganizations,
      totalUsers,
      totalAdmins,
      totalMembers,
      totalTasks,
      totalSubmissions,
    ] = await Promise.all([
      Organization.countDocuments(),
      Organization.countDocuments({ isActive: true }),
      User.countDocuments(),
      User.countDocuments({ role: 'admin' }),
      User.countDocuments({ role: 'member' }),
      Task.countDocuments(),
      Submission.countDocuments(),
    ]);
    
    // Recent organizations (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const recentOrganizations = await Organization.countDocuments({
      createdAt: { $gte: sevenDaysAgo },
    });
    
    res.json({
      success: true,
      data: {
        organizations: {
          total: totalOrganizations,
          active: activeOrganizations,
          inactive: totalOrganizations - activeOrganizations,
          recentlyCreated: recentOrganizations,
        },
        users: {
          total: totalUsers,
          admins: totalAdmins,
          members: totalMembers,
          superAdmins: 1, // Assuming one super admin (you)
        },
        platform: {
          totalTasks,
          totalSubmissions,
          averageTasksPerOrg: totalOrganizations > 0 ? Math.round(totalTasks / totalOrganizations) : 0,
          averageUsersPerOrg: totalOrganizations > 0 ? Math.round(totalUsers / totalOrganizations) : 0,
        },
        timestamp: new Date(),
      },
    });
    
  } catch (error) {
    logger.error('Get platform stats error', { error: error.message });
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  createOrganization,
  getAllOrganizations,
  getOrganization,
  updateOrganization,
  deleteOrganization,
  toggleOrganizationStatus,
  getPlatformStats,
};
