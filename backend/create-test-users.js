// Create a complete test user set for the app
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const createTestUsers = async () => {
  try {
    console.log('👥 CREATING COMPLETE TEST USER SET...');
    
    await mongoose.connect(process.env.MONGODB_URI);

    // Test users to create
    const testUsers = [
      {
        name: 'Admin User',
        email: 'admin@civicwelfare.com',
        password: 'admin123456',
        phone: '+919876543210',
        userType: 'admin',
        location: 'System',
        isActive: true,
        isVerified: true,
      },
      {
        name: 'Public Test User',
        email: 'public@test.com',
        password: 'test123456',
        phone: '+919876543211',
        userType: 'public',
        location: 'Test City',
        isActive: true,
        isVerified: true,
      },
      {
        name: 'Officer Test User',
        email: 'officer@test.com',
        password: 'test123456',
        phone: '+919876543212',
        userType: 'officer',
        department: 'garbageCollection',
        location: 'Test Department',
        isActive: true,
        isVerified: true,
      }
    ];

    for (const userData of testUsers) {
      // Check if user exists
      const existing = await User.findOne({ email: userData.email });
      if (existing) {
        console.log(`✅ ${userData.userType} user already exists: ${userData.email}`);
        continue;
      }

      // Create new user
      const user = await User.create(userData);
      console.log(`✅ Created ${userData.userType} user: ${userData.email} (ID: ${user._id})`);
    }

    console.log('\n🎉 ALL TEST USERS READY!');
    console.log('=' * 40);
    console.log('Admin Login: admin@civicwelfare.com / admin123456');
    console.log('Public Login: public@test.com / test123456');
    console.log('Officer Login: officer@test.com / test123456');
    console.log('=' * 40);

  } catch (error) {
    console.error('❌ Error creating test users:', error.message);
  } finally {
    await mongoose.connection.close();
  }
};

createTestUsers();