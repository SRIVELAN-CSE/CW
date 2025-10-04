const express = require('express');
const router = express.Router();

const Feedback = require('../models/Feedback');
const { authenticate } = require('../middleware/auth');
const { validate, feedbackSchemas } = require('../middleware/validation');

// @route   GET /api/feedback
// @desc    Get feedback with filtering
// @access  Private (Admin/Officer can see all, users see their own)
router.get('/', authenticate, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      type,
      category,
      status,
      rating,
      userId,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    let filter = {};

    // Public users can only see their own feedback
    if (req.user.userType === 'public') {
      filter.userId = req.user._id;
    }

    if (type) filter.type = type;
    if (category) filter.category = category;
    if (status) filter.status = status;
    if (rating) filter.rating = parseInt(rating);
    if (userId && req.user.userType !== 'public') filter.userId = userId;

    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    const feedbacks = await Feedback.find(filter)
      .populate('userId', 'name email')
      .populate('response.respondedBy', 'name')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const totalFeedbacks = await Feedback.countDocuments(filter);

    res.json({
      success: true,
      data: {
        feedbacks,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalFeedbacks / parseInt(limit)),
          totalFeedbacks
        }
      }
    });
  } catch (error) {
    console.error('Get feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch feedback'
    });
  }
});

// @route   POST /api/feedback/public
// @desc    Submit new feedback (Public - no auth required)
// @access  Public
router.post('/public', async (req, res) => {
  try {
    console.log('💬 Creating public feedback:', req.body);
    
    const feedbackData = {
      type: req.body.type || 'general_suggestion',
      title: req.body.title,
      message: req.body.message,
      rating: req.body.rating,
      category: req.body.category || 'General',
      userName: req.body.userName || 'Anonymous',
      userEmail: req.body.userEmail || 'anonymous@example.com',
      isAnonymous: req.body.isAnonymous || false
    };

    console.log('🔍 Processed feedback data:', feedbackData);
    
    const feedback = await Feedback.create(feedbackData);
    console.log('✅ Feedback created with ID:', feedback._id);

    res.status(201).json({
      success: true,
      message: 'Feedback submitted successfully',
      data: { 
        feedback: {
          _id: feedback._id,
          type: feedback.type,
          title: feedback.title,
          rating: feedback.rating,
          category: feedback.category,
          createdAt: feedback.createdAt
        }
      }
    });
  } catch (error) {
    console.error('❌ Create public feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit feedback',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   POST /api/feedback
// @desc    Submit new feedback
// @access  Private
router.post('/', authenticate, validate(feedbackSchemas.create), async (req, res) => {
  try {
    const feedbackData = {
      ...req.body,
      userId: req.user._id,
      userName: req.user.name,
      userEmail: req.user.email
    };

    const feedback = await Feedback.create(feedbackData);

    res.status(201).json({
      success: true,
      message: 'Feedback submitted successfully',
      data: { feedback }
    });
  } catch (error) {
    console.error('Create feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit feedback'
    });
  }
});

// @route   GET /api/feedback/:id
// @desc    Get single feedback
// @access  Private
router.get('/:id', authenticate, async (req, res) => {
  try {
    const feedback = await Feedback.findById(req.params.id)
      .populate('userId', 'name email')
      .populate('response.respondedBy', 'name email');

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

    // Check access permissions
    const canView = 
      feedback.userId._id.toString() === req.user._id.toString() ||
      req.user.userType === 'admin' ||
      req.user.userType === 'officer';

    if (!canView) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: { feedback }
    });
  } catch (error) {
    console.error('Get feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch feedback'
    });
  }
});

// @route   POST /api/feedback/:id/respond
// @desc    Respond to feedback
// @access  Private (Admin/Officer only)
router.post('/:id/respond', authenticate, async (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        message: 'Response message is required'
      });
    }

    const feedback = await Feedback.findById(req.params.id);

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

    if (feedback.response && feedback.response.message) {
      return res.status(400).json({
        success: false,
        message: 'Feedback has already been responded to'
      });
    }

    await feedback.addResponse(message, req.user._id, req.user.name);

    res.json({
      success: true,
      message: 'Response added successfully',
      data: { feedback }
    });
  } catch (error) {
    console.error('Respond to feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to respond to feedback'
    });
  }
});

// @route   POST /api/feedback/:id/vote-helpful
// @desc    Vote feedback as helpful
// @access  Private
router.post('/:id/vote-helpful', authenticate, async (req, res) => {
  try {
    const feedback = await Feedback.findById(req.params.id);

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

    await feedback.voteHelpful(req.user._id);

    res.json({
      success: true,
      message: 'Vote recorded successfully',
      data: {
        helpfulVotes: feedback.helpfulVotes
      }
    });
  } catch (error) {
    console.error('Vote helpful error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to record vote'
    });
  }
});

module.exports = router;