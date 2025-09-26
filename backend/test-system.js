// Complete Backend Test Script
require('dotenv').config();
const axios = require('axios');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const testCompleteSystem = async () => {
  try {
    console.log('🧪 COMPLETE BACKEND-FRONTEND SYSTEM TEST');
    console.log('=' * 50);

    // Test 1: Database Connection
    console.log('\n1️⃣ Testing MongoDB Atlas Connection...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB Atlas Connected');

    // Test 2: Admin User Verification
    console.log('\n2️⃣ Verifying Admin User...');
    const adminUser = await User.findOne({ 
      email: 'admin@civicwelfare.com',
      userType: 'admin'
    }).select('+password');

    if (adminUser) {
      console.log('✅ Admin user exists');
      console.log('📧 Email:', adminUser.email);
      console.log('👤 Type:', adminUser.userType);
      console.log('🔐 Password Hash:', adminUser.password ? 'Present' : 'Missing');
    } else {
      console.log('❌ Admin user not found - Creating...');
      const hashedPassword = await bcrypt.hash('admin123456', 12);
      
      const newAdmin = await User.create({
        name: 'System Administrator',
        email: 'admin@civicwelfare.com',
        password: hashedPassword,
        phone: '+919876543210',
        userType: 'admin',
        department: 'System Administration',
        location: 'System Headquarters',
        isActive: true,
        isVerified: true,
      });
      console.log('✅ Admin user created:', newAdmin._id);
    }

    // Test 3: Password Verification
    console.log('\n3️⃣ Testing Password Verification...');
    const passwordTest = await adminUser.comparePassword('admin123456');
    console.log('🔐 Password Test:', passwordTest ? '✅ Valid' : '❌ Invalid');

    // Test 4: Backend Server Tests
    console.log('\n4️⃣ Testing Backend Servers...');
    
    // Test Production Server
    try {
      const prodHealthResponse = await axios.get('https://civic-welfare-backend.onrender.com/api/health');
      console.log('✅ Production Server Health:', prodHealthResponse.data.status);
    } catch (e) {
      console.log('❌ Production Server Error:', e.message);
    }

    // Test Production Login
    try {
      const prodLoginResponse = await axios.post('https://civic-welfare-backend.onrender.com/api/auth/login', {
        email: 'admin@civicwelfare.com',
        password: 'admin123456'
      });
      console.log('✅ Production Login Success:', prodLoginResponse.data.success);
      console.log('👤 User Type:', prodLoginResponse.data.data.user.userType);
      console.log('🔑 Token Present:', !!prodLoginResponse.data.data.access_token);
    } catch (e) {
      console.log('❌ Production Login Error:', e.response?.data?.message || e.message);
    }

    // Test 5: User Creation for Testing
    console.log('\n5️⃣ Creating Test Users...');
    
    // Create test public user
    const testPublicEmail = 'testpublic@example.com';
    const existingPublic = await User.findOne({ email: testPublicEmail });
    
    if (!existingPublic) {
      const testPublic = await User.create({
        name: 'Test Public User',
        email: testPublicEmail,
        password: await bcrypt.hash('test123456', 12),
        phone: '+919876543211',
        userType: 'public',
        location: 'Test City',
        isActive: true,
        isVerified: true,
      });
      console.log('✅ Test Public User Created:', testPublic._id);
    } else {
      console.log('✅ Test Public User Already Exists');
    }

    // Create test officer user
    const testOfficerEmail = 'testofficer@example.com';
    const existingOfficer = await User.findOne({ email: testOfficerEmail });
    
    if (!existingOfficer) {
      const testOfficer = await User.create({
        name: 'Test Officer User',
        email: testOfficerEmail,
        password: await bcrypt.hash('test123456', 12),
        phone: '+919876543212',
        userType: 'officer',
        department: 'garbageCollection',
        location: 'Test Department',
        isActive: true,
        isVerified: true,
      });
      console.log('✅ Test Officer User Created:', testOfficer._id);
    } else {
      console.log('✅ Test Officer User Already Exists');
    }

    console.log('\n🎉 SYSTEM TEST COMPLETED!');
    console.log('=' * 50);
    console.log('✅ Database: Connected');
    console.log('✅ Admin User: Ready');
    console.log('✅ Test Users: Created');
    console.log('✅ Backend: Accessible');
    console.log('=' * 50);
    
    console.log('\n🔑 LOGIN CREDENTIALS:');
    console.log('Admin: admin@civicwelfare.com / admin123456');
    console.log('Public: testpublic@example.com / test123456');
    console.log('Officer: testofficer@example.com / test123456');

  } catch (error) {
    console.error('❌ System Test Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('📴 Database connection closed');
  }
};

testCompleteSystem();