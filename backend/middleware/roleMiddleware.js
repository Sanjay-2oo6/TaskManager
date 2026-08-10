/**
 * @desc    Middleware to authorize certain user roles
 * @param   {string|string[]} roles - Array of roles (or spread args) allowed to access the route
 */
exports.authorize = (...args) => {
  // Accept both authorize(['admin','assigner']) and authorize('admin','assigner')
  const roles = Array.isArray(args[0]) ? args[0] : args;
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Role '${req.user ? req.user.role : 'none'}' is not authorized for this route`,
      });
    }
    next();
  };
};
