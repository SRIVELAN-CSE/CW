// Simple Flutter connection test
// Run this in the Flutter app console to test the new CORS settings

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testFlutterConnection();
}

Future<void> testFlutterConnection() async {
  print('🧪 Testing Flutter-Backend Connection...\n');

  const baseUrl = 'https://civic-welfare-backend.onrender.com/api';
  
  // Test 1: Health Check
  print('1️⃣ Testing Health Check...');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Origin': 'http://127.0.0.1:60548', // Flutter dev server origin
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Health Check: SUCCESS');
      print('   Status: ${data['status']}');
      print('   Database: ${data['database']}');
      print('   Uptime: ${data['uptime']} seconds');
    } else {
      print('❌ Health Check: FAILED - Status ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Health Check: ERROR - $e');
  }

  // Test 2: Admin Login
  print('\n2️⃣ Testing Admin Login...');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Origin': 'http://127.0.0.1:60548',
      },
      body: jsonEncode({
        'email': 'admin@civicwelfare.com',
        'password': 'admin123456'
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Admin Login: SUCCESS');
      print('   User: ${data['data']['user']['name']}');
      print('   Token: ${data['data']['access_token'] != null ? 'Generated' : 'Missing'}');
    } else {
      print('❌ Admin Login: FAILED - Status ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Admin Login: ERROR - $e');
  }

  // Test 3: CORS Headers Check
  print('\n3️⃣ Testing CORS Headers...');
  try {
    final response = await http.options(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Origin': 'http://127.0.0.1:60548',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type',
      },
    );

    print('   CORS Status: ${response.statusCode}');
    print('   Access-Control-Allow-Origin: ${response.headers['access-control-allow-origin']}');
    print('   Access-Control-Allow-Methods: ${response.headers['access-control-allow-methods']}');
  } catch (e) {
    print('❌ CORS Test: ERROR - $e');
  }

  print('\n🎯 Connection Test Complete!');
  print('📝 If tests pass, the Flutter app should now connect successfully');
}

// Test function to call from Flutter app
Future<bool> quickConnectionTest() async {
  try {
    final response = await http.get(
      Uri.parse('https://civic-welfare-backend.onrender.com/api/health'),
      headers: {'Origin': 'http://127.0.0.1:60548'},
    ).timeout(const Duration(seconds: 10));
    
    return response.statusCode == 200;
  } catch (e) {
    print('Connection test failed: $e');
    return false;
  }
}