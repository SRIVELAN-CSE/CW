const express = require('express');
const router = express.Router();

const PasswordResetRequest = require('../models/PasswordResetRequest');
const User = require('../models/User');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, passwordResetSchemas } = require('../middleware/validation');

// @route   POST /api/password-reset
// @desc    Create password reset request
// @access  Public
router.post('/', validate(passwordResetSchemas.create), async (req, res) => {
  try {
    const { email, userType, reason } = req.body;

    // Check if user exists
    const user = await User.findOne({ email, userType });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found with this email and user type'
      });
    }

    // Check for existing pending request
    const existingRequest = await PasswordResetRequest.findOne({
      email,
      userType,
      status: 'pending'
    });

    if (existingRequest) {
      return res.status(400).json({
        success: false,
        message: 'Password reset request already pending'
      });
    }

    const request = await PasswordResetRequest.create({
      email,
      userType,
      reason: reason || 'Password reset requested'
    });

    res.status(201).json({
      success: true,
      message: 'Password reset request submitted successfully',
      data: { requestId: request._id }
    });
  } catch (error) {
    console.error('Create password reset request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit password reset request'
    });
  }
});

// @route   GET /api/password-reset
// @desc    Get all password reset requests
// @access  Private (Admin only)
router.get('/', authenticate, authorize('admin'), async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      userType,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    const filter = {};
    if (status) filter.status = status;
    if (userType) filter.userType = userType;

    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    const requests = await PasswordResetRequest.find(filter)
      .populate('reviewedBy', 'name')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const totalRequests = await PasswordResetRequest.countDocuments(filter);

    res.json({
      success: true,
      data: {
        requests,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalRequests / parseInt(limit)),
          totalRequests
        }
      }
    });
  } catch (error) {
    console.error('Get password reset requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch password reset requests'
    });
  }
});

// @route   PUT /api/password-reset/:id
// @desc    Process password reset request
// @access  Private (Admin only)
router.put('/:id', authenticate, authorize('admin'), validate(passwordResetSchemas.update), async (req, res) => {
  try {
    const { status, reviewNotes, newPassword } = req.body;

    const request = await PasswordResetRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Password reset request not found'
      });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Request has already been processed'
      });
    }

    // Update request status
    await request.updateStatus(
      status,
      req.user._id,
      req.user.name,
      reviewNotes
    );

    // If approved, update user password
    if (status === 'approved' && newPassword) {
      const user = await User.findOne({
        email: request.email,
        userType: request.userType
      });

      if (user) {
        user.password = newPassword;
        await user.save();

        request.passwordChangedAt = new Date();
        request.status = 'completed';
        await request.save();
      }
    }

    res.json({
      success: true,
      message: `Password reset request ${status} successfully`
    });
  } catch (error) {
    console.error('Process password reset request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to process password reset request'
    });
  }
});

module.exports = router;