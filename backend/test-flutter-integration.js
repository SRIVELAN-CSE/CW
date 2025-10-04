// Test Officer Registration
// This script tests the officer registration functionality

const axios = require('axios');

const API_BASE_URL = 'https://civic-welfare-backend.onrender.com/api';

async function testOfficerRegistration() {
  console.log('🧪 Testing Officer Registration...\n');
  
  const testData = {
    name: 'Test Officer Flutter',
    email: `flutter-test-officer-${Date.now()}@example.com`,
    phone: '+1234567890',
    password: 'password123',
    userType: 'officer',
    department: 'garbageCollection',
    location: 'Flutter Test District',
    reason: 'Testing Flutter registration functionality'
  };

  console.log('📋 Test Data:');
  console.log(JSON.stringify(testData, null, 2));

  try {
    console.log('\n📡 Sending registration request...');
    const response = await axios.post(`${API_BASE_URL}/auth/register`, testData, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('\n✅ Registration Response:');
    console.log('Status:', response.status);
    console.log('Data:', JSON.stringify(response.data, null, 2));
    
    if (response.data.success) {
      console.log('\n🎉 Officer registration successful!');
      console.log(`📝 Request ID: ${response.data.data.requestId}`);
      console.log(`📊 Status: ${response.data.data.status}`);
    }

  } catch (error) {
    console.log('\n❌ Registration failed:');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Error:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.log('Error:', error.message);
    }
  }
}

async function testReportsEndpoint() {
  console.log('\n\n🧪 Testing Reports Endpoint...\n');
  
  try {
    console.log('📡 Testing original reports endpoint...');
    const originalResponse = await axios.get(`${API_BASE_URL}/reports`);
    console.log('✅ Original endpoint response type:', typeof originalResponse.data);
    console.log('✅ Original endpoint structure:', Object.keys(originalResponse.data));
    
    console.log('\n📡 Testing simple reports endpoint...');
    const simpleResponse = await axios.get(`${API_BASE_URL}/reports/simple`);
    console.log('✅ Simple endpoint response type:', typeof simpleResponse.data);
    console.log('✅ Simple endpoint is array:', Array.isArray(simpleResponse.data));
    console.log('✅ Simple endpoint reports count:', simpleResponse.data.length);

  } catch (error) {
    console.log('❌ Reports test failed:', error.message);
  }
}

// Run tests
async function runTests() {
  await testOfficerRegistration();
  await testReportsEndpoint();
  
  console.log('\n📋 Summary:');
  console.log('1. Test officer registration to verify database storage');
  console.log('2. Test reports endpoint compatibility with Flutter');
  console.log('\n🔧 If registration fails, check the validation and database connection');
  console.log('🔧 If reports fail, use /api/reports/simple endpoint in Flutter');
}

runTests();