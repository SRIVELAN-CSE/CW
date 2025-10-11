const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB Atlas'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Import models
const Report = require('./models/Report');

// Create a dummy user ID for reports
const dummyUserId = new mongoose.Types.ObjectId();

const demoReports = [
  {
    title: "Pothole on Highway causing accidents",
    description: "Large pothole on NH-44 causing vehicle damage and potential accidents. Multiple complaints from commuters.",
    category: "road_maintenance", 
    priority: "critical",
    location: {
      address: "NH-44, Outer Ring Road",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560037",
      coordinates: {
        latitude: 12.9800,
        longitude: 77.6100
      }
    },
    status: "in_progress",
    submittedBy: dummyUserId,
    submittedByName: "Priya Sharma", 
    submittedByEmail: "priya.sharma@email.com",
    submittedByPhone: "+91-9876543211",
    isAnonymous: false
  },
  {
    title: "Water supply disruption in sector 7",
    description: "No water supply for the past 2 days in Sector 7. Affecting over 200 families.",
    category: "water_supply",
    priority: "high", 
    location: {
      address: "Sector 7, Residential Area",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560100",
      coordinates: {
        latitude: 12.9600,
        longitude: 77.5800
      }
    },
    status: "acknowledged",
    submittedBy: dummyUserId,
    submittedByName: "Anonymous Citizen",
    submittedByEmail: "anonymous@email.com",
    submittedByPhone: "+91-0000000000",
    isAnonymous: true
  },
  {
    title: "Garbage not collected for a week",
    description: "Garbage collection has been missed in our locality for over a week. Creating health and hygiene issues.",
    category: "garbage_collection",
    priority: "medium",
    location: {
      address: "JP Nagar, 2nd Phase",
      city: "Bangalore", 
      state: "Karnataka",
      pincode: "560078",
      coordinates: {
        latitude: 12.9900,
        longitude: 77.6200
      }
    },
    status: "in_progress",
    submittedBy: dummyUserId,
    submittedByName: "Anjali Reddy",
    submittedByEmail: "anjali.reddy@email.com",
    submittedByPhone: "+91-9876543213",
    isAnonymous: false
  },
  {
    title: "Street light not working in residential area",
    description: "Street light has been non-functional for 2 weeks, creating safety concerns for evening commuters.",
    category: "street_lights",
    priority: "high",
    location: {
      address: "JP Nagar 7th Phase",
      city: "Bangalore",
      state: "Karnataka", 
      pincode: "560078",
      coordinates: {
        latitude: 12.9750,
        longitude: 77.6050
      }
    },
    status: "submitted", 
    submittedBy: dummyUserId,
    submittedByName: "Anonymous User",
    submittedByEmail: "anonymous@example.com",
    submittedByPhone: "+91-0000000000",
    isAnonymous: true
  },
  {
    title: "Traffic signal not working at junction",
    description: "Traffic signal at the busy junction has been malfunctioning since yesterday morning. Causing traffic jams.",
    category: "traffic_management",
    priority: "high",
    location: {
      address: "Commercial Street Junction",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560001",
      coordinates: {
        latitude: 12.9700,
        longitude: 77.5900
      }
    },
    status: "resolved",
    submittedBy: dummyUserId,
    submittedByName: "Vikram Singh",
    submittedByEmail: "vikram.singh@email.com",
    submittedByPhone: "+91-9876543214",
    isAnonymous: false
  },
  {
    title: "Drainage system clogged causing waterlogging",
    description: "Heavy rains have caused severe waterlogging due to clogged drainage in residential area. Water entering homes.",
    category: "drainage",
    priority: "critical",
    location: {
      address: "Koramangala 5th Block",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560034",
      coordinates: {
        latitude: 12.9352,
        longitude: 77.6245
      }
    },
    status: "submitted",
    submittedBy: dummyUserId,
    submittedByName: "Rajesh Kumar",
    submittedByEmail: "rajesh.kumar@email.com",
    submittedByPhone: "+91-9876543215",
    isAnonymous: false
  }
];

async function createDemoData() {
  try {
    console.log('🗑️ Clearing existing demo reports...');
    await Report.deleteMany({ 
      title: { 
        $in: demoReports.map(r => r.title) 
      } 
    });
    
    console.log('📊 Creating demo reports...');
    const createdReports = await Report.insertMany(demoReports);
    
    console.log(`✅ Created ${createdReports.length} demo reports:`);
    createdReports.forEach((report, index) => {
      console.log(`${index + 1}. ${report.title} (${report.status})`);
    });
    
    console.log('\n🎯 Demo data ready for testing!');
    console.log('🔗 Test your endpoints:');
    console.log('   • Local: http://localhost:8000/api/reports');
    console.log('   • Cloud: https://civic-welfare-backend.onrender.com/api/reports');
    
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error creating demo data:', error);
    process.exit(1);
  }
}

createDemoData();