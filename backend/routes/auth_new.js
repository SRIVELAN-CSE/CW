const express = require('express');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const RegistrationRequest = require('../models/RegistrationRequest');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRegistration, validateLogin, validateProfileUpdate } = require('../middleware/validation');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// Generate JWT Token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d'
  });
};

// Generate refresh token
const generateRefreshToken = (userId) => {
  return jwt.sign({ userId, type: 'refresh' }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRE || '30d'
  });
};

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user (creates registration request)
 * @access  Public
 */
router.post('/register', validateRegistration, async (req, res) => {
  try {
    const {
      name,
      email,
      phone,
      password,
      userType,
      location,
      department,
      employeeId,
      designation
    } = req.body;

    // Check if user already exists
    let existingUser = await User.findOne({
      $or: [{ email }, { phone }]
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email or phone already exists'
      });
    }

    // Check if registration request already exists
    let existingRequest = await RegistrationRequest.findOne({
      $or: [{ email }, { phone }],
      status: 'pending'
    });

    if (existingRequest) {
      return res.status(400).json({
        success: false,
        message: 'Registration request already pending for this email or phone'
      });
    }

    // For officer registrations, validate employee ID uniqueness
    if (userType === 'officer') {
      const existingOfficer = await User.findOne({ employeeId });
      if (existingOfficer) {
        return res.status(400).json({
          success: false,
          message: 'Employee ID already exists'
        });
      }
    }

    // Create registration request
    const registrationRequest = new RegistrationRequest({
      name,
      email,
      phone,
      password, // Will be hashed by the model
      userType,
      location,
      department: userType === 'officer' ? department : undefined,
      employeeId: userType === 'officer' ? employeeId : undefined,
      designation: userType === 'officer' ? designation : undefined,
      status: 'pending'
    });

    await registrationRequest.save();

    // Notify admins about new registration request
    const admins = await User.find({ userType: 'admin', isActive: true });
    
    for (const admin of admins) {
      const notification = new Notification({
        userId: admin._id,
        userType: 'admin',
        title: 'New Registration Request',
        message: `New ${userType} registration request from ${name}`,
        type: 'registration_request',
        category: 'account',
        priority: 'medium',
        relatedEntities: {
          registrationId: registrationRequest._id
        },
        actionable: true,
        actionButtons: [
          {
            label: 'Review',
            action: 'review_registration',
            url: `/admin/registrations/${registrationRequest._id}`
          }
        ]
      });

      await notification.save();
    }

    res.status(201).json({
      success: true,
      message: 'Registration request submitted successfully. Please wait for admin approval.',
      data: {
        requestId: registrationRequest._id,
        status: 'pending',
        submittedAt: registrationRequest.createdAt
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', validateLogin, async (req, res) => {
  try {
    const { email, password, rememberMe = false } = req.body;

    // Find user by email (include password for comparison)
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is not active. Please contact administrator.'
      });
    }

    // Check password
    const isPasswordMatch = await user.comparePassword(password);

    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Update last login and login count
    user.lastLogin = new Date();
    user.loginCount += 1;
    await user.save();

    // Generate tokens
    const token = generateToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    // Set token expiry based on remember me
    const tokenExpiry = rememberMe ? '30d' : '7d';

    // Remove sensitive fields
    const userData = user.toJSON();
    delete userData.password;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: userData,
        token,
        refreshToken,
        expiresIn: tokenExpiry
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   POST /api/auth/refresh
 * @desc    Refresh JWT token
 * @access  Public
 */
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token is required'
      });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    if (decoded.type !== 'refresh') {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Find user
    const user = await User.findById(decoded.userId);

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'User not found or inactive'
      });
    }

    // Generate new tokens
    const newToken = generateToken(user._id);
    const newRefreshToken = generateRefreshToken(user._id);

    res.json({
      success: true,
      message: 'Token refreshed successfully',
      data: {
        token: newToken,
        refreshToken: newRefreshToken
      }
    });

  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid refresh token'
    });
  }
});

/**
 * @route   GET /api/auth/profile
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/profile', authenticate, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate('reportStats');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get profile',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   PUT /api/auth/profile
 * @desc    Update user profile
 * @access  Private
 */
router.put('/profile', authenticate, validateProfileUpdate, upload.single('profilePicture'), async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const {
      name,
      phone,
      location,
      dateOfBirth,
      gender,
      preferences
    } = req.body;

    // Update allowed fields
    if (name) user.name = name;
    if (phone) {
      // Check if phone is already taken
      const existingUser = await User.findOne({ 
        phone, 
        _id: { $ne: user._id } 
      });
      
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Phone number already in use'
        });
      }
      
      user.phone = phone;
    }
    
    if (location) user.location = location;
    if (dateOfBirth) user.dateOfBirth = dateOfBirth;
    if (gender) user.gender = gender;
    if (preferences) user.preferences = { ...user.preferences, ...preferences };

    // Handle profile picture upload
    if (req.file) {
      try {
        // Delete old profile picture if exists
        if (user.profilePicture) {
          const publicId = user.profilePicture.split('/').pop().split('.')[0];
          await cloudinary.uploader.destroy(publicId);
        }

        // Upload new profile picture
        const result = await new Promise((resolve, reject) => {
          cloudinary.uploader.upload_stream(
            {
              folder: 'civic-welfare/profiles',
              public_id: `${user._id}_${Date.now()}`,
              transformation: [
                { width: 300, height: 300, crop: 'fill', gravity: 'face' },
                { quality: 'auto', fetch_format: 'auto' }
              ]
            },
            (error, result) => {
              if (error) reject(error);
              else resolve(result);
            }
          ).end(req.file.buffer);
        });

        user.profilePicture = result.secure_url;
      } catch (uploadError) {
        console.error('Profile picture upload error:', uploadError);
        return res.status(400).json({
          success: false,
          message: 'Failed to upload profile picture'
        });
      }
    }

    await user.save();

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: user
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   POST /api/auth/change-password
 * @desc    Change user password
 * @access  Private
 */
router.post('/change-password', authenticate, async (req, res) => {
  try {
    const { currentPassword, newPassword, confirmPassword } = req.body;

    // Validation
    if (!currentPassword || !newPassword || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'All password fields are required'
      });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'New passwords do not match'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long'
      });
    }

    // Find user with password
    const user = await User.findById(req.user.id).select('+password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check current password
    const isCurrentPasswordValid = await user.comparePassword(currentPassword);

    if (!isCurrentPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Update password
    user.password = newPassword; // Will be hashed by pre-save middleware
    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to change password',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   POST /api/auth/logout
 * @desc    Logout user (invalidate token)
 * @access  Private
 */
router.post('/logout', authenticate, async (req, res) => {
  try {
    // In a production environment, you might want to maintain a blacklist of tokens
    // For now, we'll just return a success message as the client will remove the token

    res.json({
      success: true,
      message: 'Logout successful'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Logout failed',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   GET /api/auth/verify-token
 * @desc    Verify JWT token validity
 * @access  Private
 */
router.get('/verify-token', authenticate, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Token is invalid or user is inactive'
      });
    }

    res.json({
      success: true,
      message: 'Token is valid',
      data: {
        user: user,
        tokenExp: req.tokenExp
      }
    });

  } catch (error) {
    console.error('Token verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Token verification failed'
    });
  }
});

/**
 * @route   GET /api/auth/registration-status/:requestId
 * @desc    Check registration request status
 * @access  Public
 */
router.get('/registration-status/:requestId', async (req, res) => {
  try {
    const { requestId } = req.params;

    const registrationRequest = await RegistrationRequest.findById(requestId);

    if (!registrationRequest) {
      return res.status(404).json({
        success: false,
        message: 'Registration request not found'
      });
    }

    res.json({
      success: true,
      data: {
        requestId: registrationRequest._id,
        status: registrationRequest.status,
        submittedAt: registrationRequest.createdAt,
        reviewedAt: registrationRequest.reviewedAt,
        reviewedBy: registrationRequest.reviewedBy,
        rejectionReason: registrationRequest.rejectionReason
      }
    });

  } catch (error) {
    console.error('Registration status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get registration status',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;