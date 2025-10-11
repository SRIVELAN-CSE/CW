const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const Report = require('../models/Report');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');
const { validateReport, validateReportUpdate } = require('../middleware/validation');
const smartCategorizationService = require('../services/smartCategorizationService');

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
    files: 5 // Maximum 5 files
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'video/mp4', 'video/quicktime'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only images and videos are allowed'), false);
    }
  }
});

/**
 * @route   POST /api/reports
 * @desc    Create a new report
 * @access  Private (Citizen, Officer, Admin)
 */
router.post('/', authenticate, validateReport, upload.array('files', 5), async (req, res) => {
  try {
    const {
      title,
      description,
      category,
      subcategory,
      location,
      priority,
      urgency,
      impact,
      affectedPeople,
      isAnonymous = false,
      allowCommunication = true,
      publiclyVisible = true
    } = req.body;

    const userId = req.user.id;
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Parse location if it's a string
    let parsedLocation;
    try {
      parsedLocation = typeof location === 'string' ? JSON.parse(location) : location;
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid location format'
      });
    }

    // Use smart categorization service if available
    let smartCategory = category;
    let aiCategorized = false;
    let aiConfidenceScore = 0;
    let keywords = [];

    try {
      const categorization = await smartCategorizationService.categorizeReport({
        title,
        description,
        category,
        location: parsedLocation
      });

      if (categorization.confidence > 0.7) {
        smartCategory = categorization.suggestedCategory;
        aiCategorized = true;
        aiConfidenceScore = categorization.confidence;
        keywords = categorization.keywords;
      }
    } catch (error) {
      console.warn('Smart categorization failed:', error.message);
    }

    // Create report object
    const reportData = {
      title,
      description,
      category: smartCategory,
      subcategory,
      location: parsedLocation,
      priority: priority || 'medium',
      urgency: urgency || 'medium',
      impact: impact || 'community',
      affectedPeople: affectedPeople || 1,
      submittedBy: userId,
      submittedByName: isAnonymous ? 'Anonymous' : user.name,
      submittedByPhone: user.phone,
      submittedByEmail: user.email,
      isAnonymous,
      allowCommunication,
      publiclyVisible,
      aiCategorized,
      aiConfidenceScore,
      keywords,
      source: req.headers['user-agent']?.includes('Mobile') ? 'mobile_app' : 'web_app',
      deviceInfo: {
        platform: req.headers['x-platform'] || 'unknown',
        version: req.headers['x-version'] || 'unknown',
        userAgent: req.headers['user-agent'] || 'unknown'
      },
      ipAddress: req.ip || req.connection.remoteAddress
    };

    // Handle file uploads
    const images = [];
    const videos = [];
    
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        try {
          const result = await new Promise((resolve, reject) => {
            const uploadOptions = {
              folder: 'civic-welfare/reports',
              public_id: `report_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
              resource_type: file.mimetype.startsWith('video/') ? 'video' : 'image'
            };

            if (file.mimetype.startsWith('image/')) {
              uploadOptions.transformation = [
                { width: 1200, height: 1200, crop: 'limit' },
                { quality: 'auto', fetch_format: 'auto' }
              ];
            }

            cloudinary.uploader.upload_stream(
              uploadOptions,
              (error, result) => {
                if (error) reject(error);
                else resolve(result);
              }
            ).end(file.buffer);
          });

          const fileData = {
            url: result.secure_url,
            publicId: result.public_id,
            filename: file.originalname,
            uploadedAt: new Date()
          };

          if (file.mimetype.startsWith('video/')) {
            videos.push(fileData);
          } else {
            images.push(fileData);
          }

        } catch (uploadError) {
          console.error('File upload error:', uploadError);
          // Continue with other files even if one fails
        }
      }
    }

    reportData.images = images;
    reportData.videos = videos;

    // Create the report
    const report = new Report(reportData);
    await report.save();

    // Update user's report stats
    await User.findByIdAndUpdate(userId, {
      $inc: { 'reportStats.totalReports': 1, 'reportStats.pendingReports': 1 }
    });

    // Find officers in the assigned department for notification
    const officers = await User.find({
      userType: 'officer',
      department: report.assignedDepartment,
      isActive: true
    });

    // Notify relevant officers
    for (const officer of officers) {
      const notification = new Notification({
        userId: officer._id,
        userType: 'officer',
        title: 'New Report Assignment',
        message: `New ${report.category} report: ${report.title}`,
        type: 'report_assignment',
        category: 'report',
        priority: report.priority,
        relatedEntities: {
          reportId: report._id
        },
        actionable: true,
        actionButtons: [
          {
            label: 'View Report',
            action: 'view_report',
            url: `/reports/${report._id}`
          },
          {
            label: 'Acknowledge',
            action: 'acknowledge_report',
            style: 'primary'
          }
        ]
      });

      await notification.save();
    }

    // Notify admins
    const admins = await User.find({ userType: 'admin', isActive: true });
    for (const admin of admins) {
      const notification = new Notification({
        userId: admin._id,
        userType: 'admin',
        title: 'New Report Submitted',
        message: `New report from ${user.name}: ${report.title}`,
        type: 'report_created',
        category: 'report',
        priority: 'medium',
        relatedEntities: {
          reportId: report._id
        }
      });

      await notification.save();
    }

    // Populate report for response
    const populatedReport = await Report.findById(report._id)
      .populate('submittedBy', 'name email phone userType')
      .populate('assignedTo', 'name email department designation');

    res.status(201).json({
      success: true,
      message: 'Report submitted successfully',
      data: populatedReport
    });

  } catch (error) {
    console.error('Report creation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create report',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   GET /api/reports
 * @desc    Get reports with filtering and pagination
 * @access  Private
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      category,
      priority,
      assignedTo,
      submittedBy,
      department,
      startDate,
      endDate,
      search,
      latitude,
      longitude,
      radius = 10,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const userId = req.user.id;
    const user = await User.findById(userId);

    // Build query based on user type
    let query = {};

    // Base visibility rules
    if (user.userType === 'citizen') {
      // Citizens can only see their own reports or public ones
      query = {
        $or: [
          { submittedBy: userId },
          { publiclyVisible: true }
        ]
      };
    } else if (user.userType === 'officer') {
      // Officers can see reports in their department or assigned to them
      query = {
        $or: [
          { assignedDepartment: user.department },
          { assignedTo: userId }
        ]
      };
    }
    // Admins can see all reports (no additional filter)

    // Apply filters
    if (status) {
      if (Array.isArray(status)) {
        query.status = { $in: status };
      } else {
        query.status = status;
      }
    }

    if (category) {
      if (Array.isArray(category)) {
        query.category = { $in: category };
      } else {
        query.category = category;
      }
    }

    if (priority) {
      if (Array.isArray(priority)) {
        query.priority = { $in: priority };
      } else {
        query.priority = priority;
      }
    }

    if (assignedTo) {
      query.assignedTo = assignedTo;
    }

    if (submittedBy) {
      query.submittedBy = submittedBy;
    }

    if (department) {
      query.assignedDepartment = department;
    }

    // Date range filter
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) {
        query.createdAt.$gte = new Date(startDate);
      }
      if (endDate) {
        query.createdAt.$lte = new Date(endDate);
      }
    }

    // Location-based search
    if (latitude && longitude) {
      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);
      const radiusInKm = parseFloat(radius);
      const radiusInRadians = radiusInKm / 6371; // Earth's radius in km

      query['location.coordinates.latitude'] = {
        $gte: lat - radiusInRadians,
        $lte: lat + radiusInRadians
      };
      query['location.coordinates.longitude'] = {
        $gte: lng - radiusInRadians,
        $lte: lng + radiusInRadians
      };
    }

    // Text search
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { keywords: { $in: [new RegExp(search, 'i')] } },
        { 'location.address': { $regex: search, $options: 'i' } },
        { 'location.city': { $regex: search, $options: 'i' } }
      ];
    }

    // Pagination
    const pageNumber = parseInt(page, 10);
    const pageSize = Math.min(parseInt(limit, 10), 100); // Max 100 per page
    const skip = (pageNumber - 1) * pageSize;

    // Sort options
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'desc' ? -1 : 1;

    // Execute query
    const [reports, totalCount] = await Promise.all([
      Report.find(query)
        .populate('submittedBy', 'name email phone userType profilePicture')
        .populate('assignedTo', 'name email department designation profilePicture')
        .populate('resolutionDetails.resolvedBy', 'name email designation')
        .sort(sortOptions)
        .skip(skip)
        .limit(pageSize),
      Report.countDocuments(query)
    ]);

    // Calculate pagination info
    const totalPages = Math.ceil(totalCount / pageSize);
    const hasNextPage = pageNumber < totalPages;
    const hasPrevPage = pageNumber > 1;

    res.json({
      success: true,
      data: {
        reports,
        pagination: {
          currentPage: pageNumber,
          totalPages,
          totalCount,
          pageSize,
          hasNextPage,
          hasPrevPage
        },
        filters: {
          status,
          category,
          priority,
          search,
          location: latitude && longitude ? { latitude, longitude, radius } : null
        }
      }
    });

  } catch (error) {
    console.error('Get reports error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reports',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   GET /api/reports/:id
 * @desc    Get a specific report by ID
 * @access  Private
 */
router.get('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const user = await User.findById(userId);

    const report = await Report.findById(id)
      .populate('submittedBy', 'name email phone userType profilePicture location')
      .populate('assignedTo', 'name email department designation profilePicture')
      .populate('resolutionDetails.resolvedBy', 'name email designation profilePicture')
      .populate('updates.updatedBy', 'name email userType designation')
      .populate('feedback.submittedBy', 'name profilePicture');

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    // Check access permissions
    const hasAccess = 
      user.userType === 'admin' ||
      (user.userType === 'officer' && (
        report.assignedDepartment === user.department ||
        report.assignedTo?.toString() === userId
      )) ||
      (user.userType === 'citizen' && (
        report.submittedBy._id.toString() === userId ||
        report.publiclyVisible
      ));

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Increment view count
    report.viewCount += 1;
    await report.save();

    res.json({
      success: true,
      data: report
    });

  } catch (error) {
    console.error('Get report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch report',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   PUT /api/reports/:id/status
 * @desc    Update report status
 * @access  Private (Officer, Admin)
 */
router.put('/:id/status', authenticate, authorize(['officer', 'admin']), validateReportUpdate, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, message, isInternal = false } = req.body;
    const userId = req.user.id;
    const user = await User.findById(userId);

    const report = await Report.findById(id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    // Check permissions
    const canUpdate = 
      user.userType === 'admin' ||
      (user.userType === 'officer' && (
        report.assignedDepartment === user.department ||
        report.assignedTo?.toString() === userId
      ));

    if (!canUpdate) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Add status update
    await report.addUpdate(message, status, userId, user.name, isInternal);

    // Auto-assign if acknowledging and not already assigned
    if (status === 'acknowledged' && !report.assignedTo) {
      report.assignedTo = userId;
      report.assignedAt = new Date();
      await report.save();
    }

    // Update user report stats if resolved
    if (status === 'resolved') {
      await User.findByIdAndUpdate(report.submittedBy, {
        $inc: { 
          'reportStats.resolvedReports': 1,
          'reportStats.pendingReports': -1
        }
      });
    }

    // Notify report submitter (if not internal update)
    if (!isInternal) {
      const notification = new Notification({
        userId: report.submittedBy,
        userType: 'citizen',
        title: 'Report Status Update',
        message: `Your report "${report.title}" status changed to ${status}`,
        type: 'report_status_update',
        category: 'report',
        priority: status === 'resolved' ? 'high' : 'medium',
        relatedEntities: {
          reportId: report._id
        },
        actionable: true,
        actionButtons: [
          {
            label: 'View Report',
            action: 'view_report',
            url: `/reports/${report._id}`
          }
        ]
      });

      await notification.save();
    }

    const updatedReport = await Report.findById(id)
      .populate('submittedBy', 'name email phone userType')
      .populate('assignedTo', 'name email department designation')
      .populate('updates.updatedBy', 'name email userType designation');

    res.json({
      success: true,
      message: 'Report status updated successfully',
      data: updatedReport
    });

  } catch (error) {
    console.error('Update report status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update report status',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   POST /api/reports/:id/assign
 * @desc    Assign report to an officer
 * @access  Private (Admin, Department Officers)
 */
router.post('/:id/assign', authenticate, authorize(['officer', 'admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { assignedTo } = req.body;
    const userId = req.user.id;
    const user = await User.findById(userId);

    const report = await Report.findById(id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }

    // Check permissions
    const canAssign = 
      user.userType === 'admin' ||
      (user.userType === 'officer' && report.assignedDepartment === user.department);

    if (!canAssign) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Validate assigned officer
    const officer = await User.findById(assignedTo);

    if (!officer || officer.userType !== 'officer') {
      return res.status(400).json({
        success: false,
        message: 'Invalid officer ID'
      });
    }

    // Update assignment
    report.assignedTo = assignedTo;
    report.assignedAt = new Date();
    await report.save();

    // Add update
    await report.addUpdate(
      `Report assigned to ${officer.name}`,
      'acknowledged',
      userId,
      user.name,
      false
    );

    // Notify assigned officer
    const notification = new Notification({
      userId: assignedTo,
      userType: 'officer',
      title: 'Report Assigned',
      message: `You have been assigned to handle: ${report.title}`,
      type: 'report_assignment',
      category: 'report',
      priority: report.priority,
      relatedEntities: {
        reportId: report._id
      },
      actionable: true,
      actionButtons: [
        {
          label: 'View Report',
          action: 'view_report',
          url: `/reports/${report._id}`
        }
      ]
    });

    await notification.save();

    const updatedReport = await Report.findById(id)
      .populate('assignedTo', 'name email department designation');

    res.json({
      success: true,
      message: 'Report assigned successfully',
      data: updatedReport
    });

  } catch (error) {
    console.error('Assign report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to assign report',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

/**
 * @route   GET /api/reports/statistics/dashboard
 * @desc    Get report statistics for dashboard
 * @access  Private
 */
router.get('/statistics/dashboard', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);

    let matchStage = {};

    // Filter based on user type
    if (user.userType === 'citizen') {
      matchStage.submittedBy = mongoose.Types.ObjectId(userId);
    } else if (user.userType === 'officer') {
      matchStage.$or = [
        { assignedDepartment: user.department },
        { assignedTo: mongoose.Types.ObjectId(userId) }
      ];
    }
    // Admin gets all reports

    const [
      statusStats,
      categoryStats,
      priorityStats,
      monthlyTrend,
      resolutionTime
    ] = await Promise.all([
      // Status statistics
      Report.aggregate([
        { $match: matchStage },
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 }
          }
        }
      ]),

      // Category statistics
      Report.aggregate([
        { $match: matchStage },
        {
          $group: {
            _id: '$category',
            count: { $sum: 1 }
          }
        },
        { $sort: { count: -1 } },
        { $limit: 10 }
      ]),

      // Priority statistics
      Report.aggregate([
        { $match: matchStage },
        {
          $group: {
            _id: '$priority',
            count: { $sum: 1 }
          }
        }
      ]),

      // Monthly trend (last 12 months)
      Report.aggregate([
        {
          $match: {
            ...matchStage,
            createdAt: {
              $gte: new Date(new Date().setMonth(new Date().getMonth() - 12))
            }
          }
        },
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
            ...matchStage,
            status: 'resolved',
            actualResolutionDate: { $exists: true }
          }
        },
        {
          $group: {
            _id: null,
            avgResolutionTime: {
              $avg: {
                $divide: [
                  { $subtract: ['$actualResolutionDate', '$createdAt'] },
                  1000 * 60 * 60 * 24 // Convert to days
                ]
              }
            }
          }
        }
      ])
    ]);

    res.json({
      success: true,
      data: {
        statusStats,
        categoryStats,
        priorityStats,
        monthlyTrend,
        avgResolutionTime: resolutionTime[0]?.avgResolutionTime || 0
      }
    });

  } catch (error) {
    console.error('Get dashboard statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;