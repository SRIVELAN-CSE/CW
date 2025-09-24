const mongoose = require('mongoose');
const User = require('../models/User');
const Report = require('../models/Report');
const Notification = require('../models/Notification');

// Database health check
const checkDatabaseHealth = async () => {
  try {
    const state = mongoose.connection.readyState;
    const stateNames = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };

    return {
      status: stateNames[state] || 'unknown',
      connected: state === 1,
      host: mongoose.connection.host,
      port: mongoose.connection.port,
      name: mongoose.connection.name
    };
  } catch (error) {
    return {
      status: 'error',
      connected: false,
      error: error.message
    };
  }
};

// Get database statistics
const getDatabaseStats = async () => {
  try {
    const stats = await Promise.all([
      User.countDocuments(),
      Report.countDocuments(),
      Notification.countDocuments()
    ]);

    return {
      users: stats[0],
      reports: stats[1],
      notifications: stats[2],
      total: stats.reduce((sum, count) => sum + count, 0)
    };
  } catch (error) {
    throw new Error('Failed to get database statistics: ' + error.message);
  }
};

// Get user type distribution
const getUserTypeDistribution = async () => {
  try {
    const distribution = await User.aggregate([
      {
        $group: {
          _id: '$userType',
          count: { $sum: 1 }
        }
      },
      {
        $project: {
          userType: '$_id',
          count: 1,
          _id: 0
        }
      }
    ]);

    return distribution.reduce((acc, item) => {
      acc[item.userType] = item.count;
      return acc;
    }, {});
  } catch (error) {
    throw new Error('Failed to get user type distribution: ' + error.message);
  }
};

// Get report status distribution
const getReportStatusDistribution = async () => {
  try {
    const distribution = await Report.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      },
      {
        $project: {
          status: '$_id',
          count: 1,
          _id: 0
        }
      }
    ]);

    return distribution.reduce((acc, item) => {
      acc[item.status] = item.count;
      return acc;
    }, {});
  } catch (error) {
    throw new Error('Failed to get report status distribution: ' + error.message);
  }
};

// Get report category distribution
const getReportCategoryDistribution = async () => {
  try {
    const distribution = await Report.aggregate([
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 }
        }
      },
      {
        $project: {
          category: '$_id',
          count: 1,
          _id: 0
        }
      },
      {
        $sort: { count: -1 }
      }
    ]);

    return distribution.reduce((acc, item) => {
      acc[item.category] = item.count;
      return acc;
    }, {});
  } catch (error) {
    throw new Error('Failed to get report category distribution: ' + error.message);
  }
};

// Clean up old notifications
const cleanupOldNotifications = async (daysOld = 30) => {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await Notification.deleteMany({
      createdAt: { $lt: cutoffDate }
    });

    return {
      deletedCount: result.deletedCount,
      cutoffDate
    };
  } catch (error) {
    throw new Error('Failed to cleanup old notifications: ' + error.message);
  }
};

// Generate database backup info
const generateBackupInfo = () => {
  return {
    timestamp: new Date(),
    collections: ['users', 'reports', 'notifications', 'registrationrequests', 'passwordresetrequests', 'needrequests', 'certificates', 'feedback'],
    recommendedFrequency: 'daily',
    retentionPeriod: '30 days',
    backupLocation: process.env.BACKUP_LOCATION || '/backups'
  };
};

// Validate data integrity
const validateDataIntegrity = async () => {
  try {
    const issues = [];

    // Check for users without email
    const usersWithoutEmail = await User.countDocuments({
      $or: [
        { email: null },
        { email: '' }
      ]
    });
    if (usersWithoutEmail > 0) {
      issues.push(`${usersWithoutEmail} users found without email`);
    }

    // Check for reports without reporter
    const reportsWithoutReporter = await Report.countDocuments({
      reporterId: null
    });
    if (reportsWithoutReporter > 0) {
      issues.push(`${reportsWithoutReporter} reports found without reporter`);
    }

    // Check for notifications without recipient
    const notificationsWithoutRecipient = await Notification.countDocuments({
      userId: null
    });
    if (notificationsWithoutRecipient > 0) {
      issues.push(`${notificationsWithoutRecipient} notifications found without recipient`);
    }

    return {
      isValid: issues.length === 0,
      issues: issues,
      checkedAt: new Date()
    };
  } catch (error) {
    return {
      isValid: false,
      issues: ['Database validation failed: ' + error.message],
      checkedAt: new Date()
    };
  }
};

// Get recent activity summary
const getRecentActivitySummary = async (hours = 24) => {
  try {
    const cutoffDate = new Date();
    cutoffDate.setHours(cutoffDate.getHours() - hours);

    const [newUsers, newReports, newNotifications] = await Promise.all([
      User.countDocuments({ createdAt: { $gte: cutoffDate } }),
      Report.countDocuments({ createdAt: { $gte: cutoffDate } }),
      Notification.countDocuments({ createdAt: { $gte: cutoffDate } })
    ]);

    return {
      period: `${hours} hours`,
      newUsers,
      newReports,
      newNotifications,
      totalNewActivity: newUsers + newReports + newNotifications
    };
  } catch (error) {
    throw new Error('Failed to get recent activity summary: ' + error.message);
  }
};

module.exports = {
  checkDatabaseHealth,
  getDatabaseStats,
  getUserTypeDistribution,
  getReportStatusDistribution,
  getReportCategoryDistribution,
  cleanupOldNotifications,
  generateBackupInfo,
  validateDataIntegrity,
  getRecentActivitySummary
};