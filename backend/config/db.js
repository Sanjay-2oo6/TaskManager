const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    // ✅ PERFORMANCE: Optimized connection pool settings
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      // Connection pool configuration
      maxPoolSize: 50,        // Maximum number of connections (default: 100)
      minPoolSize: 10,        // Minimum number of connections to maintain (default: 0)
      
      // Timeout settings
      socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
      serverSelectionTimeoutMS: 5000, // Timeout for initial connection
      
      // Heartbeat
      heartbeatFrequencyMS: 10000, // Check server availability every 10 seconds
      
      // Performance optimizations
      maxIdleTimeMS: 30000,   // Remove connections idle for more than 30 seconds
      
      // Compression (reduces bandwidth, slight CPU overhead)
      compressors: ['zlib'],
    });

    console.log(`✅ MongoDB connected: ${conn.connection.host}`);
    console.log(`📊 Connection pool: min=${conn.connection.client.s.options.minPoolSize}, max=${conn.connection.client.s.options.maxPoolSize}`);
    
    // Monitor connection pool
    conn.connection.on('connected', () => {
      console.log('✅ MongoDB connection established');
    });
    
    conn.connection.on('disconnected', () => {
      console.warn('⚠️  MongoDB disconnected. Attempting to reconnect...');
    });
    
    conn.connection.on('error', (err) => {
      console.error('❌ MongoDB connection error:', err);
    });
    
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
