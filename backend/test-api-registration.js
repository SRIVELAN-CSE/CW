// Test script to verify registration API endpoint
const axios = require('axios');

const testRegistrationAPI = async () => {
  try {
    console.log('🧪 Testing registration API endpoint...');
    
    const testData = {
      name: 'API Test User',
      email: 'apitest@example.com', 
      phone: '9876543210',
      password: 'apitest123',
      confirmPassword: 'apitest123',
      userType: 'public',
      location: 'API Test Location'
    };
    
    // Test registration
    const response = await axios.post('http://localhost:3000/api/auth/register', testData, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Registration API Response:', {
      status: response.status,
      success: response.data.success,
      message: response.data.message,
      userId: response.data.data?.user?.id
    });
    
    return response.data;
    
  } catch (error) {
    if (error.response) {
      console.log('❌ API Error Response:', {
        status: error.response.status,
        message: error.response.data?.message || 'Unknown error',
        details: error.response.data
      });
    } else {
      console.error('❌ Network Error:', error.message);
    }
    return null;
  }
};

// Start server and test
const startServerAndTest = async () => {
  const { spawn } = require('child_process');
  
  console.log('🚀 Starting server...');
  const server = spawn('node', ['server.js'], {
    cwd: process.cwd(),
    stdio: 'pipe'
  });
  
  // Wait for server to start
  await new Promise((resolve) => {
    server.stdout.on('data', (data) => {
      const output = data.toString();
      console.log('Server:', output.trim());
      if (output.includes('Server running')) {
        resolve();
      }
    });
    
    server.stderr.on('data', (data) => {
      console.log('Server Error:', data.toString().trim());
    });
  });
  
  // Wait a bit more for full startup
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Run the test
  const result = await testRegistrationAPI();
  
  // Kill server
  server.kill();
  
  return result;
};

startServerAndTest();