const express = require('express');
const router = express.Router();

const User = require('../models/User');
const Report = require('../models/Report');
const Certificate = require('../models/Certificate');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');

// @route   GET /api/users
// @desc    Get all users with filtering and pagination
// @access  Private (Admin only)
router.get('/', authenticate, authorize('admin'), async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      userType,
      department,
      isActive,
      search,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    // Build filter object
    const filter = {};
    
    if (userType) filter.userType = userType;
    if (department) filter.department = department;
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    
    // Add text search
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }

    // Calculate pagination
    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    // Execute query
    const users = await User.find(filter)
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const totalUsers = await User.countDocuments(filter);
    const totalPages = Math.ceil(totalUsers / parseInt(limit));

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalUsers,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users'
    });
  }
});

// @route   GET /api/users/:id
// @desc    Get single user by ID
// @access  Private (Admin, or own profile)
router.get('/:id', authenticate, async (req, res) => {
  try {
    // Check if user can view this profile
    const canView = 
      req.user.userType === 'admin' || 
      req.user._id.toString() === req.params.id;

    if (!canView) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: { user }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user'
    });
  }
});

// @route   PUT /api/users/:id
// @desc    Update user
// @access  Private (Admin or own profile)
router.put('/:id', authenticate, async (req, res) => {
  try {
    // Check if user can update this profile
    const canUpdate = 
      req.user.userType === 'admin' || 
      req.user._id.toString() === req.params.id;

    if (!canUpdate) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const updates = req.body;
    
    // Non-admin users can't change certain fields
    if (req.user.userType !== 'admin') {
      delete updates.userType;
      delete updates.department;
      delete updates.isActive;
      delete updates.isVerified;
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'User updated successfully',
      data: { user }
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user'
    });
  }
});

// @route   PUT /api/users/:id/activate
// @desc    Activate/Deactivate user
// @access  Private (Admin only)
router.put('/:id/activate', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { isActive } = req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: `User ${isActive ? 'activated' : 'deactivated'} successfully`,
      data: { user }
    });
  } catch (error) {
    console.error('Activate user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user status'
    });
  }
});

// @route   DELETE /api/users/:id
// @desc    Delete user
// @access  Private (Admin only)
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Prevent admin from deleting themselves
    if (user._id.toString() === req.user._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account'
      });
    }

    await User.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete user'
    });
  }
});

// @route   GET /api/users/officers/available
// @desc    Get available officers by department
// @access  Private (Admin only)
router.get('/officers/available', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { department } = req.query;

    const filter = {
      userType: 'officer',
      isActive: true
    };

    if (department) {
      filter.department = department;
    }

    const officers = await User.find(filter)
      .select('name email phone department')
      .sort('name');

    res.json({
      success: true,
      data: { officers }
    });
  } catch (error) {
    console.error('Get officers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch officers'
    });
  }
});

// @route   GET /api/users/stats/overview
// @desc    Get users statistics
// @access  Private (Admin only)
router.get('/stats/overview', authenticate, authorize('admin'), async (req, res) => {
  try {
    const stats = await Promise.all([
      User.countDocuments({ userType: 'public' }),
      User.countDocuments({ userType: 'officer' }),
      User.countDocuments({ userType: 'admin' }),
      User.countDocuments({ isActive: true }),
      User.countDocuments({ isActive: false }),
      User.countDocuments(),
      User.aggregate([
        {
          $group: {
            _id: '$department',
            count: { $sum: 1 }
          }
        },
        { $sort: { count: -1 } }
      ])
    ]);

    res.json({
      success: true,
      data: {
        userTypeCounts: {
          public: stats[0],
          officer: stats[1],
          admin: stats[2]
        },
        statusCounts: {
          active: stats[3],
          inactive: stats[4],
          total: stats[5]
        },
        departmentStats: stats[6]
      }
    });
  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user statistics'
    });
  }
});

// @route   GET /api/users/:id/activity
// @desc    Get user activity summary
// @access  Private (Admin or own profile)
router.get('/:id/activity', authenticate, async (req, res) => {
  try {
    const canView = 
      req.user.userType === 'admin' || 
      req.user._id.toString() === req.params.id;

    if (!canView) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const userId = req.params.id;
    const user = await User.findById(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const [
      totalReports,
      resolvedReports,
      certificateApplications,
      notifications,
      recentActivity
    ] = await Promise.all([
      // Reports created or assigned
      user.userType === 'officer' 
        ? Report.countDocuments({ assignedOfficerId: userId })
        : Report.countDocuments({ reporterId: userId }),
      
      // Resolved reports
      user.userType === 'officer'
        ? Report.countDocuments({ assignedOfficerId: userId, status: 'resolved' })
        : Report.countDocuments({ reporterId: userId, status: 'resolved' }),
      
      // Certificate applications
      user.userType === 'public' 
        ? Certificate.countDocuments({ applicantId: userId })
        : Certificate.countDocuments(),
      
      // Notifications
      Notification.countDocuments({ userId }),
      
      // Recent activity (last 10 items)
      user.userType === 'officer'
        ? Report.find({ assignedOfficerId: userId })
            .sort({ updatedAt: -1 })
            .limit(10)
            .select('title status category updatedAt')
            .lean()
        : Report.find({ reporterId: userId })
            .sort({ updatedAt: -1 })
            .limit(10)
            .select('title status category updatedAt')
            .lean()
    ]);

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          userType: user.userType,
          department: user.department,
          isActive: user.isActive,
          createdAt: user.createdAt
        },
        activity: {
          totalReports,
          resolvedReports,
          certificateApplications,
          notifications,
          resolutionRate: totalReports > 0 ? 
            ((resolvedReports / totalReports) * 100).toFixed(1) : 0
        },
        recentActivity: recentActivity.map(item => ({
          id: item._id,
          title: item.title,
          status: item.status,
          category: item.category,
          date: item.updatedAt
        }))
      }
    });

  } catch (error) {
    console.error('Get user activity error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user activity'
    });
  }
});

// @route   POST /api/users/create-officer
// @desc    Create new officer account (Admin only)
// @access  Private (Admin)
router.post('/create-officer', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { name, email, phone, password, department, location } = req.body;

    // Validation
    if (!name || !email || !phone || !password || !department) {
      return res.status(400).json({
        success: false,
        message: 'All required fields must be provided'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Create officer account
    const officer = await User.create({
      name,
      email,
      phone,
      password,
      userType: 'officer',
      department,
      location,
      isActive: true,
      isVerified: true
    });

    // Create welcome notification
    await Notification.create({
      title: 'Welcome to CivicWelfare Officer Panel',
      message: `Your officer account has been created. You have been assigned to the ${department} department.`,
      type: 'account_created',
      userId: officer._id,
      priority: 'high'
    });

    res.status(201).json({
      success: true,
      message: 'Officer account created successfully',
      data: {
        officer: {
          id: officer._id,
          name: officer.name,
          email: officer.email,
          phone: officer.phone,
          department: officer.department,
          userType: officer.userType
        }
      }
    });

  } catch (error) {
    console.error('Create officer error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create officer account'
    });
  }
});

// @route   PUT /api/users/:id/toggle-status
// @desc    Toggle user active/inactive status (Admin only)
// @access  Private (Admin)
router.put('/:id/toggle-status', authenticate, authorize('admin'), async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Prevent admin from deactivating themselves
    if (user._id.toString() === req.user._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot modify your own account status'
      });
    }

    const previousStatus = user.isActive;
    user.isActive = !user.isActive;
    await user.save();

    // Create notification for the user
    await Notification.create({
      title: user.isActive ? 'Account Activated' : 'Account Deactivated',
      message: user.isActive 
        ? 'Your account has been activated and you can now access the system.'
        : 'Your account has been deactivated. Please contact administrator if needed.',
      type: 'account_status',
      userId: user._id,
      priority: 'high'
    });

    res.json({
      success: true,
      message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          isActive: user.isActive,
          previousStatus
        }
      }
    });

  } catch (error) {
    console.error('Toggle user status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user status'
    });
  }
});

module.exports = router;