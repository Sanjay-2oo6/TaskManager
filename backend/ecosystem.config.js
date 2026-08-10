/**
 * PM2 Ecosystem Configuration
 * 
 * This configuration enables Node.js clustering for maximum performance.
 * PM2 will automatically spawn one process per CPU core.
 * 
 * Usage:
 *   Production:  pm2 start ecosystem.config.js --env production
 *   Development: pm2 start ecosystem.config.js --env development
 *   Stop:        pm2 stop task-manager-api
 *   Restart:     pm2 restart task-manager-api
 *   Logs:        pm2 logs task-manager-api
 *   Monitor:     pm2 monit
 */

module.exports = {
  apps: [
    {
      name: 'task-manager-api',
      script: './server.js',
      
      // Clustering: Use all available CPU cores
      instances: 'max',
      exec_mode: 'cluster',
      
      // Auto-restart on crash
      autorestart: true,
      
      // Watch for file changes in development
      watch: false, // Set to true for development if needed
      
      // Maximum memory before restart (prevents memory leaks)
      max_memory_restart: '1G',
      
      // Environment variables for production
      env_production: {
        NODE_ENV: 'production',
        PORT: 5000,
      },
      
      // Environment variables for development
      env_development: {
        NODE_ENV: 'development',
        PORT: 5000,
        watch: true, // Enable watch in development
      },
      
      // Logging
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Merge logs from all instances
      merge_logs: true,
      
      // Advanced options
      instance_var: 'INSTANCE_ID',
      
      // Graceful shutdown
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
      
      // Min uptime before considering app as stable
      min_uptime: '10s',
      
      // Max restarts within max_restarts_within timeframe
      max_restarts: 10,
      
      // Exponential backoff restart delay
      exp_backoff_restart_delay: 100,
    }
  ],
  
  // Deployment configuration (optional - for future use)
  deploy: {
    production: {
      user: 'node',
      host: 'your-server-ip',
      ref: 'origin/main',
      repo: 'your-git-repo',
      path: '/var/www/task-manager',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env production'
    }
  }
};
