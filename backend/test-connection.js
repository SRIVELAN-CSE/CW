// Test script to verify database connection and API functionality
const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

const testDatabaseConnection = async () => {
  try {
    console.log('🔍 Testing database connection...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Database connected successfully');
    
    // Test creating a user
    console.log('🧪 Testing user creation...');
    
    // Check if test user exists
    const existingUser = await User.findOne({ email: 'test@example.com' });
    if (existingUser) {
      console.log('🗑️ Removing existing test user...');
      await User.deleteOne({ email: 'test@example.com' });
    }
    
    // Create a test user
    const testUser = new User({
      name: 'Test User',
      email: 'test@example.com',
      phone: '1234567890',
      password: 'testpassword123',
      userType: 'public',
      location: 'Test Location',
      isVerified: true
    });
    
    const savedUser = await testUser.save();
    console.log('✅ User created successfully:', {
      id: savedUser._id,
      name: savedUser.name,
      email: savedUser.email,
      userType: savedUser.userType
    });
    
    // Test finding the user
    const foundUser = await User.findById(savedUser._id);
    console.log('✅ User found successfully:', foundUser.name);
    
    // Clean up test user
    await User.deleteOne({ _id: savedUser._id });
    console.log('🗑️ Test user cleaned up');
    
    // Test user count
    const userCount = await User.countDocuments();
    console.log(`📊 Total users in database: ${userCount}`);
    
    console.log('🎉 All database tests passed!');
    
  } catch (error) {
    console.error('❌ Database test failed:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('📴 Database connection closed');
  }
};

// Run the test
testDatabaseConnection();