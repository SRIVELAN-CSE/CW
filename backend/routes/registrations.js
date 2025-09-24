const express = require('express');
const router = express.Router();

const RegistrationRequest = require('../models/RegistrationRequest');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');

// @route   GET /api/registrations
// @desc    Get all registration requests
// @access  Private (Admin only)
router.get('/', authenticate, authorize('admin'), async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      userType,
      department,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    const filter = {};
    if (status) filter.status = status;
    if (userType) filter.userType = userType;
    if (department) filter.department = department;

    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    const requests = await RegistrationRequest.find(filter)
      .populate('reviewedBy', 'name')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const totalRequests = await RegistrationRequest.countDocuments(filter);

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
    console.error('Get registration requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch registration requests'
    });
  }
});

// @route   GET /api/registrations/:id
// @desc    Get single registration request
// @access  Private (Admin only)
router.get('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    const request = await RegistrationRequest.findById(req.params.id)
      .populate('reviewedBy', 'name email');

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Registration request not found'
      });
    }

    res.json({
      success: true,
      data: { request }
    });
  } catch (error) {
    console.error('Get registration request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch registration request'
    });
  }
});

// @route   PUT /api/registrations/:id/approve
// @desc    Approve registration request
// @access  Private (Admin only)
router.put('/:id/approve', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { reviewNotes } = req.body;

    const request = await RegistrationRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Registration request not found'
      });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Request has already been processed'
      });
    }

    // Check if user with this email already exists
    const existingUser = await User.findOne({ email: request.email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Generate a temporary password
    const tempPassword = Math.random().toString(36).slice(-8);

    // Create user account
    const user = await User.create({
      name: request.name,
      email: request.email,
      phone: request.phone,
      password: tempPassword,
      userType: request.userType,
      location: request.location,
      department: request.department,
      isVerified: true
    });

    // Update registration request
    await request.updateStatus(
      'approved',
      req.user._id,
      req.user.name,
      reviewNotes
    );

    // Create notification for the user (if they have an account)
    // Note: In real implementation, send email with temporary password

    res.json({
      success: true,
      message: 'Registration request approved successfully',
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          userType: user.userType
        },
        temporaryPassword: tempPassword // In production, send via email
      }
    });
  } catch (error) {
    console.error('Approve registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve registration request'
    });
  }
});

// @route   PUT /api/registrations/:id/reject
// @desc    Reject registration request
// @access  Private (Admin only)
router.put('/:id/reject', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { reviewNotes } = req.body;

    if (!reviewNotes) {
      return res.status(400).json({
        success: false,
        message: 'Review notes are required for rejection'
      });
    }

    const request = await RegistrationRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Registration request not found'
      });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Request has already been processed'
      });
    }

    // Update registration request
    await request.updateStatus(
      'rejected',
      req.user._id,
      req.user.name,
      reviewNotes
    );

    res.json({
      success: true,
      message: 'Registration request rejected successfully'
    });
  } catch (error) {
    console.error('Reject registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject registration request'
    });
  }
});

// @route   DELETE /api/registrations/:id
// @desc    Delete registration request
// @access  Private (Admin only)
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    const request = await RegistrationRequest.findByIdAndDelete(req.params.id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Registration request not found'
      });
    }

    res.json({
      success: true,
      message: 'Registration request deleted successfully'
    });
  } catch (error) {
    console.error('Delete registration request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete registration request'
    });
  }
});

module.exports = router;