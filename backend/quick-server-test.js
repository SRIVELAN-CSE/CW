const axios = require('axios');

async function quickTest() {
  try {
    console.log('🔍 Testing if server is running...');
    
    const response = await axios.get('http://localhost:3000/api/health', {
      timeout: 5000
    });
    
    console.log('✅ Server is running!');
    console.log('📊 Health Status:', response.data);
    
    return true;
  } catch (error) {
    console.log('❌ Server not responding:', error.code || error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 Server is not running. Please start it with: node server.js');
    }
    
    return false;
  }
}

quickTest();