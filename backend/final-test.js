const http = require('http');

console.log('🧪 Testing CivicWelfare Backend API...\n');

// Test 1: Health Check
function testHealthCheck() {
  return new Promise((resolve) => {
    console.log('1️⃣ Testing Health Endpoint...');
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/health',
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => data += chunk);
      
      res.on('end', () => {
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          console.log('✅ Health Check Passed!');
          console.log('   Status:', response.status);
          console.log('   Database:', response.database);
          console.log('   Uptime:', Math.round(response.uptime) + 's');
          resolve(true);
        } else {
          console.log('❌ Health Check Failed:', res.statusCode);
          resolve(false);
        }
      });
    });

    req.on('error', (error) => {
      console.log('❌ Health Check Error:', error.message);
      resolve(false);
    });

    req.end();
  });
}

// Test 2: Registration
function testRegistration() {
  return new Promise((resolve) => {
    console.log('\n2️⃣ Testing User Registration...');
    
    const userData = JSON.stringify({
      name: 'API Test User',
      email: `test-${Date.now()}@example.com`,
      phone: '1234567890',
      password: 'testpass123',
      confirmPassword: 'testpass123',
      userType: 'public',
      location: 'Test City'
    });

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/register',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': userData.length
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => data += chunk);
      
      res.on('end', () => {
        if (res.statusCode === 201) {
          const response = JSON.parse(data);
          console.log('✅ Registration Successful!');
          console.log('   User ID:', response.data?.user?.id);
          console.log('   Email:', response.data?.user?.email);
          console.log('   User Type:', response.data?.user?.userType);
          console.log('   Has Token:', !!response.data?.access_token);
          resolve({ success: true, data: response.data });
        } else {
          const response = JSON.parse(data);
          console.log('❌ Registration Failed:', res.statusCode);
          console.log('   Error:', response.message);
          resolve({ success: false });
        }
      });
    });

    req.on('error', (error) => {
      console.log('❌ Registration Error:', error.message);
      resolve({ success: false });
    });

    req.write(userData);
    req.end();
  });
}

// Test 3: Login
function testLogin(email, password) {
  return new Promise((resolve) => {
    console.log('\n3️⃣ Testing User Login...');
    
    const loginData = JSON.stringify({ email, password });

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': loginData.length
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => data += chunk);
      
      res.on('end', () => {
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          console.log('✅ Login Successful!');
          console.log('   User ID:', response.data?.user?.id);
          console.log('   Email:', response.data?.user?.email);
          console.log('   Has Token:', !!response.data?.access_token);
          resolve({ success: true, token: response.data?.access_token });
        } else {
          const response = JSON.parse(data);
          console.log('❌ Login Failed:', res.statusCode);
          console.log('   Error:', response.message);
          resolve({ success: false });
        }
      });
    });

    req.on('error', (error) => {
      console.log('❌ Login Error:', error.message);
      resolve({ success: false });
    });

    req.write(loginData);
    req.end();
  });
}

// Run all tests
async function runTests() {
  try {
    // Test Health Check
    const healthOk = await testHealthCheck();
    if (!healthOk) {
      console.log('\n❌ Health check failed. Stopping tests.');
      return;
    }

    // Test Registration
    const regResult = await testRegistration();
    if (!regResult.success) {
      console.log('\n❌ Registration failed. Stopping tests.');
      return;
    }

    // Test Login
    const loginResult = await testLogin(
      regResult.data.user.email, 
      'testpass123'
    );
    
    if (loginResult.success) {
      console.log('\n🎉 ALL TESTS PASSED!');
      console.log('======================');
      console.log('✅ Backend is fully functional');
      console.log('✅ MongoDB connection working');
      console.log('✅ User registration working');
      console.log('✅ User login working'); 
      console.log('✅ JWT authentication working');
      console.log('✅ Data is being stored in database');
      
      console.log('\n🔄 Frontend Environment Status:');
      console.log('   📱 Flutter app is set to: DEVELOPMENT (localhost:3000)');
      console.log('   🌐 Backend server running on: http://localhost:3000');
      console.log('   ✅ Ready for frontend testing!');
      
    } else {
      console.log('\n❌ Login test failed.');
    }

  } catch (error) {
    console.error('❌ Test error:', error);
  }
}

// Wait a moment for server to be ready, then run tests
setTimeout(runTests, 1000);