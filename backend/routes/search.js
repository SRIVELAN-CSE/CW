const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const Report = require('../models/Report');
const User = require('../models/User');
const Certificate = require('../models/Certificate');
const NeedRequest = require('../models/NeedRequest');
const Feedback = require('../models/Feedback');
const { authenticate, authorize } = require('../middleware/auth');

// @route   GET /api/search/global
// @desc    Global search across all entities
// @access  Private
router.get('/global', authenticate, async (req, res) => {
  try {
    const { q, type = 'all', limit = 10 } = req.query;

    if (!q || q.trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Search query must be at least 2 characters long'
      });
    }

    const searchRegex = new RegExp(q, 'i');
    const results = {};

    // Search Reports
    if (type === 'all' || type === 'reports') {
      let reportFilter = {
        $or: [
          { title: searchRegex },
          { description: searchRegex },
          { location: searchRegex },
          { category: searchRegex }
        ]
      };

      // Filter by user role
      if (req.user.userType === 'officer') {
        reportFilter.assignedOfficerId = req.user._id;
      } else if (req.user.userType === 'public') {
        reportFilter.reporterId = req.user._id;
      }

      results.reports = await Report.find(reportFilter)
        .populate('reporterId', 'name email')
        .populate('assignedOfficerId', 'name email')
        .limit(parseInt(limit))
        .lean();
    }

    // Search Users (Admin only)
    if ((type === 'all' || type === 'users') && req.user.userType === 'admin') {
      results.users = await User.find({
        $or: [
          { name: searchRegex },
          { email: searchRegex },
          { phone: searchRegex }
        ]
      })
      .select('name email phone userType department isActive')
      .limit(parseInt(limit))
      .lean();
    }

    // Search Certificates
    if (type === 'all' || type === 'certificates') {
      let certFilter = {
        $or: [
          { 'applicationDetails.fullName': searchRegex },
          { certificateType: searchRegex },
          { applicationNumber: searchRegex }
        ]
      };

      if (req.user.userType === 'public') {
        certFilter.applicantId = req.user._id;
      }

      results.certificates = await Certificate.find(certFilter)
        .populate('applicantId', 'name email')
        .limit(parseInt(limit))
        .lean();
    }

    // Search Need Requests
    if (type === 'all' || type === 'needs') {
      let needFilter = {
        $or: [
          { title: searchRegex },
          { description: searchRegex },
          { category: searchRegex }
        ]
      };

      if (req.user.userType === 'public') {
        needFilter.requesterId = req.user._id;
      }

      results.needRequests = await NeedRequest.find(needFilter)
        .populate('requesterId', 'name email')
        .limit(parseInt(limit))
        .lean();
    }

    // Search Feedback (Admin/Officer only)
    if ((type === 'all' || type === 'feedback') && 
        ['admin', 'officer'].includes(req.user.userType)) {
      results.feedback = await Feedback.find({
        $or: [
          { subject: searchRegex },
          { message: searchRegex },
          { category: searchRegex }
        ]
      })
      .populate('userId', 'name email')
      .limit(parseInt(limit))
      .lean();
    }

    // Calculate total results
    const totalResults = Object.values(results).reduce((sum, arr) => sum + arr.length, 0);

    res.json({
      success: true,
      data: {
        query: q,
        totalResults,
        results
      }
    });

  } catch (error) {
    console.error('Global search error:', error);
    res.status(500).json({
      success: false,
      message: 'Search failed'
    });
  }
});

// @route   GET /api/search/suggestions
// @desc    Get search suggestions
// @access  Private
router.get('/suggestions', authenticate, async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length < 2) {
      return res.json({
        success: true,
        data: { suggestions: [] }
      });
    }

    const searchRegex = new RegExp(q, 'i');
    const suggestions = [];

    // Get category suggestions
    const categories = await Report.distinct('category', {
      category: searchRegex
    });
    suggestions.push(...categories.map(cat => ({ type: 'category', value: cat })));

    // Get location suggestions
    const locations = await Report.distinct('location', {
      location: searchRegex
    });
    suggestions.push(...locations.slice(0, 5).map(loc => ({ type: 'location', value: loc })));

    // Get user suggestions (Admin only)
    if (req.user.userType === 'admin') {
      const users = await User.find({
        $or: [
          { name: searchRegex },
          { email: searchRegex }
        ]
      })
      .select('name email')
      .limit(5)
      .lean();

      suggestions.push(...users.map(user => ({ 
        type: 'user', 
        value: user.name,
        email: user.email 
      })));
    }

    // Remove duplicates and limit
    const uniqueSuggestions = suggestions
      .filter((item, index, self) => 
        index === self.findIndex(i => i.value === item.value)
      )
      .slice(0, 10);

    res.json({
      success: true,
      data: {
        suggestions: uniqueSuggestions
      }
    });

  } catch (error) {
    console.error('Search suggestions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get suggestions'
    });
  }
});

// @route   GET /api/search/advanced
// @desc    Advanced search with filters
// @access  Private
router.get('/advanced', authenticate, async (req, res) => {
  try {
    const {
      q,
      type = 'reports',
      dateFrom,
      dateTo,
      status,
      category,
      priority,
      department,
      page = 1,
      limit = 20,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    let filter = {};
    
    // Text search
    if (q && q.trim().length >= 2) {
      const searchRegex = new RegExp(q, 'i');
      
      if (type === 'reports') {
        filter.$or = [
          { title: searchRegex },
          { description: searchRegex },
          { location: searchRegex }
        ];
      }
    }

    // Date range filter
    if (dateFrom || dateTo) {
      filter.createdAt = {};
      if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
      if (dateTo) filter.createdAt.$lte = new Date(dateTo);
    }

    // Additional filters
    if (status) filter.status = status;
    if (category) filter.category = category;
    if (priority) filter.priority = priority;
    if (department) filter.department = department;

    // Role-based filtering
    if (req.user.userType === 'officer' && type === 'reports') {
      filter.assignedOfficerId = req.user._id;
    } else if (req.user.userType === 'public' && type === 'reports') {
      filter.reporterId = req.user._id;
    }

    // Pagination
    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    let Model, populateFields = [];
    
    switch (type) {
      case 'reports':
        Model = Report;
        populateFields = [
          { path: 'reporterId', select: 'name email' },
          { path: 'assignedOfficerId', select: 'name email department' }
        ];
        break;
      case 'certificates':
        Model = Certificate;
        populateFields = [
          { path: 'applicantId', select: 'name email' },
          { path: 'processingOfficer', select: 'name email' }
        ];
        break;
      case 'users':
        if (req.user.userType !== 'admin') {
          return res.status(403).json({
            success: false,
            message: 'Access denied'
          });
        }
        Model = User;
        break;
      default:
        return res.status(400).json({
          success: false,
          message: 'Invalid search type'
        });
    }

    let query = Model.find(filter);
    
    if (populateFields.length > 0) {
      populateFields.forEach(field => {
        query = query.populate(field.path, field.select);
      });
    }

    const [results, totalCount] = await Promise.all([
      query.sort(sortObj).skip(skip).limit(parseInt(limit)).lean(),
      Model.countDocuments(filter)
    ]);

    res.json({
      success: true,
      data: {
        results,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalCount / parseInt(limit)),
          totalResults: totalCount,
          hasNext: page < Math.ceil(totalCount / parseInt(limit)),
          hasPrev: page > 1
        },
        filters: {
          type,
          query: q,
          dateRange: { from: dateFrom, to: dateTo },
          status,
          category,
          priority,
          department
        }
      }
    });

  } catch (error) {
    console.error('Advanced search error:', error);
    res.status(500).json({
      success: false,
      message: 'Advanced search failed'
    });
  }
});

module.exports = router;