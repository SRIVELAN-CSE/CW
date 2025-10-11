const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB Atlas'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Import models
const Report = require('./models/Report');

async function testReports() {
  try {
    console.log('📋 Fetching all reports...');
    const reports = await Report.find({}).limit(3);
    
    console.log(`Found ${reports.length} reports:`);
    reports.forEach((report, index) => {
      console.log(`\n${index + 1}. ${report.title}`);
      console.log(`   Status: ${report.status}`);
      console.log(`   Category: ${report.category}`);
      console.log(`   Location: ${report.location.address}, ${report.location.city}`);
      console.log(`   Submitted by: ${report.submittedByName}`);
    });
    
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error fetching reports:', error);
    process.exit(1);
  }
}

testReports();