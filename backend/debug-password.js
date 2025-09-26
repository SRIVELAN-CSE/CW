// Debug Password Issue
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

const debugPassword = async () => {
  try {
    console.log('🔍 DEBUGGING PASSWORD ISSUE...');
    
    await mongoose.connect(process.env.MONGODB_URI);

    // Test bcrypt directly
    const testPassword = 'admin123456';
    const directHash = await bcrypt.hash(testPassword, 12);
    const directCompare = await bcrypt.compare(testPassword, directHash);
    
    console.log('🧪 Direct bcrypt test:', directCompare ? '✅ VALID' : '❌ INVALID');

    // Find admin user
    const adminUser = await User.findOne({ 
      email: 'admin@civicwelfare.com' 
    }).select('+password');

    if (adminUser) {
      console.log('👤 Admin found:', adminUser.email);
      console.log('🔐 Stored hash:', adminUser.password);
      
      // Test direct comparison
      const directTest = await bcrypt.compare('admin123456', adminUser.password);
      console.log('🔍 Direct compare:', directTest ? '✅ VALID' : '❌ INVALID');
      
      // Test method comparison
      if (adminUser.comparePassword) {
        const methodTest = await adminUser.comparePassword('admin123456');
        console.log('🔍 Method compare:', methodTest ? '✅ VALID' : '❌ INVALID');
      } else {
        console.log('❌ comparePassword method not found');
      }
    } else {
      console.log('❌ Admin user not found');
    }

  } catch (error) {
    console.error('❌ Debug error:', error);
  } finally {
    await mongoose.connection.close();
  }
};

debugPassword();