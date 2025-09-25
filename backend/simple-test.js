// Simple test to verify API endpoint
const axios = require('axios');

const testAPI = async () => {
  try {
    console.log('Testing health endpoint...');
    const healthResponse = await axios.get('http://localhost:3000/api/health');
    console.log('✅ Health check:', healthResponse.data);
    
    console.log('\nTesting registration endpoint...');
    const registerData = {
      name: 'Test User API',
      email: `test${Date.now()}@example.com`,
      phone: '1234567890',
      password: 'password123',
      confirmPassword: 'password123',
      userType: 'public',
      location: 'Test Location'
    };
    
    const registerResponse = await axios.post('http://localhost:3000/api/auth/register', registerData);
    console.log('✅ Registration successful:', {
      success: registerResponse.data.success,
      message: registerResponse.data.message,
      userId: registerResponse.data.data?.user?.id
    });
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
};

testAPI();