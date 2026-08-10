/**
 * ✅ SECURITY: Pagination utility to prevent performance issues and DoS attacks
 * Limits the amount of data returned per request
 */

/**
 * Parse and validate pagination parameters from query string
 * @param {Object} query - Express req.query object
 * @param {Object} options - Configuration options
 * @returns {Object} - Validated pagination parameters
 */
exports.parsePaginationParams = (query, options = {}) => {
  const {
    defaultPage = 1,
    defaultLimit = 20,
    maxLimit = 100
  } = options;

  // Parse page number
  let page = parseInt(query.page, 10);
  if (isNaN(page) || page < 1) {
    page = defaultPage;
  }

  // Parse limit (items per page)
  let limit = parseInt(query.limit, 10);
  if (isNaN(limit) || limit < 1) {
    limit = defaultLimit;
  }

  // ✅ SECURITY: Enforce maximum limit to prevent DoS
  if (limit > maxLimit) {
    limit = maxLimit;
  }

  // Calculate skip value for MongoDB
  const skip = (page - 1) * limit;

  return { page, limit, skip };
};

/**
 * Build pagination metadata for response
 * @param {Number} page - Current page number
 * @param {Number} limit - Items per page
 * @param {Number} totalCount - Total number of items
 * @returns {Object} - Pagination metadata
 */
exports.buildPaginationMeta = (page, limit, totalCount) => {
  const totalPages = Math.ceil(totalCount / limit) || 1;
  const hasNextPage = page < totalPages;
  const hasPrevPage = page > 1;

  return {
    currentPage: page,
    totalPages,
    totalItems: totalCount,
    itemsPerPage: limit,
    hasNextPage,
    hasPrevPage,
    nextPage: hasNextPage ? page + 1 : null,
    prevPage: hasPrevPage ? page - 1 : null
  };
};

/**
 * Build paginated response with data and metadata
 * @param {Array} data - Array of items for current page
 * @param {Number} page - Current page number
 * @param {Number} limit - Items per page
 * @param {Number} totalCount - Total number of items
 * @returns {Object} - Complete paginated response
 */
exports.paginatedResponse = (data, page, limit, totalCount) => {
  return {
    success: true,
    data,
    pagination: exports.buildPaginationMeta(page, limit, totalCount)
  };
};

/**
 * Parse sort parameters from query string
 * @param {String} sortBy - Sort field from query
 * @param {String} order - Sort order ('asc' or 'desc')
 * @param {Object} allowedFields - Map of allowed sort fields to MongoDB field names
 * @param {Object} defaultSort - Default sort object if none specified
 * @returns {Object} - MongoDB sort object
 */
exports.parseSortParams = (sortBy, order = 'desc', allowedFields = {}, defaultSort = { createdAt: -1 }) => {
  if (!sortBy || !allowedFields[sortBy]) {
    return defaultSort;
  }

  const field = allowedFields[sortBy];
  const direction = order.toLowerCase() === 'asc' ? 1 : -1;

  return { [field]: direction };
};

module.exports = exports;
