// Test the fixed endpoints
const https = require('https');

async function testReportsEndpoint() {
  return new Promise((resolve) => {
    const req = https.get('https://civic-welfare-backend.onrender.com/api/reports/simple', (res) => {
      let data = '';
      
      res.on('data', chunk => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          console.log('✅ Reports endpoint test successful!');
          console.log(`📊 Response type: ${Array.isArray(parsed) ? 'Array' : 'Object'}`);
          console.log(`📊 Reports count: ${Array.isArray(parsed) ? parsed.length : 'Not an array'}`);
          if (Array.isArray(parsed) && parsed.length > 0) {
            console.log('📋 First report sample:', {
              id: parsed[0]._id,
              title: parsed[0].title,
              category: parsed[0].category,
              status: parsed[0].status
            });
          }
          resolve(true);
        } catch (e) {
          console.log('❌ Failed to parse response:', e.message);
          resolve(false);
        }
      });
    });
    
    req.on('error', (e) => {
      console.log('❌ Request failed:', e.message);
      resolve(false);
    });
  });
}

async function runTests() {
  console.log('🧪 Testing Fixed Endpoints...');
  console.log('=' .repeat(50));
  
  console.log('\n📊 Testing /reports/simple endpoint...');
  await testReportsEndpoint();
  
  console.log('\n✅ Endpoint tests completed!');
  console.log('🚀 Ready to test Flutter app with fixes!');
}

runTests();