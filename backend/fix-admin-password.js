// Fix Admin Password
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const fixAdminPassword = async () => {
  try {
    console.log('🔧 FIXING ADMIN PASSWORD...');
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find and delete existing admin
    await User.deleteOne({ email: 'admin@civicwelfare.com', userType: 'admin' });
    console.log('🗑️ Removed existing admin user');

    // Create new admin with proper password
    const hashedPassword = await bcrypt.hash('admin123456', 12);
    console.log('🔐 Password hashed successfully');

    const adminUser = await User.create({
      name: 'System Administrator',
      email: 'admin@civicwelfare.com',
      password: hashedPassword,
      phone: '+919876543210',
      userType: 'admin',
      department: 'others', // Use valid enum value
      location: 'System Headquarters',
      isActive: true,
      isVerified: true,
    });

    console.log('✅ New admin created:', adminUser._id);

    // Test password
    const testUser = await User.findOne({ email: 'admin@civicwelfare.com' }).select('+password');
    const passwordValid = await testUser.comparePassword('admin123456');
    
    console.log('🧪 Password test:', passwordValid ? '✅ VALID' : '❌ INVALID');

    console.log('\n🎉 ADMIN PASSWORD FIXED!');
    console.log('📧 Email: admin@civicwelfare.com');
    console.log('🔐 Password: admin123456');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
  }
};

fixAdminPassword();