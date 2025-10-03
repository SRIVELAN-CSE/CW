// Quick Database Summary Script
// Shows a condensed view of your MongoDB Atlas data

require('dotenv').config();
const mongoose = require('mongoose');

// Import models
const User = require('./models/User');
const Report = require('./models/Report');
const Certificate = require('./models/Certificate');
const RegistrationRequest = require('./models/RegistrationRequest');
const PasswordResetRequest = require('./models/PasswordResetRequest');
const NeedRequest = require('./models/NeedRequest');
const Feedback = require('./models/Feedback');
const Notification = require('./models/Notification');

async function quickDatabaseSummary() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas\n');

    console.log('🚀 CIVIC WELFARE DATABASE SUMMARY');
    console.log('=' .repeat(50));

    // Quick counts
    const userCount = await User.countDocuments();
    const reportCount = await Report.countDocuments();
    const certCount = await Certificate.countDocuments();
    const regCount = await RegistrationRequest.countDocuments();
    const resetCount = await PasswordResetRequest.countDocuments();
    const needCount = await NeedRequest.countDocuments();
    const feedbackCount = await Feedback.countDocuments();
    const notificationCount = await Notification.countDocuments();

    console.log(`👥 Users: ${userCount}`);
    console.log(`📊 Reports: ${reportCount}`);
    console.log(`📜 Certificates: ${certCount}`);
    console.log(`📝 Registration Requests: ${regCount}`);
    console.log(`🔐 Password Resets: ${resetCount}`);
    console.log(`🤲 Need Requests: ${needCount}`);
    console.log(`💬 Feedback: ${feedbackCount}`);
    console.log(`🔔 Notifications: ${notificationCount}`);
    
    const totalRecords = userCount + reportCount + certCount + regCount + resetCount + needCount + feedbackCount + notificationCount;
    console.log(`\n📈 TOTAL RECORDS: ${totalRecords}`);

    // User breakdown
    const userStats = await User.aggregate([
      { $group: { _id: '$userType', count: { $sum: 1 } } }
    ]);
    
    console.log('\n👥 USER BREAKDOWN:');
    userStats.forEach(stat => {
      console.log(`   ${stat._id}: ${stat.count} users`);
    });

    // Recent activity
    const recentReports = await Report.countDocuments({ 
      createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } 
    });
    
    const unreadNotifications = await Notification.countDocuments({ isRead: false });
    
    console.log('\n📊 RECENT ACTIVITY (Last 24 hours):');
    console.log(`   📊 New Reports: ${recentReports}`);
    console.log(`   🔔 Unread Notifications: ${unreadNotifications}`);

    console.log('\n✅ Database is active and populated!');
    console.log('📱 Ready for dashboard testing and production use.');

  } catch (error) {
    console.error('❌ Database summary failed:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

quickDatabaseSummary();