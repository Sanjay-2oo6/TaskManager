// ---------------------------------------------------------------------------
// passwordValidator.js - Strong password validation utility
// Fix 0.10: Enforce secure password requirements
// ---------------------------------------------------------------------------

const passwordValidator = require('password-validator');

// Create password schema with security requirements
const schema = new passwordValidator();

schema
  .is().min(8)                                    // Minimum length 8
  .is().max(100)                                  // Maximum length 100
  .has().uppercase()                              // Must have uppercase letters
  .has().lowercase()                              // Must have lowercase letters
  .has().digits()                                 // Must have digits
  .has().symbols()                                // Must have special characters
  .has().not().spaces()                           // Should not have spaces
  .is().not().oneOf(['Password123!', 'Admin@123456', 'Test@1234567']); // Blacklist common

/**
 * Validates password strength and returns detailed error messages
 * @param {string} password - The password to validate
 * @returns {Object} { isValid: boolean, errors: string[] }
 */
function validatePassword(password) {
  if (!password) {
    return {
      isValid: false,
      errors: ['Password is required']
    };
  }

  const failures = schema.validate(password, { list: true });
  
  if (failures.length === 0) {
    return {
      isValid: true,
      errors: []
    };
  }

  // Convert technical failures to user-friendly messages
  const errorMessages = failures.map(failure => {
    switch (failure) {
      case 'min':
        return 'Password must be at least 8 characters long';
      case 'max':
        return 'Password must not exceed 100 characters';
      case 'uppercase':
        return 'Password must contain at least one uppercase letter (A-Z)';
      case 'lowercase':
        return 'Password must contain at least one lowercase letter (a-z)';
      case 'digits':
        return 'Password must contain at least one number (0-9)';
      case 'symbols':
        return 'Password must contain at least one special character (@, #, $, !, etc.)';
      case 'spaces':
        return 'Password must not contain spaces';
      case 'oneOf':
        return 'This password is too common and not allowed';
      default:
        return 'Password does not meet security requirements';
    }
  });

  return {
    isValid: false,
    errors: errorMessages
  };
}

/**
 * Quick validation - returns true/false only
 * @param {string} password - The password to validate
 * @returns {boolean}
 */
function isPasswordValid(password) {
  return schema.validate(password);
}

/**
 * Get a user-friendly error message (first error only)
 * @param {string} password - The password to validate
 * @returns {string|null} Error message or null if valid
 */
function getPasswordError(password) {
  const result = validatePassword(password);
  return result.isValid ? null : result.errors[0];
}

module.exports = {
  validatePassword,
  isPasswordValid,
  getPasswordError
};
