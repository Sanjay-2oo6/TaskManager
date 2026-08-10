const admin = require('firebase-admin');
const User = require('../models/User');
const { sanitizeText, truncateText } = require('../utils/sanitizer');

// ✅ SECURITY: All notification content is sanitized to prevent XSS

/**
 * Initialize Firebase Admin
 * Expects a serviceAccountKey.json in the server root (or environment variables)
 */
try {
  // In a real environment, we'd use environment variables or a path to the JSON
  // For now, we set it up to be ready for the user to provide the key.
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin Initialized');
  } else {
    console.warn('⚠️ Firebase Admin not initialized: FIREBASE_SERVICE_ACCOUNT missing in .env');
  }
} catch (error) {
  console.error('❌ Firebase Admin Init Error:', error);
}

/**
 * Send a push notification to a specific user.
 */
exports.sendToUser = async (userId, payload) => {
  try {
    // Guard: skip silently if Firebase wasn't initialized
    if (!admin.apps.length) {
      console.log(`ℹ️ Notification skipped (Firebase not initialized)`);
      return null;
    }

    const user = await User.findById(userId);
    if (!user || !user.fcmToken) {
      console.log(`ℹ️ Skipping notification for user ${userId}: No FCM token found.`);
      return null;
    }

    // ✅ SECURITY: Sanitize notification content to prevent XSS
    const sanitizedTitle = sanitizeText(payload.title || '');
    const sanitizedBody = sanitizeText(payload.body || '');

    const message = {
      token: user.fcmToken,
      notification: { 
        title: sanitizedTitle, 
        body: sanitizedBody 
      },
      data: payload.data || {},
      android: {
        priority: 'high',
        notification: { channelId: 'task_alerts', priority: 'max' }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('🚀 Notification sent successfully:', response);
    return response;
  } catch (error) {
    console.error('❌ Error sending notification:', error.message);
    // If the token is invalid/expired, clear it so we don't retry
    if (error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-registration-token') {
      await User.findByIdAndUpdate(userId, { fcmToken: null });
    }
    return null;
  }
};

/**
 * Send a notification to multiple users.
 */
exports.sendToMultiple = async (userIds, payload) => {
  const sendToUser = exports.sendToUser;
  const promises = userIds.map(id => sendToUser(id, payload));
  return Promise.all(promises);
};
