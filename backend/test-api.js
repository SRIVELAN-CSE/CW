const https = require('https');
const http = require('http');

// Test health endpoint
const testAPI = () => {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/health',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const req = http.request(options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      console.log('✅ Health Check Response:');
      console.log('Status:', res.statusCode);
      console.log('Response:', JSON.stringify(JSON.parse(data), null, 2));
      
      // Test login endpoint
      testLogin();
    });
  });

  req.on('error', (error) => {
    console.error('❌ Health check failed:', error.message);
  });

  req.end();
};

// Test login with seeded admin user
const testLogin = () => {
  const loginData = JSON.stringify({
    email: 'admin@civicwelfare.com',
    password: 'admin123456'
  });

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

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      console.log('\n✅ Login Test Response:');
      console.log('Status:', res.statusCode);
      const response = JSON.parse(data);
      if (response.token) {
        console.log('✅ JWT Token received successfully');
        console.log('User:', response.user.name, '(' + response.user.userType + ')');
        console.log('\n🎉 Backend API is working perfectly!');
        console.log('\n📋 Available Test Accounts:');
        console.log('Admin: admin@civicwelfare.com / admin123456');
        console.log('Public User: john.doe@email.com / password123');
        console.log('Officer: kumar.officer@civicwelfare.com / officer123');
        console.log('\n🌐 API Base URL: http://localhost:3000/api');
        console.log('📊 Health Check: http://localhost:3000/api/health');
      } else {
        console.log('Response:', JSON.stringify(response, null, 2));
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Login test failed:', error.message);
  });

  req.write(loginData);
  req.end();
};

console.log('🧪 Testing Civic Welfare Backend API...\n');
testAPI();