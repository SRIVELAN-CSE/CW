import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report.dart';
import '../core/config/environment_switcher.dart';

class BackendApiService {
  // Dynamic base URL from environment switcher
  static String get baseUrl => EnvironmentSwitcher.baseUrl;

  // Headers for API requests
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Test backend connection
  static Future<bool> testConnection() async {
    try {
      print('🔍 Testing connection to: $baseUrl');
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('✅ Backend connection successful');
        return true;
      } else {
        print('❌ Backend connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Backend connection error: $e');
      return false;
    }
  }

  /// 🔐 AUTHENTICATE USER (LOGIN)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      await EnvironmentSwitcher.initialize();
      print('🔐 Attempting login for: $email');
      print('🌐 Using server: $baseUrl');
      print('🔧 Environment: ${EnvironmentSwitcher.currentEnvironment}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      print('🔍 Login response status: ${response.statusCode}');
      print('🔍 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Login successful with ${EnvironmentSwitcher.currentEnvironment}!');
        return data;
      } else {
        print('❌ Login failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('🚨 Login error: $e');
      print('🔧 Current environment: ${EnvironmentSwitcher.currentEnvironment}');
      return null;
    }
  }

  /// 👤 REGISTER NEW USER
  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String location,
    required String userType,
    String? department,
  }) async {
    try {
      await EnvironmentSwitcher.initialize();
      print('📝 Registering user: $email');
      print('👤 User type: $userType');
      print('🏢 Department: ${department ?? 'others'}');
      print('🌐 Using server: $baseUrl');

      final requestBody = {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'location': location,
        'userType': userType.toLowerCase(),
        'user_type': userType.toLowerCase(),
        'department': department ?? 'others',
      };

      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      print('🔍 Registration response status: ${response.statusCode}');
      print('🔍 Registration response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Registration successful!');
        if (userType.toLowerCase() == 'officer') {
          print('👮‍♂️ Officer registration request submitted for approval');
        }
        return data;
      } else {
        print('❌ Registration failed with status ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          return {'error': errorData['message'] ?? 'Registration failed'};
        } catch (e) {
          return {'error': 'Registration failed with status ${response.statusCode}'};
        }
      }
    } catch (e) {
      print('🚨 Registration error: $e');
      return {'error': 'Network error during registration: $e'};
    }
  }



  /// Create a new report in the backend database
  static Future<Map<String, dynamic>?> createReport(Report report) async {
    try {
      print('🔍 Sending report to backend database...');

      // Prepare report data for API
      final reportData = {
        'title': report.title,
        'description': report.description,
        'category': report.category,
        'location': report.location,
        'address': report.address,
        'latitude': report.latitude,
        'longitude': report.longitude,
        'priority': report.priority.toString().split('.').last.toLowerCase(),
        'department': report.category, // Map category to department
        'reporter_name': report.reporterName,
        'reporter_email': report.reporterEmail,
        'reporter_phone': report.reporterPhone,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/reports/'),
            headers: headers,
            body: json.encode(reportData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        print('✅ Report saved to backend database!');
        final result = json.decode(response.body);
        return result;
      } else {
        print('❌ Failed to save report: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error saving report to backend: $e');
      return null;
    }
  }

  /// Get all reports from backend database
  static Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      print('🔍 Fetching reports from backend database...');

      final response = await http
          .get(Uri.parse('$baseUrl/reports/simple'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} reports from backend');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to fetch reports: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching reports from backend: $e');
      return [];
    }
  }

  /// Get reports by user ID
  static Future<List<Map<String, dynamic>>> getReportsByUser(
    String userId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/reports/user/$userId'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to fetch user reports: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching user reports: $e');
      return [];
    }
  }

  /// Get reports by department (for officers)
  static Future<List<Map<String, dynamic>>> getReportsByDepartment(
    String department,
  ) async {
    try {
      print('🔍 Fetching reports for department: $department');

      final response = await http
          .get(
            Uri.parse('$baseUrl/reports/department/$department'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} reports for department: $department');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to fetch department reports: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching department reports: $e');
      return [];
    }
  }

  /// Update report status (for officers/admins)
  static Future<bool> updateReportStatus(
    String reportId,
    String status,
    String message,
  ) async {
    try {
      final updateData = {
        'status': status,
        'message': message,
        'updated_by': 'Flutter App',
        'updated_by_role': 'officer',
      };

      final response = await http
          .put(
            Uri.parse('$baseUrl/reports/$reportId/status'),
            headers: headers,
            body: json.encode(updateData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Report status updated successfully');
        return true;
      } else {
        print('❌ Failed to update report status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating report status: $e');
      return false;
    }
  }

  /// User authentication
  static Future<Map<String, dynamic>?> authenticateUser(
    String email,
    String password,
  ) async {
    try {
      final authData = {'username': email, 'password': password};

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: authData,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ User authenticated successfully');
        return json.decode(response.body);
      } else {
        print('❌ Authentication failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Authentication error: $e');
      return null;
    }
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(
    String userId,
    String token,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users/$userId'),
            headers: {...headers, 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to get user profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Sync local data to backend
  static Future<bool> syncLocalDataToBackend(
    List<Map<String, dynamic>> localReports,
  ) async {
    try {
      print('🔄 Syncing ${localReports.length} local reports to backend...');

      int successCount = 0;

      for (final reportData in localReports) {
        try {
          // Convert local report format to backend format
          final backendData = {
            'title': reportData['title'],
            'description': reportData['description'],
            'category': reportData['category'],
            'location': reportData['location'],
            'address': reportData['address'] ?? reportData['location'],
            'priority': 'medium', // Default priority
            'department': reportData['category'],
            'reporter_name': reportData['reporterName'] ?? 'Anonymous',
            'reporter_email':
                reportData['reporterEmail'] ?? 'anonymous@example.com',
            'reporter_phone': reportData['reporterPhone'] ?? '',
          };

          final response = await http
              .post(
                Uri.parse('$baseUrl/reports/'),
                headers: headers,
                body: json.encode(backendData),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 201) {
            successCount++;
          }
        } catch (e) {
          print('❌ Failed to sync report: $e');
        }
      }

      print('✅ Synced $successCount/${localReports.length} reports to backend');
      return successCount > 0;
    } catch (e) {
      print('❌ Error during sync: $e');
      return false;
    }
  }

  /// Create report with authentication
  static Future<Map<String, dynamic>?> createReportAuthenticated({
    required String token,
    required Report report,
  }) async {
    try {
      final authenticatedHeaders = {
        ...headers,
        'Authorization': 'Bearer $token',
      };

      final reportData = {
        'title': report.title,
        'description': report.description,
        'category': report.category,
        'location': report.location,
        'address': report.address,
        'latitude': report.latitude,
        'longitude': report.longitude,
        'priority': report.priority.toString().split('.').last.toLowerCase(),
        'department': report.department,
        'reporter_name': report.reporterName,
        'reporter_email': report.reporterEmail,
        'reporter_phone': report.reporterPhone,
        'image_urls': report.imageUrls,
        'video_urls': report.videoUrls,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/reports/'),
            headers: authenticatedHeaders,
            body: json.encode(reportData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        print('✅ Report created successfully in backend');
        return json.decode(response.body);
      } else {
        print('❌ Failed to create report: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating authenticated report: $e');
      return null;
    }
  }

  /// Create feedback with authentication
  static Future<Map<String, dynamic>?> createFeedback({
    required String token,
    required String type,
    required String message,
    required String title,
    required int rating,
    String? reportId,
  }) async {
    try {
      final authenticatedHeaders = {
        ...headers,
        'Authorization': 'Bearer $token',
      };

      final feedbackData = {
        'type': type,
        'message': message,
        'title': title,
        'rating': rating,
        'report_id': reportId,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/feedback/'),
            headers: authenticatedHeaders,
            body: json.encode(feedbackData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        print('✅ Feedback created successfully in backend');
        return json.decode(response.body);
      } else {
        print('❌ Failed to create feedback: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating feedback: $e');
      return null;
    }
  }


}
