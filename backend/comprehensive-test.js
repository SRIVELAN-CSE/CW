// Comprehensive API endpoint testing
const axios = require('axios');

const baseURL = 'http://localhost:3000/api';
const testResults = [];

// Test result tracking
const logResult = (endpoint, success, message, data = null) => {
  const result = { endpoint, success, message, data, timestamp: new Date() };
  testResults.push(result);
  console.log(`${success ? '✅' : '❌'} ${endpoint}: ${message}`);
  if (data) console.log(`   Data:`, JSON.stringify(data, null, 2));
};

// Test 1: Health Check
const testHealthCheck = async () => {
  try {
    const response = await axios.get(`${baseURL}/health`);
    logResult('GET /health', true, 'Health check passed', {
      status: response.data.status,
      database: response.data.database,
      uptime: response.data.uptime
    });
    return true;
  } catch (error) {
    logResult('GET /health', false, `Health check failed: ${error.message}`);
    return false;
  }
};

// Test 2: User Registration
const testRegistration = async () => {
  try {
    const userData = {
      name: 'Test API User',
      email: `test-${Date.now()}@example.com`,
      phone: '1234567890',
      password: 'testpass123',
      confirmPassword: 'testpass123',
      userType: 'public',
      location: 'Test City'
    };

    const response = await axios.post(`${baseURL}/auth/register`, userData);
    logResult('POST /auth/register', true, 'Registration successful', {
      userId: response.data.data?.user?.id,
      email: response.data.data?.user?.email,
      userType: response.data.data?.user?.userType
    });
    return response.data;
  } catch (error) {
    const errorMsg = error.response?.data?.message || error.message;
    logResult('POST /auth/register', false, `Registration failed: ${errorMsg}`);
    return null;
  }
};

// Test 3: User Login
const testLogin = async (email, password) => {
  try {
    const loginData = { email, password };
    const response = await axios.post(`${baseURL}/auth/login`, loginData);
    
    logResult('POST /auth/login', true, 'Login successful', {
      userId: response.data.data?.user?.id,
      email: response.data.data?.user?.email,
      hasToken: !!response.data.data?.access_token
    });
    return response.data;
  } catch (error) {
    const errorMsg = error.response?.data?.message || error.message;
    logResult('POST /auth/login', false, `Login failed: ${errorMsg}`);
    return null;
  }
};

// Test 4: Create Report
const testCreateReport = async (token) => {
  try {
    const reportData = {
      title: 'Test API Report',
      description: 'This is a test report created via API',
      category: 'public-safety',
      location: 'Test Location',
      address: '123 Test Street, Test City',
      latitude: 12.9716,
      longitude: 77.5946,
      priority: 'high',
      reporterName: 'API Test User',
      reporterEmail: 'apitest@example.com',
      reporterPhone: '1234567890'
    };

    const response = await axios.post(`${baseURL}/reports`, reportData, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    logResult('POST /reports', true, 'Report created successfully', {
      reportId: response.data.data?.id,
      title: response.data.data?.title,
      category: response.data.data?.category
    });
    return response.data;
  } catch (error) {
    const errorMsg = error.response?.data?.message || error.message;
    logResult('POST /reports', false, `Report creation failed: ${errorMsg}`);
    return null;
  }
};

// Test 5: Get Reports
const testGetReports = async (token) => {
  try {
    const response = await axios.get(`${baseURL}/reports`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    logResult('GET /reports', true, 'Reports fetched successfully', {
      totalReports: response.data.data?.length || 0,
      firstReportTitle: response.data.data?.[0]?.title || 'No reports'
    });
    return response.data;
  } catch (error) {
    const errorMsg = error.response?.data?.message || error.message;
    logResult('GET /reports', false, `Failed to fetch reports: ${errorMsg}`);
    return null;
  }
};

// Main test runner
const runAllTests = async () => {
  console.log('🚀 Starting comprehensive API testing...\n');
  
  // Step 1: Health Check
  console.log('1️⃣ Testing Health Check...');
  const healthOk = await testHealthCheck();
  
  if (!healthOk) {
    console.log('❌ Health check failed. Stopping tests.');
    return;
  }

  // Step 2: Registration
  console.log('\n2️⃣ Testing User Registration...');
  const registrationResult = await testRegistration();
  
  if (!registrationResult) {
    console.log('❌ Registration failed. Stopping tests.');
    return;
  }

  // Step 3: Login
  console.log('\n3️⃣ Testing User Login...');
  const loginResult = await testLogin(
    registrationResult.data.user.email,
    'testpass123'
  );

  if (!loginResult) {
    console.log('❌ Login failed. Stopping tests.');
    return;
  }

  const token = loginResult.data.access_token;

  // Step 4: Create Report
  console.log('\n4️⃣ Testing Report Creation...');
  await testCreateReport(token);

  // Step 5: Get Reports
  console.log('\n5️⃣ Testing Report Retrieval...');
  await testGetReports(token);

  // Summary
  console.log('\n📊 TEST SUMMARY:');
  console.log('================');
  const passed = testResults.filter(r => r.success).length;
  const total = testResults.length;
  console.log(`✅ Passed: ${passed}/${total}`);
  console.log(`❌ Failed: ${total - passed}/${total}`);
  
  if (passed === total) {
    console.log('\n🎉 ALL TESTS PASSED! Backend is fully functional!');
  } else {
    console.log('\n⚠️  Some tests failed. Check the details above.');
  }

  // Show failed tests
  const failedTests = testResults.filter(r => !r.success);
  if (failedTests.length > 0) {
    console.log('\n❌ Failed Tests:');
    failedTests.forEach(test => {
      console.log(`   ${test.endpoint}: ${test.message}`);
    });
  }
};

// Wait a moment for server to start, then run tests
setTimeout(() => {
  runAllTests().catch(console.error);
}, 2000);