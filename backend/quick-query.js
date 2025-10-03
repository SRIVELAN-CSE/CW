// Quick Database Query Tool
// Run specific queries to check dashboard data

require('dotenv').config();
const mongoose = require('mongoose');

// Import models
const User = require('./models/User');
const Report = require('./models/Report');
const Certificate = require('./models/Certificate');
const RegistrationRequest = require('./models/RegistrationRequest');
const Notification = require('./models/Notification');

async function quickQuery() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas\n');

    // Quick counts
    console.log('📊 QUICK DATABASE OVERVIEW:');
    console.log('-'.repeat(40));
    
    const [
      userCount,
      reportCount,
      certificateCount,
      registrationCount,
      notificationCount
    ] = await Promise.all([
      User.countDocuments(),
      Report.countDocuments(),
      Certificate.countDocuments(),
      RegistrationRequest.countDocuments(),
      Notification.countDocuments()
    ]);

    console.log(`👥 Users: ${userCount}`);
    console.log(`📊 Reports: ${reportCount}`);
    console.log(`📜 Certificates: ${certificateCount}`);
    console.log(`📝 Registration Requests: ${registrationCount}`);
    console.log(`🔔 Notifications: ${notificationCount}`);

    // Recent activity
    console.log('\n🕒 RECENT ACTIVITY:');
    console.log('-'.repeat(40));

    // Latest user registrations
    const recentUsers = await User.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .select('name email userType createdAt')
      .lean();

    console.log('\n👤 Latest Users:');
    recentUsers.forEach((user, index) => {
      console.log(`   ${index + 1}. ${user.name} (${user.userType}) - ${new Date(user.createdAt).toLocaleString()}`);
    });

    // Latest reports
    const recentReports = await Report.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('reporterId', 'name')
      .select('title category status reporterId createdAt')
      .lean();

    if (recentReports.length > 0) {
      console.log('\n📊 Latest Reports:');
      recentReports.forEach((report, index) => {
        console.log(`   ${index + 1}. ${report.title} (${report.category}) - ${report.status}`);
        console.log(`       By: ${report.reporterId?.name || 'Unknown'} - ${new Date(report.createdAt).toLocaleString()}`);
      });
    }

    // Admin users
    console.log('\n👑 ADMIN USERS:');
    console.log('-'.repeat(40));
    const admins = await User.find({ userType: 'admin' })
      .select('name email isActive lastLoginAt')
      .lean();

    admins.forEach((admin, index) => {
      console.log(`   ${index + 1}. ${admin.name} (${admin.email})`);
      console.log(`       Status: ${admin.isActive ? 'Active' : 'Inactive'}`);
      console.log(`       Last Login: ${admin.lastLoginAt ? new Date(admin.lastLoginAt).toLocaleString() : 'Never'}`);
    });

    // Officer users
    console.log('\n👮 OFFICER USERS:');
    console.log('-'.repeat(40));
    const officers = await User.find({ userType: 'officer' })
      .select('name email department isActive')
      .lean();

    if (officers.length > 0) {
      officers.forEach((officer, index) => {
        console.log(`   ${index + 1}. ${officer.name} (${officer.email})`);
        console.log(`       Department: ${officer.department || 'Not Assigned'}`);
        console.log(`       Status: ${officer.isActive ? 'Active' : 'Inactive'}`);
      });
    } else {
      console.log('   No officers found');
    }

    await mongoose.connection.close();
    console.log('\n✅ Quick query completed!');

  } catch (error) {
    console.error('❌ Query failed:', error.message);
  }
}

// Get command line arguments
const args = process.argv.slice(2);
const command = args[0];

if (command === 'users') {
  // Show only users
  mongoose.connect(process.env.MONGODB_URI).then(async () => {
    const users = await User.find().select('name email userType department isActive createdAt').lean();
    console.log('👥 ALL USERS:');
    users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.name} (${user.email}) - ${user.userType}`);
      if (user.department) console.log(`   Department: ${user.department}`);
      console.log(`   Status: ${user.isActive ? 'Active' : 'Inactive'} | Created: ${new Date(user.createdAt).toLocaleDateString()}`);
      console.log();
    });
    mongoose.connection.close();
  });
} else if (command === 'reports') {
  // Show only reports
  mongoose.connect(process.env.MONGODB_URI).then(async () => {
    const reports = await Report.find()
      .populate('reporterId', 'name')
      .populate('assignedOfficerId', 'name')
      .select('title category status priority location reporterId assignedOfficerId createdAt')
      .lean();
    
    console.log('📊 ALL REPORTS:');
    reports.forEach((report, index) => {
      console.log(`${index + 1}. ${report.title}`);
      console.log(`   Category: ${report.category} | Status: ${report.status} | Priority: ${report.priority}`);
      console.log(`   Location: ${report.location}`);
      console.log(`   Reporter: ${report.reporterId?.name || 'Unknown'}`);
      console.log(`   Assigned: ${report.assignedOfficerId?.name || 'Unassigned'}`);
      console.log(`   Created: ${new Date(report.createdAt).toLocaleString()}`);
      console.log();
    });
    mongoose.connection.close();
  });
} else if (command === 'certificates') {
  // Show only certificates
  mongoose.connect(process.env.MONGODB_URI).then(async () => {
    const certificates = await Certificate.find()
      .populate('applicantId', 'name')
      .select('certificateType applicationNumber status priority applicantId submissionDate')
      .lean();
    
    console.log('📜 ALL CERTIFICATES:');
    certificates.forEach((cert, index) => {
      console.log(`${index + 1}. ${cert.certificateType}`);
      console.log(`   Application #: ${cert.applicationNumber}`);
      console.log(`   Status: ${cert.status} | Priority: ${cert.priority}`);
      console.log(`   Applicant: ${cert.applicantId?.name || 'Unknown'}`);
      console.log(`   Submitted: ${new Date(cert.submissionDate).toLocaleDateString()}`);
      console.log();
    });
    mongoose.connection.close();
  });
} else {
  // Run full quick query
  quickQuery();
}

module.exports = { quickQuery };