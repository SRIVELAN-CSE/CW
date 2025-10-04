// Test All Public Dashboard Endpoints
// This script tests all the public endpoints to ensure data is stored in MongoDB Atlas

const https = require('https');

const BASE_URL = 'https://civic-welfare-backend.onrender.com/api';

// Test data
const testReport = {
  title: 'Test Public Report - Dashboard Data Storage',
  description: 'Testing if public reports are stored in MongoDB Atlas via Render server',
  category: 'Others',
  location: 'Test Location',
  address: 'Test Address',
  priority: 'Medium',
  reporter_name: 'Test User',
  reporter_email: 'test@example.com',
  reporter_phone: '+1234567890'
};

const testCertificate = {
  certificateType: 'Birth Certificate',
  applicantName: 'Test Applicant',
  applicantEmail: 'applicant@example.com',
  applicantPhone: '+1234567890',
  applicationDetails: {
    fullName: 'Test Full Name',
    dateOfBirth: '1990-01-01',
    purpose: 'Testing dashboard data storage'
  },
  priority: 'Normal'
};

const testNeedRequest = {
  title: 'Test Public Need Request',
  description: 'Testing if need requests are stored in MongoDB Atlas',
  category: 'Medical Assistance',
  location: 'Test Community',
  urgencyLevel: 'Medium',
  beneficiaryCount: 10,
  estimatedCost: 5000,
  requesterName: 'Test Requester',
  requesterEmail: 'requester@example.com',
  requesterPhone: '+1234567890'
};

const testFeedback = {
  type: 'service_feedback',
  title: 'Test Public Feedback',
  message: 'Testing if feedback is stored in MongoDB Atlas via public endpoints',
  rating: 5,
  category: 'Service Quality',
  userName: 'Test User',
  userEmail: 'feedback@example.com',
  isAnonymous: false
};

function makeRequest(endpoint, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);
    
    const options = {
      hostname: 'civic-welfare-backend.onrender.com',
      port: 443,
      path: `/api/${endpoint}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, data: responseData });
        }
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    req.write(postData);
    req.end();
  });
}

async function testEndpoint(name, endpoint, testData) {
  console.log(`\n🧪 Testing ${name}...`);
  console.log(`📡 Endpoint: ${endpoint}`);
  
  try {
    const response = await makeRequest(endpoint, testData);
    
    if (response.status === 201) {
      console.log(`✅ ${name} SUCCESS!`);
      console.log(`📊 Response:`, response.data);
      return true;
    } else {
      console.log(`❌ ${name} FAILED with status ${response.status}`);
      console.log(`📊 Response:`, response.data);
      return false;
    }
  } catch (error) {
    console.log(`❌ ${name} ERROR:`, error.message);
    return false;
  }
}

async function runAllTests() {
  console.log('🚀 TESTING ALL PUBLIC DASHBOARD ENDPOINTS');
  console.log('=' .repeat(60));
  console.log('📡 Backend: https://civic-welfare-backend.onrender.com');
  console.log('🗄️ Database: MongoDB Atlas (civic_welfare)');
  console.log('🎯 Goal: Verify all dashboard data is stored live');

  const results = {};
  
  // Test all endpoints
  results.reports = await testEndpoint('Reports Creation', 'reports/public', testReport);
  results.certificates = await testEndpoint('Certificate Applications', 'certificates/public', testCertificate);
  results.needRequests = await testEndpoint('Need Requests', 'need-requests/public', testNeedRequest);
  results.feedback = await testEndpoint('Feedback Submission', 'feedback/public', testFeedback);

  console.log('\n📊 TEST RESULTS SUMMARY');
  console.log('=' .repeat(40));
  console.log(`📊 Reports Creation: ${results.reports ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`📜 Certificate Applications: ${results.certificates ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`🤲 Need Requests: ${results.needRequests ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`💬 Feedback Submission: ${results.feedback ? '✅ PASS' : '❌ FAIL'}`);

  const totalTests = Object.keys(results).length;
  const passedTests = Object.values(results).filter(Boolean).length;
  
  console.log('\n🎯 OVERALL RESULTS');
  console.log('=' .repeat(30));
  console.log(`📈 Passed: ${passedTests}/${totalTests}`);
  console.log(`📊 Success Rate: ${Math.round((passedTests/totalTests) * 100)}%`);
  
  if (passedTests === totalTests) {
    console.log('\n🎉 ALL TESTS PASSED!');
    console.log('✅ All dashboard data is now being stored in MongoDB Atlas');
    console.log('🚀 Your Flutter app can now successfully save live data');
  } else {
    console.log('\n⚠️ SOME TESTS FAILED');
    console.log('🔍 Check the error messages above for debugging');
  }

  console.log('\n📱 NEXT STEPS:');
  console.log('1. Update your Flutter app to use the public endpoints');
  console.log('2. Test dashboard submissions from the Flutter app');
  console.log('3. Verify data appears in MongoDB Atlas database');
  console.log('4. Use inspect-database.js to monitor stored data');
}

// Run all tests
runAllTests();