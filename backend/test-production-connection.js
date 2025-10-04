// Test Production Backend Connection
// This script tests if the CORS fix is deployed and working

async function testBackendConnection() {
  const baseUrl = 'https://civic-welfare-backend.onrender.com/api';
  
  console.log('🧪 Testing Backend Connection...');
  console.log(`📡 URL: ${baseUrl}/health`);
  
  try {
    const response = await fetch(`${baseUrl}/health`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const data = await response.json();
      console.log('✅ Backend Connection Successful!');
      console.log('📊 Response:', data);
      return true;
    } else {
      console.log('❌ Backend responded with error:', response.status);
      return false;
    }
  } catch (error) {
    console.log('❌ Connection failed:', error.message);
    return false;
  }
}

// Test connection every 10 seconds
async function monitorDeployment() {
  console.log('🔄 Monitoring Render deployment...');
  let attempts = 0;
  const maxAttempts = 20; // 3+ minutes of testing
  
  while (attempts < maxAttempts) {
    attempts++;
    console.log(`\n🔍 Attempt ${attempts}/${maxAttempts}`);
    
    const success = await testBackendConnection();
    if (success) {
      console.log('\n🎉 CORS Fix Deployed Successfully!');
      console.log('✅ Backend is ready for Flutter connections');
      console.log('\n📱 Next steps:');
      console.log('   1. Run: flutter run -d chrome');
      console.log('   2. Check browser console for successful API calls');
      console.log('   3. Test dashboard functionalities');
      break;
    }
    
    if (attempts < maxAttempts) {
      console.log('⏱️ Waiting 10 seconds before next attempt...');
      await new Promise(resolve => setTimeout(resolve, 10000));
    } else {
      console.log('\n⚠️ Deployment might still be in progress');
      console.log('🌐 Check Render dashboard for deployment status');
    }
  }
}

// Start monitoring
monitorDeployment();