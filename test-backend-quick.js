// Quick test to check if backend API is working
const testBackend = async () => {
  try {
    const response = await fetch('http://localhost:8000/api/health');
    console.log('Response status:', response.status);
    const data = await response.text();
    console.log('Response data:', data);
  } catch (error) {
    console.error('Error:', error);
  }
};

testBackend();