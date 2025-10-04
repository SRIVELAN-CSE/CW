// Test Data Submission to Production Backend
// This script tests if data submission endpoints are working

const https = require('https');

// Test data for different endpoints
const testData = {
  report: {
    title: "Test Report from Flutter Fix",
    description: "Testing if report submission works correctly",
    category: "Others", 
    location: "Test Location",
    address: "Test Address",
    priority: "Medium",
    reporterName: "Test User",
    reporterEmail: "test@example.com",
    reporterPhone: "+1234567890"
  },
  registration: {
    name: "Test Officer Registration",
    email: "testofficer" + Date.now() + "@test.com", 
    password: "testpassword123",
    phone: "+1234567890",
    location: "Test City",
    userType: "officer",
    department: "garbageCollection"
  }
};

function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'civic-welfare-backend.onrender.com',
      port: 443,
      path: `/api${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', chunk => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          resolve({
            status: res.statusCode,
            data: parsed,
            success: res.statusCode >= 200 && res.statusCode < 300
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            data: responseData,
            success: false,
            error: 'Failed to parse JSON'
          });
        }
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

async function testReportSubmission() {
  console.log('\n📊 Testing Report Submission...');
  try {
    const result = await makeRequest('POST', '/reports', testData.report);
    console.log(`Status: ${result.status}`);
    
    if (result.success) {
      console.log('✅ Report submission successful!');
      console.log('📋 Response:', result.data);
      return result.data;
    } else {
      console.log('❌ Report submission failed');
      console.log('📋 Response:', result.data);
      return null;
    }
  } catch (error) {
    console.log('❌ Report submission error:', error.message);
    return null;
  }
}

async function testRegistration() {
  console.log('\n👤 Testing Registration...');
  try {
    const result = await makeRequest('POST', '/auth/register', testData.registration);
    console.log(`Status: ${result.status}`);
    
    if (result.success) {
      console.log('✅ Registration successful!');
      console.log('📋 Response:', result.data);
      return result.data;
    } else {
      console.log('❌ Registration failed');
      console.log('📋 Response:', result.data);
      return null;
    }
  } catch (error) {
    console.log('❌ Registration error:', error.message);
    return null;
  }
}

async function testDataRetrieval() {
  console.log('\n📥 Testing Data Retrieval...');
  try {
    const result = await makeRequest('GET', '/reports/simple');
    console.log(`Status: ${result.status}`);
    
    if (result.success && Array.isArray(result.data)) {
      console.log('✅ Data retrieval successful!');
      console.log(`📊 Total reports: ${result.data.length}`);
      
      // Check if our test report exists
      const testReport = result.data.find(r => r.title === testData.report.title);
      if (testReport) {
        console.log('✅ Test report found in database!');
        return true;
      } else {
        console.log('⚠️ Test report not found in database');
        return false;
      }
    } else {
      console.log('❌ Data retrieval failed');
      return false;
    }
  } catch (error) {
    console.log('❌ Data retrieval error:', error.message);
    return false;
  }
}

async function runDataSubmissionTests() {
  console.log('🧪 TESTING DATA SUBMISSION TO PRODUCTION BACKEND');
  console.log('=' .repeat(60));
  
  // Test report submission
  const reportResult = await testReportSubmission();
  
  // Test registration
  const registrationResult = await testRegistration();
  
  // Wait a moment for data to be processed
  console.log('\n⏱️ Waiting 3 seconds for data processing...');
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  // Test if data appears in retrieval
  const retrievalResult = await testDataRetrieval();
  
  console.log('\n📊 TEST SUMMARY:');
  console.log('=' .repeat(40));
  console.log(`📊 Report Submission: ${reportResult ? '✅ SUCCESS' : '❌ FAILED'}`);
  console.log(`👤 Registration: ${registrationResult ? '✅ SUCCESS' : '❌ FAILED'}`);
  console.log(`📥 Data Retrieval: ${retrievalResult ? '✅ SUCCESS' : '❌ FAILED'}`);
  
  if (reportResult && registrationResult && retrievalResult) {
    console.log('\n🎉 ALL TESTS PASSED! Data submission is working correctly.');
  } else {
    console.log('\n⚠️ SOME TESTS FAILED! There may be issues with data submission.');
    console.log('\n🔍 Troubleshooting steps:');
    console.log('1. Check backend logs for errors');
    console.log('2. Verify database connection');
    console.log('3. Check validation rules');
    console.log('4. Test with Postman/curl');
  }
}

runDataSubmissionTests();