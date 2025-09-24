require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const User = require('../models/User');
const Report = require('../models/Report');
const connectDB = require('../config/database');

const seedData = async () => {
  try {
    console.log('🌱 Starting database seeding...');
    
    await connectDB();

    // Clear existing data
    console.log('🗑️  Clearing existing data...');
    await Promise.all([
      User.deleteMany({}),
      Report.deleteMany({})
    ]);

    console.log('✅ Database cleared successfully');

    // Note: Sample data creation has been disabled for production use
    // To enable sample data for testing, uncomment the sections below
    
    /*
    // Create admin user
    console.log('👤 Creating admin user...');
    const adminPassword = await bcrypt.hash('admin123456', 12);
    const adminUser = await User.create({
      name: 'System Administrator',
      email: 'admin@civicwelfare.com',
      phone: '+91-9876543210',
      password: 'admin123456', // Will be hashed by pre-save middleware
      userType: 'admin',
      location: 'System',
      isActive: true,
      isVerified: true
    });

    // Create sample public users
    console.log('👥 Creating sample public users...');
    const publicUsers = await User.insertMany([
      {
        name: 'John Doe',
        email: 'john.doe@email.com',
        phone: '+91-9876543211',
        password: 'password123',
        userType: 'public',
        location: 'Mumbai, Maharashtra',
        isActive: true,
        isVerified: true
      },
      {
        name: 'Jane Smith',
        email: 'jane.smith@email.com',
        phone: '+91-9876543212',
        password: 'password123',
        userType: 'public',
        location: 'Delhi, NCR',
        isActive: true,
        isVerified: true
      },
      {
        name: 'Raj Patel',
        email: 'raj.patel@email.com',
        phone: '+91-9876543213',
        password: 'password123',
        userType: 'public',
        location: 'Ahmedabad, Gujarat',
        isActive: true,
        isVerified: true
      }
    ]);

    // Create sample officers
    console.log('👮 Creating sample officers...');
    const officers = await User.insertMany([
      {
        name: 'Officer Kumar',
        email: 'kumar.officer@civicwelfare.com',
        phone: '+91-9876543214',
        password: 'officer123',
        userType: 'officer',
        department: 'garbageCollection',
        location: 'Mumbai, Maharashtra',
        isActive: true,
        isVerified: true
      },
      {
        name: 'Officer Singh',
        email: 'singh.officer@civicwelfare.com',
        phone: '+91-9876543215',
        password: 'officer123',
        userType: 'officer',
        department: 'roadMaintenance',
        location: 'Delhi, NCR',
        isActive: true,
        isVerified: true
      },
      {
        name: 'Officer Sharma',
        email: 'sharma.officer@civicwelfare.com',
        phone: '+91-9876543216',
        password: 'officer123',
        userType: 'officer',
        department: 'waterSupply',
        location: 'Pune, Maharashtra',
        isActive: true,
        isVerified: true
      }
    ]);

    // Create sample reports
    console.log('📝 Creating sample reports...');
    const sampleReports = [
      {
        title: 'Overflowing Garbage Bin',
        description: 'The garbage bin near the bus stop is overflowing and creating unhygienic conditions.',
        category: 'Garbage Collection',
        location: 'Bus Stop, MG Road',
        address: 'MG Road, Near City Mall, Mumbai',
        latitude: 19.0760,
        longitude: 72.8777,
        priority: 'High',
        reporterId: publicUsers[0]._id,
        reporterName: publicUsers[0].name,
        reporterEmail: publicUsers[0].email,
        reporterPhone: publicUsers[0].phone,
        status: 'submitted'
      },
      {
        title: 'Pothole on Main Road',
        description: 'Large pothole causing traffic issues and vehicle damage.',
        category: 'Road Maintenance',
        location: 'Main Road, Sector 15',
        address: 'Main Road, Sector 15, Noida',
        latitude: 28.5355,
        longitude: 77.3910,
        priority: 'Medium',
        reporterId: publicUsers[1]._id,
        reporterName: publicUsers[1].name,
        reporterEmail: publicUsers[1].email,
        reporterPhone: publicUsers[1].phone,
        status: 'acknowledged',
        assignedOfficerId: officers[1]._id,
        assignedOfficerName: officers[1].name
      },
      {
        title: 'Street Light Not Working',
        description: 'Street light has been non-functional for over a week, making the area unsafe at night.',
        category: 'Street Lights',
        location: 'Park Street',
        address: 'Park Street, Near Community Center',
        latitude: 23.0225,
        longitude: 72.5714,
        priority: 'Medium',
        reporterId: publicUsers[2]._id,
        reporterName: publicUsers[2].name,
        reporterEmail: publicUsers[2].email,
        reporterPhone: publicUsers[2].phone,
        status: 'in_progress'
      },
      {
        title: 'Water Supply Disruption',
        description: 'No water supply for the past 3 days in our residential area.',
        category: 'Water Supply',
        location: 'Residential Area, Block A',
        address: 'Block A, Sunrise Apartments, Pune',
        latitude: 18.5204,
        longitude: 73.8567,
        priority: 'Critical',
        reporterId: publicUsers[0]._id,
        reporterName: publicUsers[0].name,
        reporterEmail: publicUsers[0].email,
        reporterPhone: publicUsers[0].phone,
        status: 'resolved',
        assignedOfficerId: officers[2]._id,
        assignedOfficerName: officers[2].name
      }
    ];

    await Report.insertMany(sampleReports);

    console.log('✅ Database seeded successfully!');
    console.log('\n📊 Created:');
    console.log(`   - 1 Admin user (admin@civicwelfare.com / admin123456)`);
    console.log(`   - 3 Public users (password: password123)`);
    console.log(`   - 3 Officers (password: officer123)`);
    console.log(`   - 4 Sample reports`);
    console.log('\n🔑 Admin Login:');
    console.log(`   Email: admin@civicwelfare.com`);
    console.log(`   Password: admin123456`);
    */

    console.log('✅ Database cleared - no sample data created');
    console.log('💡 To create sample data for testing, uncomment the sample data sections in this file');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
};

seedData();