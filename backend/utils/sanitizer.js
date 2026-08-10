const sanitizeHtml = require('sanitize-html');

/**
 * ✅ SECURITY: Input sanitization utility
 * Prevents XSS attacks by sanitizing user input before storing or displaying
 */

/**
 * Sanitize text input - Remove all HTML tags, only keep plain text
 * Use for: notifications, task titles, user names, general text input
 */
exports.sanitizeText = (input) => {
  if (!input || typeof input !== 'string') {
    return input;
  }

  // Remove all HTML tags, decode entities, trim whitespace
  return sanitizeHtml(input, {
    allowedTags: [], // No HTML tags allowed
    allowedAttributes: {},
    textFilter: (text) => {
      // Decode HTML entities and remove extra whitespace
      return text.replace(/&nbsp;/g, ' ').trim();
    }
  }).trim();
};

/**
 * Sanitize rich text input - Allow safe HTML tags only
 * Use for: task descriptions, admin notes (if rich text editor is used)
 */
exports.sanitizeRichText = (input) => {
  if (!input || typeof input !== 'string') {
    return input;
  }

  // Allow only safe HTML tags and attributes
  return sanitizeHtml(input, {
    allowedTags: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li'],
    allowedAttributes: {
      'a': ['href', 'title']
    },
    allowedSchemes: ['http', 'https', 'mailto'],
    transformTags: {
      'a': (tagName, attribs) => {
        // Ensure external links open in new tab and have noopener
        return {
          tagName: 'a',
          attribs: {
            ...attribs,
            target: '_blank',
            rel: 'noopener noreferrer'
          }
        };
      }
    }
  });
};

/**
 * Sanitize object - Recursively sanitize all string properties
 * Use for: sanitizing entire request bodies
 */
exports.sanitizeObject = (obj, richTextFields = []) => {
  if (!obj || typeof obj !== 'object') {
    return obj;
  }

  const sanitized = Array.isArray(obj) ? [] : {};

  for (const key in obj) {
    const value = obj[key];

    if (typeof value === 'string') {
      // Use rich text sanitization for specified fields, plain text for others
      sanitized[key] = richTextFields.includes(key)
        ? exports.sanitizeRichText(value)
        : exports.sanitizeText(value);
    } else if (typeof value === 'object' && value !== null) {
      // Recursively sanitize nested objects
      sanitized[key] = exports.sanitizeObject(value, richTextFields);
    } else {
      // Keep other types as-is (numbers, booleans, etc.)
      sanitized[key] = value;
    }
  }

  return sanitized;
};

/**
 * Truncate text safely for notifications (prevents breaking in middle of HTML entity)
 */
exports.truncateText = (text, maxLength = 100) => {
  if (!text || text.length <= maxLength) {
    return text;
  }

  // Truncate and add ellipsis
  let truncated = text.substring(0, maxLength);
  
  // Make sure we don't break in the middle of an HTML entity
  const lastAmpersand = truncated.lastIndexOf('&');
  const lastSemicolon = truncated.lastIndexOf(';');
  
  if (lastAmpersand > lastSemicolon) {
    // We might have broken an entity, truncate before it
    truncated = truncated.substring(0, lastAmpersand);
  }

  return truncated.trim() + '...';
};

module.exports = exports;
