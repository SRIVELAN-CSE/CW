const express = require('express');
const router = express.Router();

const Report = require('../models/Report');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, reportSchemas } = require('../middleware/validation');

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