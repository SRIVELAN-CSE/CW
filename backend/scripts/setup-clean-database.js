// Database cleanup and admin setup script
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const path = require('path');

// Import models
const User = require('../models/User');
const Report = require('../models/Report');
const RegistrationRequest = require('../models/RegistrationRequest');
const Certificate = require('../models/Certificate');
const Notification = require('../models/Notification');
const Feedback = require('../models/Feedback');
const NeedRequest = require('../models/NeedRequest');
const PasswordResetRequest = require('../models/PasswordResetRequest');

const cleanupAndSetupDatabase = async () => {
  try {
    console.log('🔄 Starting database cleanup and setup...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // 1. CLEAR ALL EXISTING DATA
    console.log('\n🗑️  Clearing all existing data...');
    
    const collections = [
      { model: User, name: 'Users' },
      { model: Report, name: 'Reports' },
      { model: RegistrationRequest, name: 'Registration Requests' },
      { model: Certificate, name: 'Certificates' },
      { model: Notification, name: 'Notifications' },
      { model: Feedback, name: 'Feedback' },
      { model: NeedRequest, name: 'Need Requests' },
      { model: PasswordResetRequest, name: 'Password Reset Requests' }
    ];

    for (const { model, name } of collections) {
      const count = await model.countDocuments();
      if (count > 0) {
        await model.deleteMany({});
        console.log(`   ✅ Cleared ${count} ${name}`);
      } else {
        console.log(`   ℹ️  No ${name} to clear`);
      }
    }

    // 2. CREATE DEFAULT ADMIN
    console.log('\n👤 Creating default admin user...');
    
    const defaultAdmin = {
      name: 'System Administrator',
      email: 'admin@civicwelfare.com',
      phone: '+911234567890',
      password: 'CivicAdmin2024!', // Strong default password
      userType: 'admin',
      location: 'System',
      // No department needed for admin users
      isActive: true,
      isVerified: true
    };

    // Create new admin (User model will hash password automatically)
    const admin = await User.create(defaultAdmin);
    console.log('   ✅ Default admin created successfully');
    console.log(`   📧 Email: ${defaultAdmin.email}`);
    console.log(`   🔐 Password: ${defaultAdmin.password}`);
    console.log(`   🆔 Admin ID: ${admin._id}`);

    // 3. VERIFY DATABASE STATE
    console.log('\n📊 Database state after cleanup:');
    for (const { model, name } of collections) {
      const count = await model.countDocuments();
      console.log(`   ${name}: ${count} records`);
    }

    // 4. SECURITY CONFIRMATION
    console.log('\n✅ Setup completed successfully!');
    console.log('\n🔐 ADMIN LOGIN CREDENTIALS:');
    console.log('=====================================');
    console.log('Email    : admin@civicwelfare.com');
    console.log('Password : CivicAdmin2024!');
    console.log('=====================================');
    console.log('\n⚠️  IMPORTANT SECURITY NOTES:');
    console.log('• Change the admin password after first login');
    console.log('• Only this admin account can access admin functions');
    console.log('• No other users have admin privileges');
    console.log('• All test/sample data has been removed');
    console.log('• Database is now clean and production-ready');

    await mongoose.connection.close();
    console.log('\n📴 Database connection closed');

  } catch (error) {
    console.error('❌ Error during setup:', error);
    process.exit(1);
  }
};

// Run the setup
cleanupAndSetupDatabase()
  .then(() => {
    console.log('\n🎉 Database cleanup and admin setup completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Setup failed:', error);
    process.exit(1);
  });