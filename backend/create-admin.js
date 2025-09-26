// Create Admin User Script
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const createAdminUser = async () => {
  try {
    console.log('🔄 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas');

    // Check if admin already exists
    const existingAdmin = await User.findOne({ 
      email: 'admin@civicwelfare.com',
      userType: 'admin'
    });

    if (existingAdmin) {
      console.log('✅ Admin user already exists');
      console.log('📧 Email: admin@civicwelfare.com');
      console.log('🔐 Password: admin123456');
      console.log('👤 User Type: admin');
      process.exit(0);
    }

    // Create new admin user
    const hashedPassword = await bcrypt.hash('admin123456', 12);
    
    const adminUser = new User({
      name: 'System Administrator',
      email: 'admin@civicwelfare.com',
      password: hashedPassword,
      phone: '+919876543210',
      userType: 'admin',
      department: 'System Administration',
      designation: 'Administrator',
      location: 'System Headquarters',
      isActive: true,
      isVerified: true,
    });

    await adminUser.save();
    
    console.log('🎉 Admin user created successfully!');
    console.log('===============================');
    console.log('📧 Email: admin@civicwelfare.com');
    console.log('🔐 Password: admin123456');
    console.log('👤 User Type: admin');
    console.log('🆔 User ID:', adminUser._id);
    console.log('===============================');
    
    console.log('✅ You can now login as admin in the app');

  } catch (error) {
    console.error('❌ Error creating admin user:', error);
  } finally {
    await mongoose.connection.close();
    console.log('📴 Database connection closed');
  }
};

// Run the script
createAdminUser();