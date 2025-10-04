const express = require('express');
const router = express.Router();

const NeedRequest = require('../models/NeedRequest');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, needRequestSchemas } = require('../middleware/validation');

// @route   GET /api/need-requests
// @desc    Get all need requests with filtering
// @access  Public
router.get('/', async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      category,
      status,
      urgencyLevel,
      requesterId,
      search,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    const filter = {};
    if (category) filter.category = category;
    if (status) filter.status = status;
    if (urgencyLevel) filter.urgencyLevel = urgencyLevel;
    if (requesterId) filter.requesterId = requesterId;

    if (search) {
      filter.$text = { $search: search };
    }

    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    const requests = await NeedRequest.find(filter)
      .populate('requesterId', 'name email')
      .populate('assignedTo', 'name email')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const totalRequests = await NeedRequest.countDocuments(filter);

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
    console.error('Get need requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch need requests'
    });
  }
});

// @route   POST /api/need-requests/public
// @desc    Create new need request (Public - no auth required)
// @access  Public
router.post('/public', async (req, res) => {
  try {
    console.log('🤲 Creating public need request:', req.body);
    
    const requestData = {
      title: req.body.title,
      description: req.body.description,
      category: req.body.category,
      location: req.body.location,
      address: req.body.address,
      urgencyLevel: req.body.urgencyLevel || 'Medium',
      beneficiaryCount: req.body.beneficiaryCount || 1,
      estimatedCost: req.body.estimatedCost || 0,
      requesterName: req.body.requesterName || 'Anonymous',
      requesterEmail: req.body.requesterEmail || 'anonymous@example.com',
      requesterPhone: req.body.requesterPhone || 'Not provided',
      status: 'submitted'
    };

    console.log('🔍 Processed need request data:', requestData);
    
    const needRequest = await NeedRequest.create(requestData);
    console.log('✅ Need request created with ID:', needRequest._id);

    // Notify admins
    const adminUsers = await require('../models/User').find({ userType: 'admin' });
    
    for (const admin of adminUsers) {
      await Notification.create({
        title: 'New Need Request',
        message: `New ${needRequest.category} request from ${needRequest.requesterName}`,
        type: 'system_alert',
        userId: admin._id,
        relatedId: needRequest._id,
        relatedModel: 'NeedRequest',
        priority: needRequest.urgencyLevel === 'Critical' ? 'high' : 'medium'
      });
    }

    res.status(201).json({
      success: true,
      message: 'Need request submitted successfully',
      data: { 
        needRequest: {
          _id: needRequest._id,
          title: needRequest.title,
          category: needRequest.category,
          status: needRequest.status,
          urgencyLevel: needRequest.urgencyLevel,
          createdAt: needRequest.createdAt
        }
      }
    });
  } catch (error) {
    console.error('❌ Create public need request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create need request',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   POST /api/need-requests
// @desc    Create new need request
// @access  Private
router.post('/', authenticate, validate(needRequestSchemas.create), async (req, res) => {
  try {
    const requestData = {
      ...req.body,
      requesterId: req.user._id,
      requesterName: req.user.name,
      requesterEmail: req.user.email,
      requesterPhone: req.user.phone
    };

    const needRequest = await NeedRequest.create(requestData);

    // Notify admins
    const adminUsers = await require('../models/User').find({ userType: 'admin' });
    
    for (const admin of adminUsers) {
      await Notification.create({
        title: 'New Need Request',
        message: `New ${needRequest.category} request from ${needRequest.requesterName}`,
        type: 'system_alert',
        userId: admin._id,
        relatedId: needRequest._id,
        relatedModel: 'NeedRequest',
        priority: needRequest.urgencyLevel === 'Critical' ? 'high' : 'medium'
      });
    }

    res.status(201).json({
      success: true,
      message: 'Need request submitted successfully',
      data: { request: needRequest }
    });
  } catch (error) {
    console.error('Create need request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create need request'
    });
  }
});

// @route   GET /api/need-requests/:id
// @desc    Get single need request
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const request = await NeedRequest.findById(req.params.id)
      .populate('requesterId', 'name email phone')
      .populate('assignedTo', 'name email phone')
      .populate('updates.updatedBy', 'name');

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Need request not found'
      });
    }

    res.json({
      success: true,
      data: { request }
    });
  } catch (error) {
    console.error('Get need request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch need request'
    });
  }
});

// @route   PUT /api/need-requests/:id/assign
// @desc    Assign need request to user
// @access  Private (Admin only)
router.put('/:id/assign', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { assignedToId } = req.body;

    const request = await NeedRequest.findById(req.params.id);
    const assignee = await require('../models/User').findById(assignedToId);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Need request not found'
      });
    }

    if (!assignee) {
      return res.status(400).json({
        success: false,
        message: 'Invalid assignee'
      });
    }

    await request.assignTo(assignee._id, assignee.name);

    // Create notification
    await Notification.create({
      title: 'Need Request Assigned',
      message: `You have been assigned a ${request.category} request`,
      type: 'assignment',
      userId: assignee._id,
      relatedId: request._id,
      relatedModel: 'NeedRequest',
      priority: 'high'
    });

    res.json({
      success: true,
      message: 'Need request assigned successfully',
      data: { request }
    });
  } catch (error) {
    console.error('Assign need request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to assign need request'
    });
  }
});

module.exports = router;