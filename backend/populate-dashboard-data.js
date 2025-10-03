// Dashboard Data Entry Test Script
// This script will populate the database with sample data from all dashboards

require('dotenv').config();
const mongoose = require('mongoose');

// Import all models
const User = require('./models/User');
const Report = require('./models/Report');
const Certificate = require('./models/Certificate');
const RegistrationRequest = require('./models/RegistrationRequest');
const PasswordResetRequest = require('./models/PasswordResetRequest');
const NeedRequest = require('./models/NeedRequest');
const Feedback = require('./models/Feedback');
const Notification = require('./models/Notification');

async function populateDashboardData() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas');
    console.log('\n🚀 POPULATING DASHBOARD DATA...\n');

    // 1. CREATE SAMPLE REPORTS (Public Dashboard)
    console.log('📊 Creating sample reports...');
    const sampleReports = [
      {
        title: 'Garbage Collection Issue on Main Street',
        description: 'Garbage has not been collected for 3 days on Main Street, causing bad smell and health concerns.',
        category: 'Garbage Collection',
        location: 'Main Street, Downtown',
        address: '123 Main Street',
        priority: 'High',
        reporterId: '6707fce1e1ae86b3d0fe9e95', // Use existing user ID
        reporterName: 'Admin User',
        reporterEmail: 'admin@civicwelfare.com',
        reporterPhone: '+1234567890',
        imageUrls: ['https://example.com/garbage1.jpg'],
        tags: ['garbage', 'health', 'urgent']
      },
      {
        title: 'Street Light Not Working',
        description: 'The street light at Park Avenue has been flickering and is now completely out, making the area unsafe at night.',
        category: 'Street Lights',
        location: 'Park Avenue',
        address: '456 Park Avenue',
        priority: 'Medium',
        reporterId: '6707fce1e1ae86b3d0fe9e95',
        reporterName: 'Admin User',
        reporterEmail: 'admin@civicwelfare.com',
        reporterPhone: '+1234567890',
        tags: ['streetlight', 'safety', 'park']
      },
      {
        title: 'Road Pothole Causing Accidents',
        description: 'Large pothole on Elm Street is causing damage to vehicles and poses a safety risk.',
        category: 'Road Maintenance',
        location: 'Elm Street',
        address: '789 Elm Street',
        priority: 'Critical',
        reporterId: '6707fce1e1ae86b3d0fe9e95',
        reporterName: 'Admin User',
        reporterEmail: 'admin@civicwelfare.com',
        reporterPhone: '+1234567890',
        tags: ['pothole', 'safety', 'road']
      },
      {
        title: 'Water Supply Disruption',
        description: 'Water supply has been interrupted in Oak District for 2 days. Residents need urgent water supply.',
        category: 'Water Supply',
        location: 'Oak District',
        address: 'Oak District, Sector 5',
        priority: 'Critical',
        reporterId: '6707fce1e1ae86b3d0fe9e95',
        reporterName: 'Admin User',
        reporterEmail: 'admin@civicwelfare.com',
        reporterPhone: '+1234567890',
        tags: ['water', 'emergency', 'district']
      }
    ];

    for (const reportData of sampleReports) {
      await Report.create(reportData);
    }
    console.log('✅ Created 4 sample reports');

    // 2. CREATE SAMPLE CERTIFICATES (Public Dashboard)
    console.log('📜 Creating sample certificate applications...');
    const sampleCertificates = [
      {
        certificateType: 'Birth Certificate',
        applicantId: '6707fce1e1ae86b3d0fe9e95',
        applicantName: 'Admin User',
        applicantEmail: 'admin@civicwelfare.com',
        applicantPhone: '+1234567890',
        applicationDetails: {
          fullName: 'John Doe',
          dateOfBirth: new Date('1990-05-15'),
          gender: 'Male',
          fatherName: 'Robert Doe',
          motherName: 'Jane Doe',
          address: '123 Birth Street, City',
          pincode: '12345',
          purpose: 'Passport application'
        },
        applicationNumber: 'BC' + Date.now(),
        priority: 'Normal',
        expectedDeliveryDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      },
      {
        certificateType: 'Income Certificate',
        applicantId: '6707fce1e1ae86b3d0fe9e95',
        applicantName: 'Admin User',
        applicantEmail: 'admin@civicwelfare.com',
        applicantPhone: '+1234567890',
        applicationDetails: {
          fullName: 'Mary Smith',
          address: '456 Income Avenue, City',
          pincode: '54321',
          purpose: 'Education scholarship'
        },
        applicationNumber: 'IC' + Date.now(),
        priority: 'Urgent',
        expectedDeliveryDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000)
      }
    ];

    for (const certData of sampleCertificates) {
      await Certificate.create(certData);
    }
    console.log('✅ Created 2 sample certificate applications');

    // 3. CREATE SAMPLE REGISTRATION REQUESTS (Admin Dashboard)
    console.log('📝 Creating sample registration requests...');
    const sampleRegistrations = [
      {
        name: 'Officer Jane Smith',
        email: 'jane.smith@city.gov',
        phone: '+1987654321',
        userType: 'officer',
        department: 'garbageCollection',
        location: 'Downtown District',
        reason: 'New officer joining the garbage collection department',
        status: 'pending'
      },
      {
        name: 'Officer Mike Johnson',
        email: 'mike.johnson@city.gov',
        phone: '+1456789123',
        userType: 'officer',
        department: 'roadMaintenance',
        location: 'North District',
        reason: 'Experienced road maintenance officer transfer',
        status: 'pending'
      }
    ];

    for (const regData of sampleRegistrations) {
      await RegistrationRequest.create(regData);
    }
    console.log('✅ Created 2 sample registration requests');

    // 4. CREATE SAMPLE PASSWORD RESET REQUESTS (Admin Dashboard)
    console.log('🔐 Creating sample password reset requests...');
    const samplePasswordResets = [
      {
        email: 'john.doe@example.com',
        userType: 'public',
        reason: 'Forgot password, unable to access account',
        status: 'pending'
      },
      {
        email: 'sarah.wilson@example.com',
        userType: 'officer',
        reason: 'Compromised account, requesting admin password reset',
        status: 'approved',
        reviewedBy: '6707fce1e1ae86b3d0fe9e95',
        reviewedByName: 'Admin User',
        reviewedAt: new Date(),
        reviewNotes: 'Password reset approved. New temporary password generated.'
      }
    ];

    for (const resetData of samplePasswordResets) {
      await PasswordResetRequest.create(resetData);
    }
    console.log('✅ Created 2 sample password reset requests');

    // 5. CREATE SAMPLE NEED REQUESTS (Public Dashboard)
    console.log('🤲 Creating sample need requests...');
    const sampleNeedRequests = [
      {
        title: 'Medical Emergency Transport',
        description: 'Elderly residents in rural area need regular medical transport to city hospital',
        category: 'Medical Assistance',
        location: 'Rural District',
        urgencyLevel: 'High',
        requesterId: '6707fce1e1ae86b3d0fe9e95',
        requesterName: 'Admin User',
        requesterEmail: 'admin@civicwelfare.com',
        requesterPhone: '+1234567890',
        estimatedCost: 50000,
        beneficiaryCount: 150
      },
      {
        title: 'School Infrastructure Improvement',
        description: 'Local school needs new desks, chairs, and basic infrastructure improvements',
        category: 'Educational Support',
        location: 'School District',
        urgencyLevel: 'Medium',
        requesterId: '6707fce1e1ae86b3d0fe9e95',
        requesterName: 'Admin User',
        requesterEmail: 'admin@civicwelfare.com',
        requesterPhone: '+1234567890',
        estimatedCost: 100000,
        beneficiaryCount: 300
      }
    ];

    for (const needData of sampleNeedRequests) {
      await NeedRequest.create(needData);
    }
    console.log('✅ Created 2 sample need requests');

    // 6. CREATE SAMPLE FEEDBACK (Public Dashboard)
    console.log('💬 Creating sample feedback...');
    const sampleFeedback = [
      {
        type: 'service_feedback',
        title: 'Excellent Garbage Collection Service',
        message: 'The garbage collection in our area has improved significantly. Very satisfied with the service.',
        rating: 5,
        userId: '6707fce1e1ae86b3d0fe9e95',
        userName: 'Admin User',
        userEmail: 'admin@civicwelfare.com'
      },
      {
        type: 'app_feedback',
        title: 'App Suggestion',
        message: 'The app is good but could use a dark mode feature for better user experience.',
        rating: 4,
        userId: '6707fce1e1ae86b3d0fe9e95',
        userName: 'Admin User',
        userEmail: 'admin@civicwelfare.com'
      },
      {
        type: 'complaint',
        title: 'Road Maintenance Complaint',
        message: 'Roads in our area are in bad condition. More frequent maintenance required.',
        userId: '6707fce1e1ae86b3d0fe9e95',
        userName: 'Admin User',
        userEmail: 'admin@civicwelfare.com'
      }
    ];

    for (const feedbackData of sampleFeedback) {
      await Feedback.create(feedbackData);
    }
    console.log('✅ Created 3 sample feedback entries');

    // 7. CREATE SAMPLE NOTIFICATIONS
    console.log('🔔 Creating sample notifications...');
    const sampleNotifications = [
      {
        title: 'Report Status Updated',
        message: 'Your garbage collection report has been assigned to an officer',
        type: 'report_update',
        userId: '6707fce1e1ae86b3d0fe9e95',
        priority: 'medium',
        relatedModel: 'Report'
      },
      {
        title: 'Certificate Application Approved',
        message: 'Your birth certificate application has been approved and is ready for collection',
        type: 'system_alert',
        userId: '6707fce1e1ae86b3d0fe9e95',
        priority: 'high',
        relatedModel: 'Certificate'
      },
      {
        title: 'System Maintenance Notice',
        message: 'Maintenance scheduled for this weekend. Some services may be temporarily unavailable.',
        type: 'announcement',
        userId: '6707fce1e1ae86b3d0fe9e95',
        priority: 'medium'
      }
    ];

    for (const notificationData of sampleNotifications) {
      await Notification.create(notificationData);
    }
    console.log('✅ Created 3 sample notifications');

    console.log('\n🎉 DASHBOARD DATA POPULATION COMPLETED!');
    console.log('\n📊 SUMMARY OF CREATED DATA:');
    console.log('   📊 Reports: 4 new entries');
    console.log('   📜 Certificates: 2 new applications');
    console.log('   📝 Registration Requests: 2 new requests');
    console.log('   🔐 Password Resets: 2 new requests');
    console.log('   🤲 Need Requests: 2 new requests');
    console.log('   💬 Feedback: 3 new entries');
    console.log('   🔔 Notifications: 3 new notifications');

    console.log('\n✅ All dashboard data has been populated successfully!');
    console.log('📱 You can now test all dashboard functionalities with this sample data.');

  } catch (error) {
    console.error('❌ Data population failed:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

// Run the data population
populateDashboardData();