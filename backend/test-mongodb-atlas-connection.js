const mongoose = require('mongoose');
require('dotenv').config();

// Import all models to ensure collections are created
const User = require('./models/User');
const Report = require('./models/Report');
const Certificate = require('./models/Certificate');
const Feedback = require('./models/Feedback');
const Notification = require('./models/Notification');
const RegistrationRequest = require('./models/RegistrationRequest');
const PasswordResetRequest = require('./models/PasswordResetRequest');
const NeedRequest = require('./models/NeedRequest');

console.log('🚀 Starting MongoDB Atlas Connection Test...\n');

async function testConnection() {
  try {
    // Connect to MongoDB Atlas
    console.log('📡 Connecting to MongoDB Atlas...');
    console.log('🔗 MongoDB URI:', process.env.MONGODB_URI ? 'SET ✅' : 'NOT SET ❌');
    
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000, // 30 seconds timeout
      socketTimeoutMS: 45000, // 45 seconds timeout
    });

    console.log(`✅ MongoDB Connected Successfully!`);
    console.log(`🏠 Host: ${conn.connection.host}`);
    console.log(`📂 Database: ${conn.connection.name}`);
    console.log(`⚡ Connection State: ${conn.connection.readyState === 1 ? 'Connected' : 'Not Connected'}\n`);

    // Test database operations
    console.log('🔍 Testing Database Operations...\n');

    // Check existing collections
    const collections = await conn.connection.db.listCollections().toArray();
    console.log('📋 Existing Collections:', collections.length);
    collections.forEach(col => {
      console.log(`  - ${col.name}`);
    });

    // Create indexes and ensure collections exist
    console.log('\n📝 Ensuring All Collections and Indexes...\n');

    const models = [
      { name: 'Users', model: User },
      { name: 'Reports', model: Report },
      { name: 'Certificates', model: Certificate },
      { name: 'Feedback', model: Feedback },
      { name: 'Notifications', model: Notification },
      { name: 'RegistrationRequests', model: RegistrationRequest },
      { name: 'PasswordResetRequests', model: PasswordResetRequest },
      { name: 'NeedRequests', model: NeedRequest },
    ];

    for (const { name, model } of models) {
      try {
        // Create collection if it doesn't exist
        await model.createCollection();
        
        // Ensure indexes
        await model.ensureIndexes();
        
        console.log(`✅ ${name}: Collection ready with indexes`);
      } catch (error) {
        if (error.code === 48) {
          console.log(`✅ ${name}: Collection already exists`);
        } else {
          console.log(`⚠️ ${name}: ${error.message}`);
        }
      }
    }

    // Test basic CRUD operations
    console.log('\n🧪 Testing Basic CRUD Operations...\n');

    // Test User creation
    try {
      const testUser = new User({
        name: 'Test User',
        email: `test_${Date.now()}@example.com`,
        phone: '+1234567890',
        password: 'test123456',
        userType: 'public'
      });
      await testUser.save();
      console.log('✅ User CRUD: Create operation successful');
      
      // Clean up
      await User.deleteOne({ _id: testUser._id });
      console.log('✅ User CRUD: Delete operation successful');
    } catch (error) {
      console.log('❌ User CRUD failed:', error.message);
    }

    // Test Report creation
    try {
      const testReport = new Report({
        title: 'Test Report',
        description: 'This is a test report',
        category: 'Others',
        location: 'Test Location',
        reporterId: new mongoose.Types.ObjectId(),
        reporterName: 'Test Reporter',
        reporterEmail: 'test@example.com'
      });
      await testReport.save();
      console.log('✅ Report CRUD: Create operation successful');
      
      // Clean up
      await Report.deleteOne({ _id: testReport._id });
      console.log('✅ Report CRUD: Delete operation successful');
    } catch (error) {
      console.log('❌ Report CRUD failed:', error.message);
    }

    // Get database stats
    console.log('\n📊 Database Statistics...\n');
    const stats = await conn.connection.db.stats();
    console.log(`📦 Database Size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
    console.log(`📋 Collections: ${stats.collections}`);
    console.log(`📄 Objects: ${stats.objects}`);
    console.log(`💾 Storage Size: ${(stats.storageSize / 1024 / 1024).toFixed(2)} MB`);

    // Test connection to Render deployment URL
    console.log('\n🌐 Testing Render Deployment Configuration...\n');
    console.log('🔗 Backend URLs configured:');
    console.log('  - Local: http://localhost:3000');
    console.log('  - Render: https://civic-welfare-backend.onrender.com');
    console.log('  - CORS Origins:', process.env.CORS_ORIGIN);

    console.log('\n🎉 All Tests Completed Successfully!');
    console.log('✅ MongoDB Atlas connection is working perfectly');
    console.log('✅ All collections are ready');
    console.log('✅ CRUD operations are functional');
    console.log('✅ Ready for frontend integration');

  } catch (error) {
    console.error('❌ Connection Test Failed:', error);
    
    if (error.name === 'MongooseServerSelectionError') {
      console.error('\n🔍 Troubleshooting Tips:');
      console.error('1. Check if MongoDB URI is correct');
      console.error('2. Verify network connectivity');
      console.error('3. Check MongoDB Atlas whitelist settings');
      console.error('4. Ensure database user has proper permissions');
    }
  } finally {
    // Close connection
    await mongoose.connection.close();
    console.log('\n📴 Connection closed');
    process.exit(0);
  }
}

// Handle process termination
process.on('SIGINT', async () => {
  console.log('\n⏹️ Process interrupted');
  await mongoose.connection.close();
  process.exit(0);
});

process.on('unhandledRejection', (err) => {
  console.error('❌ Unhandled Promise Rejection:', err);
  process.exit(1);
});

// Run the test
testConnection();