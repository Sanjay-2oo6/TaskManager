const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const crypto = require('crypto');
const dotenv = require('dotenv');

dotenv.config();

const s3Client = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  }
});

/**
 * Upload a file buffer to S3 with security hardening.
 * 🛡️ SECURITY FIX 0.12: Added encryption, content disposition, and file hash
 * @param {Buffer} fileBuffer - The file content.
 * @param {string} fileName - Destination name in S3.
 * @param {string} mimeType - The file type.
 * @returns {Promise<{key: string, hash: string}>} - S3 object key and file hash
 */
exports.uploadToS3 = async (fileBuffer, fileName, mimeType, folder = 'submissions') => {
  // Calculate SHA-256 hash for file integrity verification
  const fileHash = crypto.createHash('sha256').update(fileBuffer).digest('hex');

  const uploadParams = {
    Bucket: process.env.AWS_BUCKET_NAME,
    Key: `${folder}/${Date.now()}_${fileName}`,
    Body: fileBuffer,
    ContentType: mimeType,
    // 🛡️ SECURITY: Enable server-side encryption (AES-256)
    ServerSideEncryption: 'AES256',
    // 🛡️ SECURITY: Force download instead of opening in browser
    ContentDisposition: `attachment; filename="${fileName}"`,
    // 🛡️ SECURITY: Store original hash as metadata for integrity verification
    Metadata: {
      'original-hash': fileHash,
      'uploaded-at': new Date().toISOString()
    }
  };

  await s3Client.send(new PutObjectCommand(uploadParams));
  
  return {
    key: uploadParams.Key,
    hash: fileHash
  };
};

/**
 * Upload a file to S3 with Public-Read access for updates (with security).
 * 🛡️ SECURITY FIX 0.12: Added encryption and content disposition
 */
exports.uploadPublicFile = async (fileBuffer, fileName, mimeType, folder = 'updates') => {
  // Calculate hash for integrity
  const fileHash = crypto.createHash('sha256').update(fileBuffer).digest('hex');

  const uploadParams = {
    Bucket: process.env.AWS_BUCKET_NAME,
    Key: `${folder}/${fileName}`,
    Body: fileBuffer,
    ContentType: mimeType,
    // 🛡️ SECURITY: Enable server-side encryption
    ServerSideEncryption: 'AES256',
    // 🛡️ SECURITY: Force download
    ContentDisposition: `attachment; filename="${fileName}"`,
    // 🛡️ SECURITY: Store hash metadata
    Metadata: {
      'original-hash': fileHash,
      'uploaded-at': new Date().toISOString()
    }
  };

  await s3Client.send(new PutObjectCommand(uploadParams));
  return {
    url: `https://${process.env.AWS_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${uploadParams.Key}`,
    hash: fileHash
  };
};

/**
 * Generates a temporary pre-signed URL for downloading a file
 * @param {string} fullUrl The public S3 URL
 * @returns {Promise<string>} A signed URL valid for 24 hours
 */
exports.getSignedDownloadUrl = async (fullUrl) => {
  try {
    if (!fullUrl || !fullUrl.includes('amazonaws.com')) return fullUrl;

    // Extract Key from URL (it's the part after .com/)
    const key = fullUrl.split('.com/')[1];
    
    const command = new GetObjectCommand({
      Bucket: process.env.AWS_BUCKET_NAME,
      Key: key,
    });

    // Sign for 24 hours (86400 seconds)
    return await getSignedUrl(s3Client, command, { expiresIn: 86400 });
  } catch (error) {
    console.error('❌ Signed URL Error:', error);
    return fullUrl; // Fallback to raw URL
  }
};

/**
 * Generate a secure, time-limited signed URL for viewing an S3 object.
 * @param {string} key - The S3 object key.
 * @returns {Promise<string>} - The signed URL.
 */
exports.getSignedImageUrl = async (key) => {
  const command = new GetObjectCommand({
    Bucket: process.env.AWS_BUCKET_NAME,
    Key: key
  });

  // ✅ FIX: URL expires in 24 hours (was 1 hour, causing expired links)
  return await getSignedUrl(s3Client, command, { expiresIn: 86400 });
};

/**
 * Delete a file from S3 by its key
 * @param {string} key - The S3 object key to delete
 * @returns {Promise<boolean>} - True if deletion was successful
 */
exports.deleteFromS3 = async (key) => {
  try {
    const command = new DeleteObjectCommand({
      Bucket: process.env.AWS_BUCKET_NAME,
      Key: key
    });

    const response = await s3Client.send(command);
    return response.$metadata.httpStatusCode === 204;
  } catch (error) {
    console.error('❌ S3 Delete Error:', { key, error: error.message });
    throw error;
  }
};
