/**
 * SECURE Admin Setup Script
 * 
 * This script ensures ONLY ONE admin account exists in the system.
 * - Removes ALL existing admin accounts
 * - Creates ONE default admin with secure credentials
 * - Verifies system security
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

// SINGLE ADMIN CONFIGURATION
const ADMIN_CONFIG = {
  name: 'System Administrator',
  email: 'admin@civicwelfare.com',
  phone: '+919876543210',
  password: 'CivicAdmin2024!',
  securityCode: 'ADMIN2024SEC',  // Security code for admin
  userType: 'admin',
  location: 'System Headquarters',
  isActive: true,
  isVerified: true
};

async function secureAdminSetup() {
  try {
    console.log('🔐 ===== SECURE ADMIN SETUP =====');
    console.log('🔄 Connecting to MongoDB...');
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    console.log(`📂 Database: ${mongoose.connection.db.databaseName}`);

    // STEP 1: Remove ALL existing admin accounts (security measure)
    console.log('\n🗑️  Removing ALL existing admin accounts...');
    const deletedAdmins = await User.deleteMany({ userType: 'admin' });
    console.log(`   ✅ Removed ${deletedAdmins.deletedCount} admin accounts`);

    // STEP 2: Verify no admin accounts exist
    const existingAdmins = await User.countDocuments({ userType: 'admin' });
    if (existingAdmins > 0) {
      throw new Error(`❌ Security Error: ${existingAdmins} admin accounts still exist after cleanup`);
    }
    console.log('   ✅ Verified: No admin accounts exist');

    // STEP 3: Create the SINGLE default admin
    console.log('\n👤 Creating SINGLE default admin...');
    const admin = new User(ADMIN_CONFIG);
    await admin.save();
    
    console.log('   ✅ Default admin created successfully');
    console.log(`   🆔 Admin ID: ${admin._id}`);

    // STEP 4: Verify ONLY ONE admin exists
    const finalAdminCount = await User.countDocuments({ userType: 'admin' });
    if (finalAdminCount !== 1) {
      throw new Error(`❌ Security Error: Expected 1 admin, found ${finalAdminCount}`);
    }

    // STEP 5: Verify admin details
    const verifyAdmin = await User.findOne({ email: ADMIN_CONFIG.email });
    if (!verifyAdmin || verifyAdmin.userType !== 'admin') {
      throw new Error('❌ Security Error: Admin verification failed');
    }

    console.log('\n✅ ===== SECURE ADMIN SETUP COMPLETED =====');
    console.log('🔐 SINGLE ADMIN CREDENTIALS:');
    console.log('=====================================');
    console.log(`Email       : ${ADMIN_CONFIG.email}`);
    console.log(`Password    : ${ADMIN_CONFIG.password}`);
    console.log(`Security Code: ${ADMIN_CONFIG.securityCode}`);
    console.log('=====================================');
    
    console.log('\n🔒 SECURITY SUMMARY:');
    console.log(`   • Total Admins: ${finalAdminCount} (MAXIMUM ALLOWED: 1)`);
    console.log(`   • Admin Email: ${verifyAdmin.email}`);
    console.log(`   • Account Status: ${verifyAdmin.isActive ? 'Active' : 'Inactive'}`);
    console.log(`   • Verification: ${verifyAdmin.isVerified ? 'Verified' : 'Unverified'}`);

    console.log('\n⚠️  IMPORTANT SECURITY NOTES:');
    console.log('• ONLY this admin account can access admin functions');
    console.log('• Change password after first login in production');
    console.log('• Security code required for sensitive operations');
    console.log('• No duplicate admin accounts allowed');

  } catch (error) {
    console.error('\n❌ Error during secure admin setup:', error.message);
    if (error.name === 'ValidationError') {
      console.error('Validation details:', Object.keys(error.errors).map(key => 
        `${key}: ${error.errors[key].message}`
      ));
    }
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('\n📴 Database connection closed');
  }
}

// Run the secure setup
if (require.main === module) {
  secureAdminSetup()
    .then(() => {
      console.log('\n🎉 Secure admin setup completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Fatal error:', error);
      process.exit(1);
    });
}

module.exports = { secureAdminSetup, ADMIN_CONFIG };