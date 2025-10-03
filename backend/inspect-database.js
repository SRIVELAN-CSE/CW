// MongoDB Atlas Database Inspector
// Run this script to check all stored data from dashboard entries

require('dotenv').config();
const mongoose = require('mongoose');

// Import all models
const User = require('./models/User');
const Report = require('./models/Report');
const Certificate = require('./models/Certificate');
const RegistrationRequest = require('./models/RegistrationRequest');
const PasswordResetRequest = require('./models/PasswordResetRequest');
const NeedRequest = require('./models/NeedRequest');
const Feedback = require('./models/Feedback');
const Notification = require('./models/Notification');

async function inspectDatabase() {
  try {
    console.log('🔍 CONNECTING TO MONGODB ATLAS...');
    console.log('📡 Database:', process.env.MONGODB_URI.split('/')[3].split('?')[0]);
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas\n');

    console.log('='.repeat(80));
    console.log('📊 CIVIC WELFARE DATABASE INSPECTION REPORT');
    console.log('=' .repeat(80));

    // 1. USERS COLLECTION
    console.log('\n👥 USERS COLLECTION:');
    console.log('-'.repeat(40));
    const users = await User.find().select('name email userType department isActive createdAt').lean();
    console.log(`📋 Total Users: ${users.length}`);
    
    const usersByType = await User.aggregate([
      { $group: { _id: '$userType', count: { $sum: 1 } } }
    ]);
    
    console.log('👤 Users by Type:');
    usersByType.forEach(type => {
      console.log(`   ${type._id}: ${type.count}`);
    });
    
    console.log('\n📝 User Details:');
    users.forEach((user, index) => {
      console.log(`   ${index + 1}. ${user.name} (${user.email})`);
      console.log(`      Type: ${user.userType} | Department: ${user.department || 'N/A'}`);
      console.log(`      Status: ${user.isActive ? 'Active' : 'Inactive'} | Created: ${new Date(user.createdAt).toLocaleDateString()}`);
      console.log();
    });

    // 2. REPORTS COLLECTION
    console.log('\n📊 REPORTS COLLECTION:');
    console.log('-'.repeat(40));
    const reports = await Report.find()
      .populate('reporterId', 'name email')
      .populate('assignedOfficerId', 'name email')
      .lean();
    
    console.log(`📋 Total Reports: ${reports.length}`);
    
    if (reports.length > 0) {
      const reportsByStatus = await Report.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ]);
      
      const reportsByCategory = await Report.aggregate([
        { $group: { _id: '$category', count: { $sum: 1 } } }
      ]);
      
      console.log('\n📈 Reports by Status:');
      reportsByStatus.forEach(status => {
        console.log(`   ${status._id}: ${status.count}`);
      });
      
      console.log('\n📂 Reports by Category:');
      reportsByCategory.forEach(category => {
        console.log(`   ${category._id}: ${category.count}`);
      });
      
      console.log('\n📝 Report Details:');
      reports.forEach((report, index) => {
        console.log(`   ${index + 1}. ${report.title}`);
        console.log(`      Category: ${report.category} | Status: ${report.status}`);
        console.log(`      Priority: ${report.priority} | Location: ${report.location}`);
        console.log(`      Reporter: ${report.reporterId?.name || 'Unknown'} (${report.reporterId?.email || 'N/A'})`);
        console.log(`      Assigned: ${report.assignedOfficerId?.name || 'Unassigned'}`);
        console.log(`      Upvotes: ${report.upvotes} | Created: ${new Date(report.createdAt).toLocaleDateString()}`);
        console.log();
      });
    }

    // 3. CERTIFICATES COLLECTION
    console.log('\n📜 CERTIFICATES COLLECTION:');
    console.log('-'.repeat(40));
    const certificates = await Certificate.find()
      .populate('applicantId', 'name email')
      .populate('processingOfficer', 'name email')
      .lean();
    
    console.log(`📋 Total Certificates: ${certificates.length}`);
    
    if (certificates.length > 0) {
      const certsByType = await Certificate.aggregate([
        { $group: { _id: '$certificateType', count: { $sum: 1 } } }
      ]);
      
      const certsByStatus = await Certificate.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ]);
      
      console.log('\n📄 Certificates by Type:');
      certsByType.forEach(type => {
        console.log(`   ${type._id}: ${type.count}`);
      });
      
      console.log('\n📊 Certificates by Status:');
      certsByStatus.forEach(status => {
        console.log(`   ${status._id}: ${status.count}`);
      });
      
      console.log('\n📝 Certificate Details:');
      certificates.forEach((cert, index) => {
        console.log(`   ${index + 1}. ${cert.certificateType}`);
        console.log(`      Application #: ${cert.applicationNumber}`);
        console.log(`      Status: ${cert.status} | Priority: ${cert.priority}`);
        console.log(`      Applicant: ${cert.applicantId?.name || 'Unknown'} (${cert.applicantId?.email || 'N/A'})`);
        console.log(`      Processing Officer: ${cert.processingOfficer?.name || 'Unassigned'}`);
        console.log(`      Submitted: ${new Date(cert.submissionDate).toLocaleDateString()}`);
        console.log();
      });
    }

    // 4. REGISTRATION REQUESTS COLLECTION
    console.log('\n📝 REGISTRATION REQUESTS COLLECTION:');
    console.log('-'.repeat(40));
    const registrations = await RegistrationRequest.find().lean();
    console.log(`📋 Total Registration Requests: ${registrations.length}`);
    
    if (registrations.length > 0) {
      const regsByStatus = await RegistrationRequest.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ]);
      
      console.log('\n📊 Requests by Status:');
      regsByStatus.forEach(status => {
        console.log(`   ${status._id}: ${status.count}`);
      });
      
      console.log('\n📝 Registration Details:');
      registrations.forEach((reg, index) => {
        console.log(`   ${index + 1}. ${reg.name} (${reg.email})`);
        console.log(`      Type: ${reg.userType} | Department: ${reg.department || 'N/A'}`);
        console.log(`      Status: ${reg.status} | Phone: ${reg.phone}`);
        console.log(`      Location: ${reg.location} | Submitted: ${new Date(reg.submittedAt).toLocaleDateString()}`);
        console.log();
      });
    }

    // 5. PASSWORD RESET REQUESTS COLLECTION
    console.log('\n🔐 PASSWORD RESET REQUESTS COLLECTION:');
    console.log('-'.repeat(40));
    const passwordResets = await PasswordResetRequest.find().lean();
    console.log(`📋 Total Password Reset Requests: ${passwordResets.length}`);
    
    if (passwordResets.length > 0) {
      console.log('\n📝 Password Reset Details:');
      passwordResets.forEach((reset, index) => {
        console.log(`   ${index + 1}. ${reset.email}`);
        console.log(`      Status: ${reset.status} | Type: ${reset.requestType}`);
        console.log(`      Requested: ${new Date(reset.requestedAt).toLocaleDateString()}`);
        console.log(`      Expires: ${reset.expiresAt ? new Date(reset.expiresAt).toLocaleDateString() : 'N/A'}`);
        console.log();
      });
    }

    // 6. NEED REQUESTS COLLECTION
    console.log('\n🤲 NEED REQUESTS COLLECTION:');
    console.log('-'.repeat(40));
    const needRequests = await NeedRequest.find()
      .populate('requesterId', 'name email')
      .lean();
    
    console.log(`📋 Total Need Requests: ${needRequests.length}`);
    
    if (needRequests.length > 0) {
      const needsByStatus = await NeedRequest.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ]);
      
      console.log('\n📊 Need Requests by Status:');
      needsByStatus.forEach(status => {
        console.log(`   ${status._id}: ${status.count}`);
      });
      
      console.log('\n📝 Need Request Details:');
      needRequests.forEach((need, index) => {
        console.log(`   ${index + 1}. ${need.title}`);
        console.log(`      Category: ${need.category} | Status: ${need.status}`);
        console.log(`      Priority: ${need.priority} | Location: ${need.location}`);
        console.log(`      Requester: ${need.requesterId?.name || 'Unknown'} (${need.requesterId?.email || 'N/A'})`);
        console.log(`      Created: ${new Date(need.createdAt).toLocaleDateString()}`);
        console.log();
      });
    }

    // 7. FEEDBACK COLLECTION
    console.log('\n💬 FEEDBACK COLLECTION:');
    console.log('-'.repeat(40));
    const feedback = await Feedback.find()
      .populate('userId', 'name email')
      .lean();
    
    console.log(`📋 Total Feedback: ${feedback.length}`);
    
    if (feedback.length > 0) {
      const feedbackByCategory = await Feedback.aggregate([
        { $group: { _id: '$category', count: { $sum: 1 } } }
      ]);
      
      console.log('\n📂 Feedback by Category:');
      feedbackByCategory.forEach(category => {
        console.log(`   ${category._id}: ${category.count}`);
      });
      
      console.log('\n📝 Feedback Details:');
      feedback.forEach((fb, index) => {
        console.log(`   ${index + 1}. ${fb.subject}`);
        console.log(`      Category: ${fb.category} | Rating: ${fb.rating}/5`);
        console.log(`      User: ${fb.userId?.name || 'Anonymous'} (${fb.userId?.email || 'N/A'})`);
        console.log(`      Submitted: ${new Date(fb.createdAt).toLocaleDateString()}`);
        console.log();
      });
    }

    // 8. NOTIFICATIONS COLLECTION
    console.log('\n🔔 NOTIFICATIONS COLLECTION:');
    console.log('-'.repeat(40));
    const notifications = await Notification.find()
      .populate('userId', 'name email')
      .lean();
    
    console.log(`📋 Total Notifications: ${notifications.length}`);
    
    if (notifications.length > 0) {
      const notificationsByType = await Notification.aggregate([
        { $group: { _id: '$type', count: { $sum: 1 } } }
      ]);
      
      const readStats = await Notification.aggregate([
        { $group: { _id: '$isRead', count: { $sum: 1 } } }
      ]);
      
      console.log('\n📂 Notifications by Type:');
      notificationsByType.forEach(type => {
        console.log(`   ${type._id}: ${type.count}`);
      });
      
      console.log('\n📊 Read Status:');
      readStats.forEach(stat => {
        console.log(`   ${stat._id ? 'Read' : 'Unread'}: ${stat.count}`);
      });
      
      console.log('\n📝 Recent Notifications (Last 10):');
      const recentNotifications = notifications
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
        .slice(0, 10);
      
      recentNotifications.forEach((notif, index) => {
        console.log(`   ${index + 1}. ${notif.title}`);
        console.log(`      Type: ${notif.type} | Priority: ${notif.priority}`);
        console.log(`      User: ${notif.userId?.name || 'System'} | Read: ${notif.isRead ? 'Yes' : 'No'}`);
        console.log(`      Created: ${new Date(notif.createdAt).toLocaleString()}`);
        console.log();
      });
    }

    // SUMMARY STATISTICS
    console.log('\n' + '='.repeat(80));
    console.log('📈 SUMMARY STATISTICS');
    console.log('=' .repeat(80));
    console.log(`Total Users: ${users.length}`);
    console.log(`Total Reports: ${reports.length}`);
    console.log(`Total Certificates: ${certificates.length}`);
    console.log(`Total Registration Requests: ${registrations.length}`);
    console.log(`Total Password Resets: ${passwordResets.length}`);
    console.log(`Total Need Requests: ${needRequests.length}`);
    console.log(`Total Feedback: ${feedback.length}`);
    console.log(`Total Notifications: ${notifications.length}`);
    console.log('\n✅ Database inspection completed successfully!');

  } catch (error) {
    console.error('❌ Database inspection failed:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
    process.exit(0);
  }
}

// Run the inspection
inspectDatabase();