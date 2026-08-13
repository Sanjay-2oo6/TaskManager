const Joi = require('joi');

/**
 * VALIDATION MIDDLEWARE - Request Data Validation
 * 
 * Purpose: Validate all incoming request data against schemas
 * - Prevents malformed/malicious requests from reaching controllers
 * - Prevents crashes from unexpected data types or lengths
 * - Protects against injection attacks and DoS
 * 
 * How it works:
 * - Each endpoint has a Joi schema that defines allowed data
 * - Middleware checks incoming data against schema
 * - If data is invalid, returns 400 (Bad Request) error
 * - If data is valid, passes to controller
 */

// ============================================
// COMMON VALIDATION SCHEMAS
// ============================================

const commonSchemas = {
  // Standard object ID
  objectId: Joi.string()
    .regex(/^[0-9a-fA-F]{24}$/)
    .messages({
      'string.pattern.base': 'Invalid ID format'
    }),

  // Email validation
  email: Joi.string()
    .email()
    .lowercase()
    .trim()
    .max(255)
    .messages({
      'string.email': 'Must be a valid email address'
    }),

  // Strong password (8+ chars, uppercase, lowercase, number, special)
  strongPassword: Joi.string()
    .min(8)
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/)
    .messages({
      'string.min': 'Password must be at least 8 characters',
      'string.pattern.base': 'Password must include uppercase, lowercase, number, and special character (@$!%*?&)'
    }),

  // Username (3-20 alphanumeric + underscore)
  username: Joi.string()
    .alphanum()
    .min(3)
    .max(20)
    .messages({
      'string.alphanum': 'Username can only contain letters and numbers',
      'string.min': 'Username must be at least 3 characters',
      'string.max': 'Username cannot exceed 20 characters'
    }),

  // Generic text field
  text: Joi.string()
    .trim()
    .max(5000),

  // Short text (title-like)
  shortText: Joi.string()
    .trim()
    .max(255)
};

// ============================================
// AUTH ENDPOINTS VALIDATION
// ============================================

const validationSchemas = {
  // POST /auth/login
  login: Joi.object({
    email: commonSchemas.email.required(),
    password: Joi.string().required()
  }).unknown(false),

  // POST /auth/users (create user)
  createUser: Joi.object({
    name: Joi.string()
      .trim()
      .max(100)
      .required()
      .messages({
        'string.max': 'Name cannot exceed 100 characters'
      }),
    email: commonSchemas.email.required(),
    password: commonSchemas.strongPassword.required(),
    role: Joi.string()
      .valid('member', 'admin', 'super_admin')
      .optional()  // ✅ Role defaults to 'member' in controller
      .messages({
        'any.only': 'Role must be: member, admin, or super_admin'
      })
  }).unknown(false),

  // PATCH /auth/me/profile (update own profile)
  updateProfile: Joi.object({
    name: Joi.string()
      .trim()
      .max(100)
      .messages({
        'string.max': 'Name cannot exceed 100 characters'
      }),
    email: commonSchemas.email,
    password: commonSchemas.strongPassword,
    profilePicture: Joi.string()
      .uri()
      .max(2000)
      .messages({
        'string.uri': 'Profile picture must be a valid URL'
      }),
    phone: Joi.string()
      .regex(/^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,9}$/)
      .max(20)
      .messages({
        'string.pattern.base': 'Invalid phone number format'
      })
  }).unknown(false).min(1),

  // PATCH /auth/users/:id/password (change password)
  updatePassword: Joi.object({
    password: commonSchemas.strongPassword.required()
  }).unknown(false),

  // PATCH /fcm-token
  updateFcmToken: Joi.object({
    token: Joi.string()
      .trim()
      .required()
      .messages({
        'string.empty': 'FCM token is required'
      })
  }).unknown(false)
};

// ============================================
// TASK ENDPOINTS VALIDATION
// ============================================

Object.assign(validationSchemas, {
  // POST /tasks (create task)
  createTask: Joi.object({
    title: commonSchemas.shortText
      .required()
      .messages({
        'string.empty': 'Task title is required'
      }),
    description: Joi.string().trim().max(5000).allow('', null).optional(),
    assignedTo: Joi.alternatives().try(
      Joi.array().items(commonSchemas.objectId),
      Joi.string()
    ).required(),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'extreme')
      .default('medium')
      .messages({
        'any.only': 'Priority must be: low, medium, high, or extreme'
      }),
    dueDate: Joi.date()
      .required()
      .messages({
        'date.base': 'Due date must be a valid date'
      }),
    adminNote: commonSchemas.text.allow('', null),
    adminNotes: commonSchemas.text.allow('', null),
    // Sequential pipeline fields
    parentTaskId: Joi.string().allow('', null),
    dependsOn: Joi.alternatives().try(
      Joi.array().items(commonSchemas.objectId),
      Joi.string().allow('', null)
    ),
    // File fields (multer adds these)
    adminFiles: Joi.any(),
    adminFileNames: Joi.any()
  }).unknown(true).min(1),

  // PUT /tasks/:id (update task)
  updateTask: Joi.object({
    title: commonSchemas.shortText,
    description: commonSchemas.text.allow('', null),
    assignedTo: Joi.alternatives().try(
      Joi.array().items(commonSchemas.objectId),
      Joi.string()
    ),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'extreme'),
    dueDate: Joi.date(),
    status: Joi.string()
      .valid('pending', 'in-progress', 'submitted', 'completed', 'rejected', 'waiting'),
    adminNotes: commonSchemas.text.allow('', null),
    adminNote: commonSchemas.text.allow('', null),
    notes: commonSchemas.text.allow('', null),
    // Sequential pipeline fields
    parentTaskId: Joi.string().allow('', null),
    dependsOn: Joi.alternatives().try(
      Joi.array().items(commonSchemas.objectId),
      Joi.string().allow('', null)
    ),
    // File fields
    adminFiles: Joi.any(),
    adminFileNames: Joi.any()
  }).unknown(true).min(1),

  // PUT /tasks/:id/assign (assign task)
  assignTask: Joi.object({
    assignedTo: Joi.array()
      .items(commonSchemas.objectId)
      .required()
      .messages({
        'array.empty': 'Must assign to at least one employee'
      })
  }).unknown(false),

  // POST /tasks/:id/comments (add comment)
  addComment: Joi.object({
    text: Joi.string()
      .trim()
      .min(1)
      .max(2000)
      .required()
      .messages({
        'string.empty': 'Comment cannot be empty',
        'string.max': 'Comment cannot exceed 2000 characters'
      })
  }).unknown(false)
});

// ============================================
// SUBMISSION ENDPOINTS VALIDATION
// ============================================

Object.assign(validationSchemas, {
  // POST /submissions (create submission)
  createSubmission: Joi.object({
    taskId: commonSchemas.objectId.required(),
    description: commonSchemas.text.allow('', null).optional(),
    status: Joi.string()
      .valid('pending', 'approved', 'rejected')
      .default('pending')
  }).unknown(false),

  // PATCH /submissions/:id/status (approve/reject)
  updateSubmissionStatus: Joi.object({
    status: Joi.string()
      .valid('approved', 'rejected')
      .required()
      .messages({
        'any.only': 'Status must be: approved or rejected'
      }),
    adminFeedback: Joi.string()
      .trim()
      .max(2000)
      .allow(null)  // ✅ Allow null/undefined
      .optional()
      .messages({
        'string.max': 'Feedback cannot exceed 2000 characters'
      })
  }).unknown(false),

  // POST /submissions/:id/comments (add comment to submission)
  addSubmissionComment: Joi.object({
    text: Joi.string()
      .trim()
      .min(1)
      .max(2000)
      .required()
      .messages({
        'string.empty': 'Comment cannot be empty',
        'string.max': 'Comment cannot exceed 2000 characters'
      })
  }).unknown(false)
});

// ============================================
// VALIDATION MIDDLEWARE FACTORY
// ============================================

/**
 * Create validation middleware
 * Usage: app.post('/endpoint', validateRequest('schemaName'), controller)
 */
const validateRequest = (schemaName) => {
  return (req, res, next) => {
    const schema = validationSchemas[schemaName];

    if (!schema) {
      console.error(`❌ Validation schema not found: ${schemaName}`);
      return res.status(500).json({
        success: false,
        message: 'Server error: validation schema not configured'
      });
    }

    // Validate request body
    const { error, value } = schema.validate(req.body, {
      abortEarly: true,
      stripUnknown: true,
      messages: {
        'object.unknown': 'Unknown field: {#key}'
      }
    });

    if (error) {
      // Extract detailed error messages
      const details = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));

      // Log validation errors for debugging
      console.log('❌ Validation failed for', schemaName, ':', JSON.stringify({
        body: req.body,
        errors: details
      }, null, 2));

      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: details
      });
    }

    // Replace request body with validated/sanitized data
    req.body = value;
    next();
  };
};

/**
 * Validate URL parameters
 * Usage: app.get('/resource/:id', validateParams('objectId', 'id'), controller)
 */
const validateParams = (schemaName, paramName) => {
  return (req, res, next) => {
    const schema = validationSchemas[schemaName] || commonSchemas[schemaName];

    if (!schema) {
      console.error(`❌ Validation schema not found: ${schemaName}`);
      return res.status(500).json({
        success: false,
        message: 'Server error: validation schema not configured'
      });
    }

    const { error, value } = schema.validate(req.params[paramName]);

    if (error) {
      return res.status(400).json({
        success: false,
        message: `Invalid ${paramName}: ${error.message}`
      });
    }

    req.params[paramName] = value;
    next();
  };
};

/**
 * Validate query parameters
 * Usage: app.get('/endpoint', validateQuery(schema), controller)
 */
const validateQuery = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.query, {
      abortEarly: true,
      stripUnknown: true
    });

    if (error) {
      const details = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));

      return res.status(400).json({
        success: false,
        message: 'Invalid query parameters',
        errors: details
      });
    }

    req.query = value;
    next();
  };
};

module.exports = {
  validateRequest,
  validateParams,
  validateQuery,
  validationSchemas,
  commonSchemas
};

