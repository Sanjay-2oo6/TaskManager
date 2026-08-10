const multer = require('multer');
const path = require('path');

// ✅ SECURITY: Whitelist ONLY safe file types
const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
]);

const ALLOWED_EXTENSIONS = new Map([
  ['image/jpeg', ['.jpg', '.jpeg']],
  ['image/png', ['.png']],
  ['image/webp', ['.webp']],
  ['application/pdf', ['.pdf']],
  ['application/msword', ['.doc']],
  ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', ['.docx']],
  ['application/vnd.ms-excel', ['.xls']],
  ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', ['.xlsx']]
]);

// Configure Multer for buffer-based uploads (memory storage)
const storage = multer.memoryStorage();

// ✅ SECURITY: File validation filter
const fileFilter = (req, file, cb) => {
  try {
    // 1. Check MIME type
    if (!ALLOWED_MIME_TYPES.has(file.mimetype)) {
      console.warn(`⚠️ Rejected file: Invalid MIME type "${file.mimetype}"`);
      return cb(new Error(
        `File type not allowed: ${file.mimetype}. Allowed: images (JPG, PNG, WEBP), PDF, DOC, DOCX, XLS, XLSX`
      ));
    }

    // 2. Check file extension
    const ext = path.extname(file.originalname).toLowerCase();
    const allowedExts = ALLOWED_EXTENSIONS.get(file.mimetype) || [];
    
    if (!allowedExts.includes(ext)) {
      console.warn(`⚠️ Rejected file: Extension "${ext}" doesn't match MIME type "${file.mimetype}"`);
      return cb(new Error(
        `File extension "${ext}" not allowed for type "${file.mimetype}"`
      ));
    }

    // 3. Sanitize filename (prevent path traversal)
    const sanitizedName = path.basename(file.originalname)
      .replace(/[^a-zA-Z0-9.-]/g, '_')
      .substring(0, 255); // Limit filename length
    
    if (sanitizedName !== file.originalname) {
      console.log(`🔧 Filename sanitized: ${file.originalname} → ${sanitizedName}`);
      file.originalname = sanitizedName;
    }

    // 4. Reject suspicious patterns
    if (file.originalname.includes('..') || file.originalname.includes('/') || file.originalname.includes('\\')) {
      console.warn(`⚠️ Rejected file: Suspicious path traversal attempt in "${file.originalname}"`);
      return cb(new Error('Invalid filename: path traversal attempt detected'));
    }

    console.log(`✅ File validated: ${file.originalname} (${file.mimetype})`);
    cb(null, true);

  } catch (err) {
    console.error('❌ File validation error:', err);
    cb(err);
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 20 * 1024 * 1024, // 20MB limit per file
    files: 20 // Max 20 files per request
  },
  fileFilter: fileFilter
});

module.exports = { upload };
