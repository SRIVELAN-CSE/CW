const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const Report = require('../models/Report');
const User = require('../models/User');
const RegistrationRequest = require('../models/RegistrationRequest');
const NeedRequest = require('../models/NeedRequest');
const Certificate = require('../models/Certificate');
const Feedback = require('../models/Feedback');
const { authenticate, authorize } = require('../middleware/auth');

// @route   GET /api/dashboard/admin/stats
// @desc    Get admin dashboard statistics
// @access  Private (Admin only)
router.get('/admin/stats', authenticate, authorize('admin'), async (req, res) => {
  try {
    // Get current date ranges
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay()));
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Parallel queries for better performance
    const [
      totalReports,
      activeReports,
      resolvedReports,
      todayReports,
      weekReports,
      monthReports,
      totalUsers,
      activeUsers,
      pendingRegistrations,
      totalOfficers,
      totalCertificates,
      totalFeedback,
      needRequests,
      categoryStats,
      priorityStats,
      departmentStats,
      statusDistribution,
      recentActivity
    ] = await Promise.all([
      // Report statistics
      Report.countDocuments(),
      Report.countDocuments({ status: { $in: ['submitted', 'acknowledged', 'in_progress'] } }),
      Report.countDocuments({ status: 'resolved' }),
      Report.countDocuments({ createdAt: { $gte: startOfDay } }),
      Report.countDocuments({ createdAt: { $gte: startOfWeek } }),
      Report.countDocuments({ createdAt: { $gte: startOfMonth } }),

      // User statistics
      User.countDocuments(),
      User.countDocuments({ isActive: true }),
      RegistrationRequest.countDocuments({ status: 'pending' }),
      User.countDocuments({ userType: 'officer' }),

      // Other statistics
      Certificate.countDocuments(),
      Feedback.countDocuments(),
      NeedRequest.countDocuments(),

      // Aggregated statistics
      Report.aggregate([
        { $group: { _id: '$category', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),
      
      Report.aggregate([
        { $group: { _id: '$priority', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),

      Report.aggregate([
        { $group: { _id: '$department', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),

      Report.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ]),

      // Recent activity (last 10 reports)
      Report.find()
        .populate('reporterId', 'name email')
        .populate('assignedOfficerId', 'name email')
        .sort({ createdAt: -1 })
        .limit(10)
        .lean()
    ]);

    // Calculate resolution rate
    const resolutionRate = totalReports > 0 ? ((resolvedReports / totalReports) * 100).toFixed(1) : 0;

    // Weekly trend (last 7 days)
    const weeklyTrend = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());
      const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000);
      
      const dayReports = await Report.countDocuments({
        createdAt: { $gte: startOfDay, $lt: endOfDay }
      });
      
      weeklyTrend.push({
        date: startOfDay.toISOString().split('T')[0],
        reports: dayReports
      });
    }

    res.json({
      success: true,
      data: {
        overview: {
          totalReports,
          activeReports,
          resolvedReports,
          resolutionRate: parseFloat(resolutionRate),
          totalUsers,
          activeUsers,
          totalOfficers,
          pendingRegistrations
        },
        timeBasedStats: {
          today: todayReports,
          thisWeek: weekReports,
          thisMonth: monthReports,
          weeklyTrend
        },
        distributions: {
          categories: categoryStats.map(item => ({
            name: item._id,
            value: item.count
          })),
          priorities: priorityStats.map(item => ({
            name: item._id,
            value: item.count
          })),
          departments: departmentStats.map(item => ({
            name: item._id,
            value: item.count
          })),
          statuses: statusDistribution.map(item => ({
            name: item._id,
            value: item.count
          }))
        },
        otherStats: {
          totalCertificates,
          totalFeedback,
          needRequests
        },
        recentActivity: recentActivity.map(report => ({
          id: report._id,
          title: report.title,
          category: report.category,
          status: report.status,
          priority: report.priority,
          reporterName: report.reporterId?.name || 'Unknown',
          assignedOfficer: report.assignedOfficerId?.name || 'Unassigned',
          createdAt: report.createdAt
        }))
      }
    });

  } catch (error) {
    console.error('Admin dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch admin dashboard statistics'
    });
  }
});

// @route   GET /api/dashboard/officer/stats
// @desc    Get officer dashboard statistics
// @access  Private (Officer only)
router.get('/officer/stats', authenticate, authorize('officer'), async (req, res) => {
  try {
    const officerId = req.user._id;
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay()));

    const [
      assignedReports,
      inProgressReports,
      resolvedReports,
      weeklyAssigned,
      monthlyAssigned,
      myRecentReports,
      categoryBreakdown,
      priorityBreakdown
    ] = await Promise.all([
      Report.countDocuments({ assignedOfficerId: officerId }),
      Report.countDocuments({ 
        assignedOfficerId: officerId, 
        status: { $in: ['acknowledged', 'in_progress'] } 
      }),
      Report.countDocuments({ 
        assignedOfficerId: officerId, 
        status: 'resolved' 
      }),
      Report.countDocuments({ 
        assignedOfficerId: officerId,
        createdAt: { $gte: startOfWeek } 
      }),
      Report.countDocuments({ 
        assignedOfficerId: officerId,
        createdAt: { $gte: startOfMonth } 
      }),
      Report.find({ assignedOfficerId: officerId })
        .populate('reporterId', 'name email')
        .sort({ createdAt: -1 })
        .limit(10)
        .lean(),
      Report.aggregate([
        { $match: { assignedOfficerId: officerId } },
        { $group: { _id: '$category', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),
      Report.aggregate([
        { $match: { assignedOfficerId: officerId } },
        { $group: { _id: '$priority', count: { $sum: 1 } } }
      ])
    ]);

    // Calculate performance metrics
    const resolutionRate = assignedReports > 0 ? 
      ((resolvedReports / assignedReports) * 100).toFixed(1) : 0;

    res.json({
      success: true,
      data: {
        overview: {
          assignedReports,
          inProgressReports,
          resolvedReports,
          resolutionRate: parseFloat(resolutionRate)
        },
        timeStats: {
          weeklyAssigned,
          monthlyAssigned
        },
        breakdowns: {
          categories: categoryBreakdown.map(item => ({
            name: item._id,
            value: item.count
          })),
          priorities: priorityBreakdown.map(item => ({
            name: item._id,
            value: item.count
          }))
        },
        recentReports: myRecentReports.map(report => ({
          id: report._id,
          title: report.title,
          category: report.category,
          status: report.status,
          priority: report.priority,
          reporterName: report.reporterId?.name || 'Unknown',
          createdAt: report.createdAt
        }))
      }
    });

  } catch (error) {
    console.error('Officer dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch officer dashboard statistics'
    });
  }
});

// @route   GET /api/dashboard/public/stats
// @desc    Get public dashboard statistics
// @access  Public
router.get('/public/stats', async (req, res) => {
  try {
    const [
      totalReports,
      resolvedReports,
      inProgressReports,
      recentReports,
      categoryStats,
      statusStats
    ] = await Promise.all([
      Report.countDocuments({ isPublic: true }),
      Report.countDocuments({ isPublic: true, status: 'resolved' }),
      Report.countDocuments({ 
        isPublic: true, 
        status: { $in: ['acknowledged', 'in_progress'] } 
      }),
      Report.find({ isPublic: true })
        .populate('reporterId', 'name')
        .sort({ createdAt: -1 })
        .limit(10)
        .lean(),
      Report.aggregate([
        { $match: { isPublic: true } },
        { $group: { _id: '$category', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),
      Report.aggregate([
        { $match: { isPublic: true } },
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ])
    ]);

    const resolutionRate = totalReports > 0 ? 
      ((resolvedReports / totalReports) * 100).toFixed(1) : 0;

    res.json({
      success: true,
      data: {
        overview: {
          totalReports,
          resolvedReports,
          inProgressReports,
          resolutionRate: parseFloat(resolutionRate)
        },
        distributions: {
          categories: categoryStats.map(item => ({
            name: item._id,
            value: item.count
          })),
          statuses: statusStats.map(item => ({
            name: item._id,
            value: item.count
          }))
        },
        recentActivity: recentReports.map(report => ({
          id: report._id,
          title: report.title,
          category: report.category,
          status: report.status,
          location: report.location,
          createdAt: report.createdAt
        }))
      }
    });

  } catch (error) {
    console.error('Public dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch public dashboard statistics'
    });
  }
});

module.exports = router;