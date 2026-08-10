const fs = require('fs');
const path = require('path');
const s3Service = require('../services/s3Service');
const User = require('../models/User');

const VERSION_FILE = path.join(__dirname, '../config/version.json');

// Ensure config directory exists
const configDir = path.join(__dirname, '../config');
if (!fs.existsSync(configDir)) {
  fs.mkdirSync(configDir);
}

// Initial default config if file doesn't exist
if (!fs.existsSync(VERSION_FILE)) {
  const defaultConfig = {
    version: "1.0.1",
    androidUrl: "https://github.com/InnoTechHub/Taskmanager/releases/download/v1.0.1/app-release.apk",
    desktopUrl: "https://github.com/InnoTechHub/Taskmanager/releases/download/v1.0.1/Taskmanager-Setup.exe",
    releaseNotes: "Performance improvements and live chat stability fixes."
  };
  fs.writeFileSync(VERSION_FILE, JSON.stringify(defaultConfig, null, 2));
}

/**
 * Handles application-level data such as versioning and OTA updates.
 */
const getLatestVersion = async (req, res) => {
  try {
    const data = await fs.promises.readFile(VERSION_FILE, 'utf8');
    const config = JSON.parse(data);
    
    // Generate signed URL for S3 content if it's an S3 link
    if (config.androidUrl && config.androidUrl.includes('amazonaws.com')) {
      config.androidUrl = await s3Service.getSignedDownloadUrl(config.androidUrl);
    }

    res.status(200).json({
      success: true,
      data: config
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Update app version metadata and upload APK to S3 (Pro Dashboard).
 */
const updateAppVersion = async (req, res) => {
  try {
    const { version, releaseNotes, desktopUrl } = req.body;
    let { androidUrl } = req.body;

    // Validate version to prevent path traversal in S3 filename
    if (version && !/^[\d]+\.[\d]+\.[\d]+$/.test(version)) {
      return res.status(400).json({ success: false, message: 'Invalid version format. Use semver (e.g. 1.2.3)' });
    }

    // If an APK file was uploaded, put it in S3
    if (req.file) {
      const safeVersion = version || 'latest';
      androidUrl = await s3Service.uploadPublicFile(
        req.file.buffer, 
        `app-v${safeVersion}.apk`, 
        req.file.mimetype
      );
    }

    const currentData = await fs.promises.readFile(VERSION_FILE, 'utf8');
    const currentConfig = JSON.parse(currentData);
    
    const newConfig = {
      version: version || currentConfig.version,
      androidUrl: androidUrl || currentConfig.androidUrl,
      desktopUrl: desktopUrl || currentConfig.desktopUrl,
      releaseNotes: releaseNotes || currentConfig.releaseNotes
    };

    await fs.promises.writeFile(VERSION_FILE, JSON.stringify(newConfig, null, 2));

    res.status(200).json({
      success: true,
      data: newConfig,
      message: 'App version deployed successfully to the fleet.'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getLatestVersion,
  updateAppVersion,
  getUsers: async (req, res) => {
    try {
      const organizationId = req.user.organizationId;
      if (!organizationId) {
        return res.status(400).json({ success: false, message: 'No organization context' });
      }

      const users = await User.find({ organizationId })
        .select('_id name username role email organizationId')
        .lean();

      res.status(200).json({ 
        success: true, 
        data: users,
        count: users.length 
      });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
};
