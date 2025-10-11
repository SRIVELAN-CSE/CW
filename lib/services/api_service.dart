import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'environment_service.dart';

class ApiService {
  // Dynamic base URL from environment service
  String get baseUrl => EnvironmentService.instance.currentConfig.apiURL;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  Map<String, String> get _authHeaders {
    final headers = Map<String, String>.from(_headers);
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }
  
  String? _token;
  String? _refreshToken;
  
  // Initialize service with stored tokens and environment
  Future<void> init() async {
    await EnvironmentService.instance.initialize();
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }
  
  // Token management
  Future<void> setTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('refresh_token', refreshToken);
  }
  
  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
  
  bool get isAuthenticated => _token != null;
  
  // Refresh token if expired
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: _headers,
        body: jsonEncode({
          'refreshToken': _refreshToken,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await setTokens(data['data']['token'], data['data']['refreshToken']);
        return true;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    
    return false;
  }
  
  // Generic API request handler with automatic token refresh
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/$endpoint');
      http.Response response;
      
      Map<String, String> headers = requiresAuth ? _authHeaders : _headers;
      
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
      
      // Handle token expiration
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return _makeRequest(method, endpoint, body: body, requiresAuth: requiresAuth);
        } else {
          // Refresh failed, user needs to login again
          await clearTokens();
          throw Exception('Authentication required');
        }
      }
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Unknown error',
          statusCode: response.statusCode,
          errors: responseData['errors'],
        );
      }
      
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: 'Network error: $e');
    }
  }
  
  // Authentication APIs
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await _makeRequest('POST', 'auth/register', 
        body: userData, requiresAuth: false);
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _makeRequest('POST', 'auth/login', 
        body: {
          'email': email,
          'password': password,
        }, 
        requiresAuth: false);
    
    if (response['success'] == true) {
      final data = response['data'];
      await setTokens(data['token'], data['refreshToken']);
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> logout() async {
    try {
      await _makeRequest('POST', 'auth/logout');
    } finally {
      await clearTokens();
    }
    return {'success': true, 'message': 'Logout successful'};
  }
  
  Future<Map<String, dynamic>> getProfile() async {
    return await _makeRequest('GET', 'auth/profile');
  }
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    return await _makeRequest('PUT', 'auth/profile', body: profileData);
  }
  
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    return await _makeRequest('POST', 'auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
  
  Future<Map<String, dynamic>> checkRegistrationStatus(String requestId) async {
    return await _makeRequest('GET', 'auth/registration-status/$requestId', 
        requiresAuth: false);
  }
  
  // Report APIs
  Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    return await _makeRequest('POST', 'reports', body: reportData);
  }
  
  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
    String? priority,
    String? search,
    double? latitude,
    double? longitude,
    double? radius,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sortBy,
      'order': sortOrder,
    };
    
    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;
    if (priority != null) queryParams['priority'] = priority;
    if (search != null) queryParams['search'] = search;
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    if (radius != null) queryParams['radius'] = radius.toString();
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return await _makeRequest('GET', 'reports?$queryString', requiresAuth: false);
  }
  
  Future<Map<String, dynamic>> getReport(String reportId) async {
    return await _makeRequest('GET', 'reports/$reportId');
  }
  
  Future<Map<String, dynamic>> updateReportStatus(
    String reportId,
    String status,
    String message, {
    bool isInternal = false,
  }) async {
    return await _makeRequest('PUT', 'reports/$reportId/status', body: {
      'status': status,
      'message': message,
      'isInternal': isInternal,
    });
  }
  
  Future<Map<String, dynamic>> assignReport(String reportId, String officerId) async {
    return await _makeRequest('POST', 'reports/$reportId/assign', body: {
      'assignedTo': officerId,
    });
  }
  
  Future<Map<String, dynamic>> getReportStatistics() async {
    return await _makeRequest('GET', 'reports/statistics/dashboard');
  }
  
  // Notification APIs
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (isRead != null) queryParams['isRead'] = isRead.toString();
    if (type != null) queryParams['type'] = type;
    
    final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _authHeaders);
    
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    return await _makeRequest('PUT', 'notifications/$notificationId/read');
  }
  
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return await _makeRequest('PUT', 'notifications/mark-all-read');
  }
  
  // User Management APIs (Admin/Officer)
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 10,
    String? userType,
    String? search,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (userType != null) queryParams['userType'] = userType;
    if (search != null) queryParams['search'] = search;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    
    final uri = Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _authHeaders);
    
    return jsonDecode(response.body);
  }
  
  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    return await _makeRequest('GET', 'health', requiresAuth: false);
  }
}

// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<dynamic>? errors;
  
  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });
  
  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return '$message: ${errors!.join(', ')}';
    }
    return message;
  }
}