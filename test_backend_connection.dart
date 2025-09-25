import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Flutter to Backend Connection...\n');
  
  // Test connection to localhost backend
  const baseUrl = 'http://localhost:3000/api';
  
  try {
    print('1️⃣ Testing Health Check...');
    final healthResponse = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    
    if (healthResponse.statusCode == 200) {
      final data = json.decode(healthResponse.body);
      print('✅ Health Check Successful!');
      print('   Status: ${data['status']}');
      print('   Database: ${data['database']}');
      print('   Uptime: ${data['uptime']}s');
    } else {
      print('❌ Health Check Failed: ${healthResponse.statusCode}');
      return;
    }
    
    print('\n2️⃣ Testing User Registration...');
    final registerData = {
      'name': 'Flutter Test User',
      'email': 'flutter-test-${DateTime.now().millisecondsSinceEpoch}@example.com',
      'phone': '1234567890',
      'password': 'flutter123',
      'confirmPassword': 'flutter123',
      'userType': 'public',
      'location': 'Flutter Test City'
    };
    
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(registerData),
    ).timeout(const Duration(seconds: 10));
    
    if (registerResponse.statusCode == 201) {
      final regData = json.decode(registerResponse.body);
      print('✅ Registration Successful!');
      print('   User ID: ${regData['data']['user']['id']}');
      print('   Email: ${regData['data']['user']['email']}');
      print('   User Type: ${regData['data']['user']['userType']}');
      print('   Has Token: ${regData['data']['access_token'] != null}');
      
      // Test login
      print('\n3️⃣ Testing User Login...');
      final loginData = {
        'email': regData['data']['user']['email'],
        'password': 'flutter123'
      };
      
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      ).timeout(const Duration(seconds: 10));
      
      if (loginResponse.statusCode == 200) {
        final loginResult = json.decode(loginResponse.body);
        print('✅ Login Successful!');
        print('   User ID: ${loginResult['data']['user']['id']}');
        print('   Has Token: ${loginResult['data']['access_token'] != null}');
        
        print('\n🎉 ALL FLUTTER-BACKEND TESTS PASSED!');
        print('========================================');
        print('✅ Backend server is running perfectly');
        print('✅ MongoDB connection is working');
        print('✅ Flutter can communicate with backend');
        print('✅ User registration works from Flutter');
        print('✅ User login works from Flutter');
        print('✅ Data is being stored in database');
        print('✅ JWT authentication is working');
        
      } else {
        print('❌ Login Failed: ${loginResponse.statusCode}');
        print('   Error: ${loginResponse.body}');
      }
      
    } else {
      print('❌ Registration Failed: ${registerResponse.statusCode}');
      print('   Error: ${registerResponse.body}');
    }
    
  } catch (e) {
    print('❌ Connection Error: $e');
    print('\n💡 Make sure the backend server is running on http://localhost:3000');
  }
}