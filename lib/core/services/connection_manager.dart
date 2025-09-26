import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment_switcher.dart';

class ConnectionManager {
  static bool _isBackendAvailable = false;
  static DateTime? _lastConnectionTest;
  static const Duration _connectionTestCooldown = Duration(minutes: 1);

  /// Test backend connection with retry mechanism
  static Future<bool> testBackendConnection({int maxRetries = 3}) async {
    // Skip test if recently tested and successful
    if (_isBackendAvailable && 
        _lastConnectionTest != null && 
        DateTime.now().difference(_lastConnectionTest!) < _connectionTestCooldown) {
      return true;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔍 Testing backend connection (attempt $attempt/$maxRetries)');
        print('🌐 URL: ${EnvironmentSwitcher.baseUrl}/health');

        final response = await http.get(
          Uri.parse('${EnvironmentSwitcher.baseUrl}/health'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 30)); // Extended timeout for Render cold start

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Backend connection successful!');
          print('📊 Backend status: ${data['status']}');
          print('💾 Database: ${data['database']}');
          
          _isBackendAvailable = true;
          _lastConnectionTest = DateTime.now();
          return true;
        } else {
          print('❌ Backend responded with status: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Connection attempt $attempt failed: $e');
        
        if (attempt < maxRetries) {
          print('⏳ Waiting before retry (Render cold start takes ~30s)...');
          await Future.delayed(Duration(seconds: 10 * attempt)); // Exponential backoff
        }
      }
    }

    _isBackendAvailable = false;
    _lastConnectionTest = DateTime.now();
    print('🔴 Backend connection failed after $maxRetries attempts');
    return false;
  }

  /// Wake up Render service (handles cold start)
  static Future<void> wakeUpRenderService() async {
    try {
      print('🔥 Waking up Render service...');
      
      // Multiple wake-up attempts to different endpoints
      final endpoints = [
        '/health',
        '/auth/ping', 
        '/'
      ];

      for (final endpoint in endpoints) {
        try {
          await http.get(
            Uri.parse('${EnvironmentSwitcher.baseUrl}$endpoint'),
            headers: {'User-Agent': 'CivicWelfare-Flutter-App'},
          ).timeout(const Duration(seconds: 5));
          break; // Success, stop trying other endpoints
        } catch (e) {
          // Ignore individual failures, keep trying
        }
      }
      
      print('🔥 Wake-up requests sent');
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      print('⚠️ Wake-up failed: $e');
    }
  }

  /// Get connection status
  static bool get isBackendAvailable => _isBackendAvailable;

  /// Force connection recheck
  static void resetConnectionStatus() {
    _isBackendAvailable = false;
    _lastConnectionTest = null;
  }

  /// Smart connection with fallback handling
  static Future<Map<String, dynamic>?> makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
    String? authToken,
  }) async {
    // Ensure backend is available
    if (!await testBackendConnection()) {
      print('🔴 Backend unavailable - cannot make request to $endpoint');
      return null;
    }

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?additionalHeaders,
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      late http.Response response;
      final uri = Uri.parse('${EnvironmentSwitcher.baseUrl}$endpoint');

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('❌ Request failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Request error: $e');
      resetConnectionStatus(); // Reset connection status on error
      return null;
    }
  }
}