const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');
const Report = require('./models/Report');
const Notification = require('./models/Notification');

async function cleanupCollections() {
  try {
    console.log('🧹 Starting database cleanup...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Delete all test/sample data
    const userResult = await User.deleteMany({});
    console.log(`🗑️  Deleted ${userResult.deletedCount} users`);

    const reportResult = await Report.deleteMany({});
    console.log(`🗑️  Deleted ${reportResult.deletedCount} reports`);

    const notificationResult = await Notification.deleteMany({});
    console.log(`🗑️  Deleted ${notificationResult.deletedCount} notifications`);

    console.log('✅ Database cleanup completed successfully!');
    console.log(`📊 Total documents removed: ${userResult.deletedCount + reportResult.deletedCount + notificationResult.deletedCount}`);

  } catch (error) {
    console.error('❌ Cleanup error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('📴 Database connection closed');
  }
}

if (require.main === module) {
  cleanupCollections();
}

module.exports = cleanupCollections;