// ---------------------------------------------------------------------------
// validateEnv.js - Validate required environment variables
// Fix 0.13: Fail early if critical config is missing
// ---------------------------------------------------------------------------

const path = require('path');
const logger = require('./logger');

// Ensure .env is loaded from the server directory
require('dotenv').config({ path: path.join(__dirname, '../.env') });

/**
 * List of required environment variables
 * These MUST be set before server starts
 */
const REQUIRED_ENV_VARS = [
  'MONGODB_URI',
  'JWT_SECRET',
  'AWS_ACCESS_KEY_ID',
  'AWS_SECRET_ACCESS_KEY',
  'AWS_BUCKET_NAME',
  'AWS_REGION',
  'FIREBASE_SERVICE_ACCOUNT',
  'NODE_ENV',
  'PORT'
];

/**
 * Validate all required environment variables are set
 * Throws error if any are missing
 */
function validateEnvironmentVariables() {
  const missing = [];

  for (const envVar of REQUIRED_ENV_VARS) {
    if (!process.env[envVar]) {
      missing.push(envVar);
    }
  }

  if (missing.length > 0) {
    const errorMsg = `❌ MISSING REQUIRED ENVIRONMENT VARIABLES:\n${missing.map(v => `   - ${v}`).join('\n')}\n\nUpdate your .env file and restart the server.`;
    
    console.error(errorMsg);
    logger.error('Environment validation failed', { missing });
    
    // Exit immediately - don't start server with incomplete config
    process.exit(1);
  }

  logger.info('Environment validation passed', {
    node_env: process.env.NODE_ENV,
    aws_region: process.env.AWS_REGION,
    firebase_project: process.env.FIREBASE_PROJECT_ID
  });
}

module.exports = { validateEnvironmentVariables };
