const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
const ensureDirectoryExists = (dirPath) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

// Create upload directories
const uploadDirs = {
  reports: path.join(__dirname, '../uploads/reports'),
  certificates: path.join(__dirname, '../uploads/certificates'),
  profiles: path.join(__dirname, '../uploads/profiles'),
  documents: path.join(__dirname, '../uploads/documents')
};

Object.values(uploadDirs).forEach(ensureDirectoryExists);

// Storage configuration for different file types
const createStorage = (destination) => {
  return multer.diskStorage({
    destination: (req, file, cb) => {
      cb(null, destination);
    },
    filename: (req, file, cb) => {
      // Generate unique filename with timestamp and random number
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      const fileExtension = path.extname(file.originalname);
      const fileName = `${file.fieldname}-${uniqueSuffix}${fileExtension}`;
      cb(null, fileName);
    }
  });
};

// File filter functions
const imageFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only image files (JPEG, PNG, GIF) are allowed'), false);
  }
};

const documentFilter = (req, file, cb) => {
  const allowedTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg',
    'image/jpg',
    'image/png'
  ];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only PDF, Word documents, and images are allowed'), false);
  }
};

const generalFilter = (req, file, cb) => {
  const allowedTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('File type not supported'), false);
  }
};

// File size limits (in bytes)
const fileSizeLimits = {
  image: 5 * 1024 * 1024, // 5MB for images
  document: 10 * 1024 * 1024, // 10MB for documents
  general: 10 * 1024 * 1024 // 10MB general limit
};

// Upload configurations for different purposes
const uploadConfigs = {
  // For report images
  reportImages: multer({
    storage: createStorage(uploadDirs.reports),
    fileFilter: imageFilter,
    limits: {
      fileSize: fileSizeLimits.image,
      files: 5 // Maximum 5 files
    }
  }),

  // For certificate documents
  certificateDocuments: multer({
    storage: createStorage(uploadDirs.certificates),
    fileFilter: documentFilter,
    limits: {
      fileSize: fileSizeLimits.document,
      files: 3 // Maximum 3 files
    }
  }),

  // For profile pictures
  profilePicture: multer({
    storage: createStorage(uploadDirs.profiles),
    fileFilter: imageFilter,
    limits: {
      fileSize: fileSizeLimits.image,
      files: 1 // Only one profile picture
    }
  }),

  // For general documents
  generalDocuments: multer({
    storage: createStorage(uploadDirs.documents),
    fileFilter: generalFilter,
    limits: {
      fileSize: fileSizeLimits.general,
      files: 10 // Maximum 10 files
    }
  })
};

// Middleware to handle upload errors
const handleUploadError = (error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    switch (error.code) {
      case 'LIMIT_FILE_SIZE':
        return res.status(400).json({
          success: false,
          error: 'File too large. Please upload a smaller file.'
        });
      case 'LIMIT_FILE_COUNT':
        return res.status(400).json({
          success: false,
          error: 'Too many files. Please reduce the number of files.'
        });
      case 'LIMIT_UNEXPECTED_FILE':
        return res.status(400).json({
          success: false,
          error: 'Unexpected file field.'
        });
      default:
        return res.status(400).json({
          success: false,
          error: 'File upload error: ' + error.message
        });
    }
  } else if (error) {
    return res.status(400).json({
      success: false,
      error: error.message
    });
  }
  next();
};

// Helper function to delete uploaded files
const deleteUploadedFiles = (files) => {
  if (!files) return;

  const filesToDelete = Array.isArray(files) ? files : [files];
  
  filesToDelete.forEach(file => {
    try {
      if (fs.existsSync(file.path)) {
        fs.unlinkSync(file.path);
      }
    } catch (error) {
      console.error('Error deleting file:', file.path, error);
    }
  });
};

// Helper function to get file URL
const getFileUrl = (filePath) => {
  if (!filePath) return null;
  
  // Convert absolute path to relative URL
  const relativePath = path.relative(path.join(__dirname, '..'), filePath);
  return `${process.env.API_BASE_URL || 'http://localhost:3000'}/${relativePath.replace(/\\/g, '/')}`;
};

// Clean up old files (can be used in a cron job)
const cleanupOldFiles = (directory, maxAgeInDays = 30) => {
  try {
    if (!fs.existsSync(directory)) return;

    const files = fs.readdirSync(directory);
    const maxAge = maxAgeInDays * 24 * 60 * 60 * 1000; // Convert to milliseconds
    const now = Date.now();

    files.forEach(file => {
      const filePath = path.join(directory, file);
      const stats = fs.statSync(filePath);
      
      if (now - stats.mtime.getTime() > maxAge) {
        fs.unlinkSync(filePath);
        console.log(`Deleted old file: ${filePath}`);
      }
    });
  } catch (error) {
    console.error('Error cleaning up old files:', error);
  }
};

module.exports = {
  uploadConfigs,
  handleUploadError,
  deleteUploadedFiles,
  getFileUrl,
  cleanupOldFiles,
  uploadDirs
};