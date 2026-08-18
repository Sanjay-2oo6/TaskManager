const jwt = require('jsonwebtoken');

const protect = async (req, res, next) => {
  // ✅ FIX: Skip auth check for preflight OPTIONS requests
  if (req.method === 'OPTIONS') {
    return next();
  }

  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // ✅ SECURITY FIX: Verify organization still exists and is active
      if (decoded.organizationId) {
        const Organization = require('../models/Organization');
        const org = await Organization.findById(decoded.organizationId);
        
        // Organization deleted or deactivated - invalidate token
        if (!org || !org.isActive) {
          return res.status(401).json({
            success: false,
            data: null,
            message: 'Organization is not active or has been deleted',
          });
        }
      }
      
      // ✅ SECURITY FIX: Verify user still exists and is active in organization
      const User = require('../models/User');
      const user = await User.findById(decoded.id);
      
      if (!user) {
        return res.status(401).json({
          success: false,
          data: null,
          message: 'User account has been deleted',
        });
      }
      
      req.user = {
        id: decoded.id,
        role: decoded.role,
        organizationId: decoded.organizationId,
      };
      return next();
    } catch (error) {
      return res.status(401).json({
        success: false,
        data: null,
        message: 'Not authorized, token failed',
      });
    }
  }

  return res.status(401).json({
    success: false,
    data: null,
    message: 'Not authorized, no token provided',
  });
};

const authorize = (...args) => {
  // Accept both authorize(['admin','admin']) and authorize('admin', 'admin')
  const roles = Array.isArray(args[0]) ? args[0] : args;
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        data: null,
        message: 'Forbidden: insufficient permissions',
      });
    }
    next();
  };
};

module.exports = { protect, authorize };
