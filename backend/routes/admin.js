const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;

const User = require('../models/User');
const Report = require('../models/Report');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../uploads/reports');
    try {
      await fs.mkdir(uploadPath, { recursive: true });
      cb(null, uploadPath);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `report-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|mp4|mov|avi/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image and video files are allowed'));
    }
  }
});

// @route   POST /api/admin/assign-officer
// @desc    Auto-assign officer to report based on department and workload
// @access  Private (Admin only)
router.post('/assign-officer', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { reportId, officerId } = req.body;

    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: 'Report ID is required'
      });
    }

    const report = await Report.findById(reportId);
    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    let assignedOfficer;

    if (officerId) {
      // Manual assignment
      assignedOfficer = await User.findOne({
        _id: officerId,
        userType: 'officer',
        isActive: true
      });

      if (!assignedOfficer) {
        return res.status(404).json({
          success: false,
          message: 'Officer not found or inactive'
        });
      }
    } else {
      // Auto-assignment based on department and workload
      const departmentOfficers = await User.find({
        userType: 'officer',
        department: report.department,
        isActive: true
      });

      if (departmentOfficers.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'No active officers found for this department'
        });
      }

      // Calculate workload for each officer
      const officerWorkloads = await Promise.all(
        departmentOfficers.map(async (officer) => {
          const activeReports = await Report.countDocuments({
            assignedOfficerId: officer._id,
            status: { $in: ['submitted', 'acknowledged', 'in_progress'] }
          });
          return { officer, workload: activeReports };
        })
      );

      // Sort by workload (ascending) to get the officer with least workload
      officerWorkloads.sort((a, b) => a.workload - b.workload);
      assignedOfficer = officerWorkloads[0].officer;
    }

    // Update report with assigned officer
    report.assignedOfficerId = assignedOfficer._id;
    report.assignedOfficerName = assignedOfficer.name;
    report.status = 'acknowledged';
    
    // Add update to report history
    report.updates.push({
      message: `Report assigned to ${assignedOfficer.name}`,
      status: 'acknowledged',
      updatedBy: req.user._id,
      updatedByName: req.user.name
    });

    await report.save();

    // Create notification for assigned officer
    await Notification.create({
      title: 'New Report Assigned',
      message: `You have been assigned a new ${report.category} report: ${report.title}`,
      type: 'assignment',
      userId: assignedOfficer._id,
      relatedId: report._id,
      relatedModel: 'Report',
      priority: report.priority === 'Critical' ? 'high' : 'medium'
    });

    // Send real-time notification
    const io = req.app.get('io');
    if (io) {
      io.to(`user_${assignedOfficer._id}`).emit('newNotification', {
        title: 'New Assignment',
        message: `New ${report.category} report assigned to you`,
        reportId: report._id
      });
    }

    res.json({
      success: true,
      message: 'Officer assigned successfully',
      data: {
        report: {
          id: report._id,
          title: report.title,
          assignedOfficer: {
            id: assignedOfficer._id,
            name: assignedOfficer.name,
            email: assignedOfficer.email,
            department: assignedOfficer.department
          }
        }
      }
    });

  } catch (error) {
    console.error('Officer assignment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to assign officer'
    });
  }
});

// @route   POST /api/admin/bulk-assign
// @desc    Bulk assign multiple reports to officers
// @access  Private (Admin only)
router.post('/bulk-assign', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { reportIds, assignmentType = 'auto' } = req.body;

    if (!Array.isArray(reportIds) || reportIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Report IDs array is required'
      });
    }

    const reports = await Report.find({ _id: { $in: reportIds } });
    
    if (reports.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No valid reports found'
      });
    }

    const assignmentResults = [];

    for (const report of reports) {
      try {
        // Skip if already assigned
        if (report.assignedOfficerId) {
          assignmentResults.push({
            reportId: report._id,
            success: false,
            message: 'Already assigned'
          });
          continue;
        }

        // Find officers for this department
        const departmentOfficers = await User.find({
          userType: 'officer',
          department: report.department,
          isActive: true
        });

        if (departmentOfficers.length === 0) {
          assignmentResults.push({
            reportId: report._id,
            success: false,
            message: 'No officers available for department'
          });
          continue;
        }

        // Get officer with least workload
        const officerWorkloads = await Promise.all(
          departmentOfficers.map(async (officer) => {
            const activeReports = await Report.countDocuments({
              assignedOfficerId: officer._id,
              status: { $in: ['submitted', 'acknowledged', 'in_progress'] }
            });
            return { officer, workload: activeReports };
          })
        );

        officerWorkloads.sort((a, b) => a.workload - b.workload);
        const assignedOfficer = officerWorkloads[0].officer;

        // Update report
        report.assignedOfficerId = assignedOfficer._id;
        report.assignedOfficerName = assignedOfficer.name;
        report.status = 'acknowledged';
        
        report.updates.push({
          message: `Bulk assigned to ${assignedOfficer.name}`,
          status: 'acknowledged',
          updatedBy: req.user._id,
          updatedByName: req.user.name
        });

        await report.save();

        // Create notification
        await Notification.create({
          title: 'New Report Assigned',
          message: `You have been assigned a ${report.category} report: ${report.title}`,
          type: 'assignment',
          userId: assignedOfficer._id,
          relatedId: report._id,
          relatedModel: 'Report'
        });

        assignmentResults.push({
          reportId: report._id,
          success: true,
          assignedTo: assignedOfficer.name
        });

      } catch (error) {
        assignmentResults.push({
          reportId: report._id,
          success: false,
          message: error.message
        });
      }
    }

    res.json({
      success: true,
      message: 'Bulk assignment completed',
      data: {
        totalReports: reportIds.length,
        successful: assignmentResults.filter(r => r.success).length,
        failed: assignmentResults.filter(r => !r.success).length,
        results: assignmentResults
      }
    });

  } catch (error) {
    console.error('Bulk assignment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to perform bulk assignment'
    });
  }
});

// @route   POST /api/admin/system-announcement
// @desc    Create system-wide announcement
// @access  Private (Admin only)
router.post('/system-announcement', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { title, message, priority = 'medium', targetUserTypes = ['public', 'officer'] } = req.body;

    if (!title || !message) {
      return res.status(400).json({
        success: false,
        message: 'Title and message are required'
      });
    }

    // Get target users
    const targetUsers = await User.find({
      userType: { $in: targetUserTypes },
      isActive: true
    }).select('_id');

    // Create notifications for all target users
    const notifications = targetUsers.map(user => ({
      title: `System Announcement: ${title}`,
      message: message,
      type: 'system_announcement',
      userId: user._id,
      priority: priority,
      isSystemMessage: true
    }));

    await Notification.insertMany(notifications);

    // Send real-time notifications
    const io = req.app.get('io');
    if (io) {
      targetUsers.forEach(user => {
        io.to(`user_${user._id}`).emit('systemAnnouncement', {
          title: title,
          message: message,
          priority: priority
        });
      });
    }

    res.json({
      success: true,
      message: 'System announcement sent successfully',
      data: {
        title,
        message,
        targetUsers: targetUsers.length,
        priority
      }
    });

  } catch (error) {
    console.error('System announcement error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send system announcement'
    });
  }
});

// @route   GET /api/admin/system-health
// @desc    Get system health information
// @access  Private (Admin only)
router.get('/system-health', authenticate, authorize('admin'), async (req, res) => {
  try {
    const [
      totalUsers,
      activeUsers,
      inactiveUsers,
      totalReports,
      unassignedReports,
      overdueReports,
      systemNotifications
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ isActive: true }),
      User.countDocuments({ isActive: false }),
      Report.countDocuments(),
      Report.countDocuments({ assignedOfficerId: null }),
      Report.countDocuments({ 
        status: { $in: ['submitted', 'acknowledged'] },
        createdAt: { $lt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } // 7 days old
      }),
      Notification.countDocuments({ 
        type: 'system_announcement',
        createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } // Last 30 days
      })
    ]);

    // Database connection status
    const dbStatus = {
      connected: require('mongoose').connection.readyState === 1,
      status: require('mongoose').connection.readyState
    };

    // System performance metrics
    const performanceMetrics = {
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage()
    };

    // Health score calculation (0-100)
    let healthScore = 100;
    
    if (!dbStatus.connected) healthScore -= 50;
    if (unassignedReports > totalReports * 0.1) healthScore -= 20; // More than 10% unassigned
    if (overdueReports > totalReports * 0.05) healthScore -= 15; // More than 5% overdue
    if (inactiveUsers > totalUsers * 0.3) healthScore -= 10; // More than 30% inactive
    if (performanceMetrics.uptime < 3600) healthScore -= 5; // Less than 1 hour uptime

    const healthStatus = healthScore >= 80 ? 'healthy' : 
                        healthScore >= 60 ? 'warning' : 'critical';

    res.json({
      success: true,
      data: {
        healthScore,
        healthStatus,
        database: dbStatus,
        performance: performanceMetrics,
        statistics: {
          users: {
            total: totalUsers,
            active: activeUsers,
            inactive: inactiveUsers
          },
          reports: {
            total: totalReports,
            unassigned: unassignedReports,
            overdue: overdueReports
          },
          system: {
            recentAnnouncements: systemNotifications
          }
        },
        alerts: [
          ...(unassignedReports > 0 ? [{
            type: 'warning',
            message: `${unassignedReports} reports are unassigned`
          }] : []),
          ...(overdueReports > 0 ? [{
            type: 'error',
            message: `${overdueReports} reports are overdue`
          }] : []),
          ...(!dbStatus.connected ? [{
            type: 'critical',
            message: 'Database connection issue detected'
          }] : [])
        ]
      }
    });

  } catch (error) {
    console.error('System health check error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch system health information'
    });
  }
});

// @route   POST /api/admin/upload-report-media
// @desc    Upload media files for reports
// @access  Private (Admin/Officer)
router.post('/upload-report-media', authenticate, authorize('admin', 'officer'), 
  upload.array('media', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No files uploaded'
      });
    }

    const uploadedFiles = req.files.map(file => ({
      filename: file.filename,
      originalName: file.originalname,
      path: `/uploads/reports/${file.filename}`,
      size: file.size,
      mimetype: file.mimetype,
      url: `${req.protocol}://${req.get('host')}/uploads/reports/${file.filename}`
    }));

    res.json({
      success: true,
      message: 'Files uploaded successfully',
      data: {
        files: uploadedFiles
      }
    });

  } catch (error) {
    console.error('File upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload files'
    });
  }
});

module.exports = router;