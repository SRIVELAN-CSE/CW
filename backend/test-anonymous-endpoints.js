// Test Anonymous Data Submission
// This script tests the new anonymous endpoints

const https = require('https');

function testAnonymousReport() {
  return new Promise((resolve) => {
    const testReport = {
      title: "Live Test Anonymous Report " + Date.now(),
      description: "Testing anonymous report submission to MongoDB Atlas",
      category: "Others",
      location: "Test Location",
      address: "Test Address",
      priority: "Medium",
      reporterName: "Anonymous Tester",
      reporterEmail: "test@anonymous.com",
      reporterPhone: "+1234567890",
      imageUrls: [],
      tags: ["test", "anonymous"]
    };

    const postData = JSON.stringify(testReport);
    
    const options = {
      hostname: 'civic-welfare-backend.onrender.com',
      port: 443,
      path: '/api/reports/anonymous',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', chunk => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          console.log('📊 Anonymous Report Test:');
          console.log(`   Status: ${res.statusCode}`);
          console.log(`   Success: ${res.statusCode === 201 ? '✅' : '❌'}`);
          if (result.data) {
            console.log(`   Report ID: ${result.data.reportId}`);
            console.log(`   Tracking: ${result.data.trackingNumber}`);
          }
          resolve(res.statusCode === 201);
        } catch (e) {
          console.log('❌ Failed to parse response:', e.message);
          resolve(false);
        }
      });
    });

    req.on('error', (e) => {
      console.log('❌ Request failed:', e.message);
      resolve(false);
    });

    req.write(postData);
    req.end();
  });
}

function testAnonymousCertificate() {
  return new Promise((resolve) => {
    const testCertificate = {
      certificateType: "Birth Certificate",
      applicantName: "Anonymous Applicant",
      applicantEmail: "cert@anonymous.com",
      applicantPhone: "+1234567890",
      applicationDetails: {
        fullName: "Test Person",
        dateOfBirth: "1990-01-01",
        gender: "Other",
        fatherName: "Test Father",
        motherName: "Test Mother",
        address: "Test Address",
        pincode: "12345",
        purpose: "Testing"
      },
      priority: "Normal"
    };

    const postData = JSON.stringify(testCertificate);
    
    const options = {
      hostname: 'civic-welfare-backend.onrender.com',
      port: 443,
      path: '/api/certificates/anonymous',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', chunk => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          console.log('📜 Anonymous Certificate Test:');
          console.log(`   Status: ${res.statusCode}`);
          console.log(`   Success: ${res.statusCode === 201 ? '✅' : '❌'}`);
          if (result.data) {
            console.log(`   Application ID: ${result.data.applicationId}`);
            console.log(`   Application Number: ${result.data.applicationNumber}`);
          }
          resolve(res.statusCode === 201);
        } catch (e) {
          console.log('❌ Failed to parse response:', e.message);
          resolve(false);
        }
      });
    });

    req.on('error', (e) => {
      console.log('❌ Request failed:', e.message);
      resolve(false);
    });

    req.write(postData);
    req.end();
  });
}

async function runAnonymousTests() {
  console.log('🧪 TESTING ANONYMOUS DATA SUBMISSION');
  console.log('=' .repeat(50));
  
  // Wait for deployment
  console.log('⏱️ Waiting 30 seconds for Render deployment...');
  await new Promise(resolve => setTimeout(resolve, 30000));
  
  console.log('\n🔍 Testing anonymous endpoints...');
  
  const reportSuccess = await testAnonymousReport();
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  const certSuccess = await testAnonymousCertificate();
  
  console.log('\n📊 ANONYMOUS SUBMISSION TEST RESULTS:');
  console.log('=' .repeat(40));
  console.log(`📊 Anonymous Reports: ${reportSuccess ? '✅ WORKING' : '❌ FAILED'}`);
  console.log(`📜 Anonymous Certificates: ${certSuccess ? '✅ WORKING' : '❌ FAILED'}`);
  
  if (reportSuccess && certSuccess) {
    console.log('\n🎉 SUCCESS! Anonymous data submission is working!');
    console.log('✅ Your Flutter app can now store data in MongoDB Atlas');
    console.log('🚀 Ready for dashboard testing without authentication');
  } else {
    console.log('\n⚠️ Some endpoints are still not working');
    console.log('🔄 Deployment may still be in progress');
  }
}

runAnonymousTests();