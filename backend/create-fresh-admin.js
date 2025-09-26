// Create Fresh Admin - Simple Approach
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const createFreshAdmin = async () => {
  try {
    console.log('🔄 CREATING FRESH ADMIN USER...');
    
    await mongoose.connect(process.env.MONGODB_URI);

    // Delete all existing admin users
    const deleteResult = await User.deleteMany({ userType: 'admin' });
    console.log('🗑️ Deleted', deleteResult.deletedCount, 'admin users');

    // Create admin with minimal required fields
    const adminData = {
      name: 'Admin User',
      email: 'admin@civicwelfare.com',
      password: 'admin123456', // Let the pre-save hook handle hashing
      phone: '+919876543210',
      userType: 'admin',
      location: 'System',
      isActive: true,
      isVerified: true,
    };

    console.log('💾 Creating admin with data:', {
      name: adminData.name,
      email: adminData.email,
      userType: adminData.userType,
      password: '[PROTECTED]'
    });

    const adminUser = await User.create(adminData);
    console.log('✅ Admin created successfully:', adminUser._id);

    // Test login immediately
    const testUser = await User.findOne({ email: 'admin@civicwelfare.com' }).select('+password');
    console.log('🔍 Testing password...');
    
    const passwordTest = await testUser.comparePassword('admin123456');
    console.log('🔐 Password test:', passwordTest ? '✅ SUCCESS' : '❌ FAILED');

    if (passwordTest) {
      console.log('\n🎉 ADMIN USER READY FOR LOGIN!');
      console.log('📧 Email: admin@civicwelfare.com');
      console.log('🔐 Password: admin123456');
    }

  } catch (error) {
    console.error('❌ Error creating admin:', error.message);
    if (error.errors) {
      Object.keys(error.errors).forEach(key => {
        console.error(`  - ${key}: ${error.errors[key].message}`);
      });
    }
  } finally {
    await mongoose.connection.close();
  }
};

createFreshAdmin();