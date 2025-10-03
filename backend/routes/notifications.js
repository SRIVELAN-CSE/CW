const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const Notification = require('../models/Notification');
const User = require('../models/User');
const { authenticate, authorize } = require('../middleware/auth');

// @route   GET /api/notifications
// @desc    Get user notifications with pagination
// @access  Private
router.get('/', authenticate, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      type,
      isRead,
      sort = 'createdAt',
      order = 'desc'
    } = req.query;

    // Build filter object
    const filter = { userId: req.user._id };
    
    if (type) filter.type = type;
    if (isRead !== undefined) filter.isRead = isRead === 'true';

    // Calculate pagination
    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    // Execute query
    const notifications = await Notification.find(filter)
      .populate('relatedId')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const totalNotifications = await Notification.countDocuments(filter);
    const unreadCount = await Notification.countDocuments({ 
      userId: req.user._id, 
      isRead: false 
    });

    res.json({
      success: true,
      data: {
        notifications,
        unreadCount,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalNotifications / parseInt(limit)),
          totalNotifications,
          hasNext: page < Math.ceil(totalNotifications / parseInt(limit)),
          hasPrev: page > 1
        }
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notifications'
    });
  }
});

// @route   PUT /api/notifications/:id/read
// @desc    Mark notification as read
// @access  Private
router.put('/:id/read', authenticate, async (req, res) => {
  try {
    const notification = await Notification.findOne({
      _id: req.params.id,
      userId: req.user._id
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    notification.isRead = true;
    await notification.save();

    res.json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (error) {
    console.error('Mark notification read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read'
    });
  }
});

// @route   PUT /api/notifications/read-all
// @desc    Mark all notifications as read
// @access  Private
router.put('/read-all', authenticate, async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user._id, isRead: false },
      { isRead: true }
    );

    res.json({
      success: true,
      message: 'All notifications marked as read'
    });
  } catch (error) {
    console.error('Mark all notifications read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark all notifications as read'
    });
  }
});

// @route   DELETE /api/notifications/:id
// @desc    Delete notification
// @access  Private
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const notification = await Notification.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification deleted successfully'
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete notification'
    });
  }
});

// @route   POST /api/notifications/bulk-create
// @desc    Create bulk notifications (Admin only)
// @access  Private (Admin)
router.post('/bulk-create', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { title, message, type = 'announcement', targetUserTypes = ['public'], priority = 'medium' } = req.body;

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

    if (targetUsers.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No target users found'
      });
    }

    // Create notifications
    const notifications = targetUsers.map(user => ({
      title,
      message,
      type,
      userId: user._id,
      priority,
      isSystemMessage: true
    }));

    const createdNotifications = await Notification.insertMany(notifications);

    // Send real-time notifications
    const io = req.app.get('io');
    if (io) {
      targetUsers.forEach(user => {
        io.to(`user_${user._id}`).emit('newNotification', {
          title,
          message,
          type,
          priority
        });
      });
    }

    res.status(201).json({
      success: true,
      message: 'Bulk notifications created successfully',
      data: {
        count: createdNotifications.length,
        targetUserTypes
      }
    });

  } catch (error) {
    console.error('Bulk create notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create bulk notifications'
    });
  }
});

// @route   GET /api/notifications/stats
// @desc    Get notification statistics
// @access  Private
router.get('/stats', authenticate, async (req, res) => {
  try {
    const userId = req.user._id;

    const [
      totalNotifications,
      unreadCount,
      typeDistribution,
      recentCount,
      priorityDistribution
    ] = await Promise.all([
      Notification.countDocuments({ userId }),
      Notification.countDocuments({ userId, isRead: false }),
      Notification.aggregate([
        { $match: { userId: userId } },
        { $group: { _id: '$type', count: { $sum: 1 } } }
      ]),
      Notification.countDocuments({
        userId,
        createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } // Last 24 hours
      }),
      Notification.aggregate([
        { $match: { userId: userId } },
        { $group: { _id: '$priority', count: { $sum: 1 } } }
      ])
    ]);

    res.json({
      success: true,
      data: {
        total: totalNotifications,
        unread: unreadCount,
        recent: recentCount,
        typeBreakdown: typeDistribution.map(item => ({
          type: item._id,
          count: item.count
        })),
        priorityBreakdown: priorityDistribution.map(item => ({
          priority: item._id,
          count: item.count
        }))
      }
    });

  } catch (error) {
    console.error('Notification stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notification statistics'
    });
  }
});

module.exports = router;