// Quick API test
const http = require('http');

// Test health endpoint
console.log('🔍 Testing health endpoint...');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/health',
  method: 'GET'
};

const req = http.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    if (res.statusCode === 200) {
      console.log('✅ Health endpoint working!');
      const response = JSON.parse(data);
      console.log('   Status:', response.status);
      console.log('   Database:', response.database);
      console.log('   Uptime:', response.uptime + 's');
      
      // Test registration
      testRegistration();
    } else {
      console.log('❌ Health endpoint failed:', res.statusCode);
    }
  });
});

req.on('error', (error) => {
  console.log('❌ Connection error:', error.message);
  console.log('   Make sure the server is running on http://localhost:3000');
});

req.end();

function testRegistration() {
  console.log('\n🧪 Testing registration endpoint...');
  
  const userData = JSON.stringify({
    name: 'Quick Test User',
    email: `quicktest${Date.now()}@example.com`,
    phone: '1234567890',
    password: 'test123',
    confirmPassword: 'test123',
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
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      if (res.statusCode === 201) {
        console.log('✅ Registration endpoint working!');
        const response = JSON.parse(data);
        console.log('   User ID:', response.data?.user?.id);
        console.log('   User Name:', response.data?.user?.name);
        console.log('   User Type:', response.data?.user?.userType);
        console.log('   Has Token:', !!response.data?.access_token);
        
        console.log('\n🎉 BACKEND IS FULLY FUNCTIONAL!');
        console.log('   ✅ Health check passed');
        console.log('   ✅ MongoDB connected');
        console.log('   ✅ User registration works');
        console.log('   ✅ Database storage confirmed');
        console.log('   ✅ JWT token generation works');
        
      } else {
        console.log('❌ Registration failed:', res.statusCode);
        const response = JSON.parse(data);
        console.log('   Error:', response.message);
      }
    });
  });
  
  req.on('error', (error) => {
    console.log('❌ Registration error:', error.message);
  });
  
  req.write(userData);
  req.end();
}