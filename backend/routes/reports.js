const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const Report = require('../models/Report');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, reportSchemas } = require('../middleware/validation');

// @route   GET /api/reports/simple
// @desc    Get reports in simple array format (Flutter compatible)
// @access  Public
router.get('/simple', async (req, res) => {
  try {
    const reports = await Report.find()
      .populate('reporterId', 'name email')
      .populate('assignedOfficerId', 'name email department')
      .sort({ createdAt: -1 })
      .limit(50);

    // Return direct array for Flutter compatibility
    res.json(reports);
  } catch (error) {
    console.error('Get simple reports error:', error);
    res.status(500).json([]);
  }
});

// @route   GET /api/reports
// @desc    Get all reports with filtering and pagination
// @access  Public
router.get('/', async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      category,
      priority,
      department,
      reporterId,
      assignedOfficerId,
      search,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    // Build filter object
    const filter = {};
    
    if (status) filter.status = status;
    if (category) filter.category = category;
    if (priority) filter.priority = priority;
    if (department) filter.department = department;
    if (reporterId) filter.reporterId = reporterId;
    if (assignedOfficerId) filter.assignedOfficerId = assignedOfficerId;
    
    // Add text search
    if (search) {
      filter.$text = { $search: search };
    }

    // Calculate pagination
    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    // Execute query
    const reports = await Report.find(filter)
      .populate('reporterId', 'name email')
      .populate('assignedOfficerId', 'name email department')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const totalReports = await Report.countDocuments(filter);
    const totalPages = Math.ceil(totalReports / parseInt(limit));

    res.json({
      success: true,
      data: {
        reports,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalReports,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      }
    });
  } catch (error) {
    console.error('Get reports error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reports'
    });
  }
});

// @route   GET /api/reports/:id
// @desc    Get single report by ID
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const report = await Report.findById(req.params.id)
      .populate('reporterId', 'name email phone')
      .populate('assignedOfficerId', 'name email phone department')
      .populate('updates.updatedBy', 'name');

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    res.json({
      success: true,
      data: { report }
    });
  } catch (error) {
    console.error('Get report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch report'
    });
  }
});

// @route   POST /api/reports/:id/upvote
// @desc    Upvote a report
// @access  Private
router.post('/:id/upvote', authenticate, async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);
    
    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    const userId = req.user._id;
    const hasUpvoted = report.upvotedBy.includes(userId);

    if (hasUpvoted) {
      // Remove upvote
      report.upvotedBy = report.upvotedBy.filter(id => !id.equals(userId));
      report.upvotes = Math.max(0, report.upvotes - 1);
    } else {
      // Add upvote
      report.upvotedBy.push(userId);
      report.upvotes += 1;
    }

    await report.save();

    res.json({
      success: true,
      data: {
        reportId: report._id,
        upvotes: report.upvotes,
        hasUpvoted: !hasUpvoted
      }
    });

  } catch (error) {
    console.error('Upvote report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update upvote'
    });
  }
});

// @route   PUT /api/reports/:id/assign
// @desc    Assign report to officer (Admin only)
// @access  Private (Admin)
router.put('/:id/assign', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { officerId } = req.body;
    
    const report = await Report.findById(req.params.id);
    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    const officer = await User.findOne({
      _id: officerId,
      userType: 'officer',
      isActive: true
    });

    if (!officer) {
      return res.status(404).json({
        success: false,
        message: 'Officer not found or inactive'
      });
    }

    // Update report
    report.assignedOfficerId = officer._id;
    report.assignedOfficerName = officer.name;
    report.status = 'acknowledged';
    
    report.updates.push({
      message: `Report assigned to ${officer.name}`,
      status: 'acknowledged',
      updatedBy: req.user._id,
      updatedByName: req.user.name
    });

    await report.save();

    // Create notification for officer
    await Notification.create({
      title: 'New Report Assigned',
      message: `You have been assigned a new ${report.category} report: ${report.title}`,
      type: 'assignment',
      userId: officer._id,
      relatedId: report._id,
      relatedModel: 'Report',
      priority: report.priority === 'Critical' ? 'high' : 'medium'
    });

    // Send real-time notification
    const io = req.app.get('io');
    if (io) {
      io.to(`user_${officer._id}`).emit('newNotification', {
        title: 'New Assignment',
        message: `New ${report.category} report assigned to you`,
        reportId: report._id
      });
    }

    await report.populate('assignedOfficerId', 'name email department');

    res.json({
      success: true,
      message: 'Report assigned successfully',
      data: { report }
    });

  } catch (error) {
    console.error('Assign report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to assign report'
    });
  }
});

// @route   GET /api/reports/analytics/summary
// @desc    Get reports analytics summary
// @access  Private (Admin/Officer)
router.get('/analytics/summary', authenticate, authorize('admin', 'officer'), async (req, res) => {
  try {
    const { startDate, endDate, department } = req.query;
    
    // Build filter
    const filter = {};
    
    if (startDate && endDate) {
      filter.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }
    
    if (department) {
      filter.department = department;
    }
    
    // If officer, filter by their assignments
    if (req.user.userType === 'officer') {
      filter.assignedOfficerId = req.user._id;
    }

    const [
      totalReports,
      statusDistribution,
      categoryDistribution,
      priorityDistribution,
      departmentDistribution,
      monthlyTrend,
      averageResolutionTime,
      topIssueLocations
    ] = await Promise.all([
      Report.countDocuments(filter),
      
      Report.aggregate([
        { $match: filter },
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ]),
      
      Report.aggregate([
        { $match: filter },
        { $group: { _id: '$category', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),
      
      Report.aggregate([
        { $match: filter },
        { $group: { _id: '$priority', count: { $sum: 1 } } }
      ]),
      
      Report.aggregate([
        { $match: filter },
        { $group: { _id: '$department', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),
      
      // Monthly trend for the last 12 months
      Report.aggregate([
        { $match: filter },
        {
          $group: {
            _id: {
              year: { $year: '$createdAt' },
              month: { $month: '$createdAt' }
            },
            count: { $sum: 1 }
          }
        },
        { $sort: { '_id.year': 1, '_id.month': 1 } }
      ]),
      
      // Average resolution time
      Report.aggregate([
        {
          $match: {
            ...filter,
            status: 'resolved',
            resolvedAt: { $exists: true }
          }
        },
        {
          $project: {
            resolutionTime: {
              $divide: [
                { $subtract: ['$resolvedAt', '$createdAt'] },
                1000 * 60 * 60 * 24 // Convert to days
              ]
            }
          }
        },
        {
          $group: {
            _id: null,
            avgResolutionTime: { $avg: '$resolutionTime' }
          }
        }
      ]),
      
      // Top issue locations
      Report.aggregate([
        { $match: filter },
        { $group: { _id: '$location', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 }
      ])
    ]);

    res.json({
      success: true,
      data: {
        overview: {
          totalReports,
          averageResolutionTime: averageResolutionTime[0]?.avgResolutionTime || 0
        },
        distributions: {
          status: statusDistribution.map(item => ({
            name: item._id,
            value: item.count
          })),
          category: categoryDistribution.map(item => ({
            name: item._id,
            value: item.count
          })),
          priority: priorityDistribution.map(item => ({
            name: item._id,
            value: item.count
          })),
          department: departmentDistribution.map(item => ({
            name: item._id,
            value: item.count
          }))
        },
        trends: {
          monthly: monthlyTrend.map(item => ({
            month: `${item._id.year}-${String(item._id.month).padStart(2, '0')}`,
            count: item.count
          }))
        },
        topLocations: topIssueLocations.map(item => ({
          location: item._id,
          count: item.count
        }))
      }
    });

  } catch (error) {
    console.error('Reports analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reports analytics'
    });
  }
});

// @route   POST /api/reports/public
// @desc    Create a new report (Public - no auth required)
// @access  Public
router.post('/public', async (req, res) => {
  try {
    console.log('📝 Creating public report:', req.body);
    
    const reportData = {
      title: req.body.title,
      description: req.body.description,
      category: req.body.category,
      location: req.body.location,
      address: req.body.address,
      latitude: req.body.latitude,
      longitude: req.body.longitude,
      priority: req.body.priority || 'Medium',
      reporterName: req.body.reporter_name || req.body.reporterName || 'Anonymous',
      reporterEmail: req.body.reporter_email || req.body.reporterEmail || 'anonymous@example.com',
      reporterPhone: req.body.reporter_phone || req.body.reporterPhone || 'Not provided',
      imageUrls: req.body.imageUrls || [],
      tags: req.body.tags || [],
      status: 'submitted'
    };

    console.log('🔍 Processed report data:', reportData);
    
    const report = await Report.create(reportData);
    console.log('✅ Report created with ID:', report._id);

    // Create notification for admins about new report
    const adminUsers = await require('../models/User').find({ userType: 'admin' });
    
    for (const admin of adminUsers) {
      await Notification.create({
        title: 'New Report Submitted',
        message: `A new ${report.category} report has been submitted by ${report.reporterName}`,
        type: 'report_update',
        userId: admin._id,
        relatedId: report._id,
        relatedModel: 'Report',
        priority: report.priority === 'Critical' ? 'high' : 'medium'
      });
    }

    res.status(201).json({
      success: true,
      message: 'Report submitted successfully',
      data: { 
        report: {
          _id: report._id,
          title: report.title,
          category: report.category,
          status: report.status,
          priority: report.priority,
          createdAt: report.createdAt
        }
      }
    });
  } catch (error) {
    console.error('❌ Create public report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create report',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   POST /api/reports
// @desc    Create a new report
// @access  Private
router.post('/', authenticate, validate(reportSchemas.create), async (req, res) => {
  try {
    const reportData = {
      ...req.body,
      reporterId: req.user._id,
      reporterName: req.user.name,
      reporterEmail: req.user.email,
      reporterPhone: req.user.phone
    };

    const report = await Report.create(reportData);

    // Populate the created report
    await report.populate('reporterId', 'name email phone');

    // Create notification for admins about new report
    const adminUsers = await require('../models/User').find({ userType: 'admin' });
    
    for (const admin of adminUsers) {
      await Notification.create({
        title: 'New Report Submitted',
        message: `A new ${report.category} report has been submitted by ${report.reporterName}`,
        type: 'report_update',
        userId: admin._id,
        relatedId: report._id,
        relatedModel: 'Report',
        priority: report.priority === 'Critical' ? 'high' : 'medium'
      });
    }

    // Send real-time notification
    const io = req.app.get('io');
    if (io) {
      adminUsers.forEach(admin => {
        io.to(`user_${admin._id}`).emit('newNotification', {
          title: 'New Report Submitted',
          message: `New ${report.category} report from ${report.reporterName}`,
          reportId: report._id
        });
      });
    }

    res.status(201).json({
      success: true,
      message: 'Report submitted successfully',
      data: { report }
    });
  } catch (error) {
    console.error('Create report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create report'
    });
  }
});

// @route   PUT /api/reports/:id
// @desc    Update report
// @access  Private (Only reporter, assigned officer, or admin)
router.put('/:id', authenticate, validate(reportSchemas.update), async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    // Check permissions
    const canUpdate = 
      report.reporterId.toString() === req.user._id.toString() ||
      (report.assignedOfficerId && report.assignedOfficerId.toString() === req.user._id.toString()) ||
      req.user.userType === 'admin';

    if (!canUpdate) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this report'
      });
    }

    const updates = req.body;
    
    // If status is being updated, add to updates array
    if (updates.status && updates.status !== report.status) {
      const statusMessages = {
        acknowledged: 'Report has been acknowledged',
        in_progress: 'Work on this report has started',
        resolved: 'Report has been resolved',
        closed: 'Report has been closed'
      };

      report.updates.push({
        message: statusMessages[updates.status] || `Status updated to ${updates.status}`,
        status: updates.status,
        updatedBy: req.user._id,
        updatedByName: req.user.name
      });
    }

    // Update the report
    Object.assign(report, updates);
    await report.save();

    // Populate the updated report
    await report.populate('reporterId', 'name email phone');
    await report.populate('assignedOfficerId', 'name email phone department');

    // Create notification for reporter if status changed
    if (updates.status && updates.status !== report.status) {
      await Notification.create({
        title: 'Report Status Updated',
        message: `Your report "${report.title}" status has been updated to ${updates.status}`,
        type: 'report_update',
        userId: report.reporterId,
        relatedId: report._id,
        relatedModel: 'Report'
      });

      // Send real-time notification
      const io = req.app.get('io');
      if (io) {
        io.to(`user_${report.reporterId}`).emit('reportUpdate', {
          reportId: report._id,
          status: updates.status,
          message: `Report status updated to ${updates.status}`
        });
      }
    }

    res.json({
      success: true,
      message: 'Report updated successfully',
      data: { report }
    });
  } catch (error) {
    console.error('Update report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update report'
    });
  }
});

// @route   POST /api/reports/:id/assign
// @desc    Assign report to officer
// @access  Private (Admin only)
router.post('/:id/assign', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { officerId } = req.body;

    if (!officerId) {
      return res.status(400).json({
        success: false,
        message: 'Officer ID is required'
      });
    }

    const report = await Report.findById(req.params.id);
    const officer = await require('../models/User').findById(officerId);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    if (!officer || officer.userType !== 'officer') {
      return res.status(400).json({
        success: false,
        message: 'Invalid officer'
      });
    }

    // Update report
    report.assignedOfficerId = officer._id;
    report.assignedOfficerName = officer.name;
    report.status = 'acknowledged';
    
    report.updates.push({
      message: `Report assigned to ${officer.name}`,
      status: 'acknowledged',
      updatedBy: req.user._id,
      updatedByName: req.user.name
    });

    await report.save();

    // Create notifications
    await Promise.all([
      // Notification for the assigned officer
      Notification.create({
        title: 'Report Assigned',
        message: `You have been assigned a new ${report.category} report`,
        type: 'assignment',
        userId: officer._id,
        relatedId: report._id,
        relatedModel: 'Report',
        priority: 'high'
      }),
      // Notification for the reporter
      Notification.create({
        title: 'Report Assigned',
        message: `Your report has been assigned to ${officer.name}`,
        type: 'report_update',
        userId: report.reporterId,
        relatedId: report._id,
        relatedModel: 'Report'
      })
    ]);

    // Send real-time notifications
    const io = req.app.get('io');
    if (io) {
      io.to(`user_${officer._id}`).emit('reportAssigned', {
        reportId: report._id,
        title: report.title,
        category: report.category
      });

      io.to(`user_${report.reporterId}`).emit('reportUpdate', {
        reportId: report._id,
        status: 'acknowledged',
        assignedOfficer: officer.name
      });
    }

    res.json({
      success: true,
      message: 'Report assigned successfully',
      data: { report }
    });
  } catch (error) {
    console.error('Assign report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to assign report'
    });
  }
});

// @route   POST /api/reports/:id/upvote
// @desc    Upvote a report
// @access  Private
router.post('/:id/upvote', authenticate, async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    // Check if user already upvoted
    if (report.upvotedBy.includes(req.user._id)) {
      return res.status(400).json({
        success: false,
        message: 'You have already upvoted this report'
      });
    }

    // Add upvote
    report.upvotedBy.push(req.user._id);
    report.upvotes += 1;
    await report.save();

    res.json({
      success: true,
      message: 'Report upvoted successfully',
      data: {
        upvotes: report.upvotes
      }
    });
  } catch (error) {
    console.error('Upvote report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upvote report'
    });
  }
});

// @route   DELETE /api/reports/:id
// @desc    Delete report
// @access  Private (Only reporter or admin)
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    // Check permissions
    const canDelete = 
      report.reporterId.toString() === req.user._id.toString() ||
      req.user.userType === 'admin';

    if (!canDelete) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this report'
      });
    }

    await Report.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Report deleted successfully'
    });
  } catch (error) {
    console.error('Delete report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete report'
    });
  }
});

// @route   GET /api/reports/stats/overview
// @desc    Get reports statistics
// @access  Private (Admin and officers)
router.get('/stats/overview', authenticate, authorize('admin', 'officer'), async (req, res) => {
  try {
    const stats = await Promise.all([
      Report.countDocuments({ status: 'submitted' }),
      Report.countDocuments({ status: 'in_progress' }),
      Report.countDocuments({ status: 'resolved' }),
      Report.countDocuments({ status: 'closed' }),
      Report.countDocuments(),
      Report.aggregate([
        {
          $group: {
            _id: '$category',
            count: { $sum: 1 }
          }
        },
        { $sort: { count: -1 } }
      ]),
      Report.aggregate([
        {
          $group: {
            _id: '$priority',
            count: { $sum: 1 }
          }
        }
      ])
    ]);

    res.json({
      success: true,
      data: {
        statusCounts: {
          submitted: stats[0],
          inProgress: stats[1],
          resolved: stats[2],
          closed: stats[3],
          total: stats[4]
        },
        categoryStats: stats[5],
        priorityStats: stats[6]
      }
    });
  } catch (error) {
    console.error('Get report stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch report statistics'
    });
  }
});

module.exports = router;