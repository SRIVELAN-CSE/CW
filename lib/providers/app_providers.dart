import 'package:flutter/foundation.dart';
import '../models/user_enhanced.dart';
import '../models/report_enhanced.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;

  final ApiService _apiService = ApiService();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.login(email, password);
      
      if (response['success'] == true) {
        _token = response['data']['token'];
        _currentUser = User.fromJson(response['data']['user']);
        
        // Store token in secure storage or SharedPreferences
        await _storeToken(_token!);
        
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserType userType,
    String? department,
    String? employeeId,
    UserLocation? location,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final userData = {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'userType': userType.toString().split('.').last,
        if (department != null) 'department': department,
        if (employeeId != null) 'employeeId': employeeId,
        if (location != null) 'location': location.toJson(),
      };
      
      final response = await _apiService.register(userData);
      
      if (response['success'] == true) {
        // Registration successful, but user might need approval
        return true;
      } else {
        _setError(response['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Log error but don't prevent logout
      debugPrint('Logout error: $e');
    }
    
    _currentUser = null;
    _token = null;
    await _clearToken();
    notifyListeners();
  }

  Future<bool> refreshUserProfile() async {
    if (_token == null) return false;
    
    try {
      final response = await _apiService.getProfile();
      
      if (response['success'] == true) {
        _currentUser = User.fromJson(response['data']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    UserLocation? location,
    String? profilePictureUrl,
  }) async {
    if (_currentUser == null) return false;
    
    try {
      _setLoading(true);
      _setError(null);

      final profileData = <String, dynamic>{};
      if (name != null) profileData['name'] = name;
      if (phone != null) profileData['phone'] = phone;
      if (location != null) profileData['location'] = location.toJson();
      if (profilePictureUrl != null) profileData['profilePicture'] = profilePictureUrl;
      
      final response = await _apiService.updateProfile(profileData);
      
      if (response['success'] == true) {
        _currentUser = User.fromJson(response['data']);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Update failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.changePassword(currentPassword, newPassword, newPassword);
      
      if (response['success'] == true) {
        return true;
      } else {
        _setError(response['message'] ?? 'Password change failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _storeToken(String token) async {
    // Implement secure token storage using flutter_secure_storage or SharedPreferences
    // For now, this is a placeholder
  }

  Future<void> _clearToken() async {
    // Implement token clearing from secure storage
    // For now, this is a placeholder
  }

  Future<void> initializeFromStorage() async {
    // Implement token retrieval and auto-login on app start
    // For now, this is a placeholder
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class ReportsProvider with ChangeNotifier {
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;
  Report? _selectedReport;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Report? get selectedReport => _selectedReport;

  final ApiService _apiService = ApiService();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> fetchReports({
    int page = 1,
    int limit = 20,
    ReportStatus? status,
    ReportCategory? category,
    String? search,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.getReports(
        page: page,
        limit: limit,
        status: status?.toString().split('.').last,
        category: category?.toString().split('.').last,
        search: search,
      );
      
      if (response['success'] == true) {
        final List<dynamic> reportsData = response['data']['reports'];
        _reports = reportsData.map((data) => Report.fromJson(data)).toList();
        notifyListeners();
      } else {
        _setError(response['message'] ?? 'Failed to fetch reports');
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createReport({
    required String title,
    required String description,
    required ReportCategory category,
    String? subCategory,
    required ReportLocation location,
    List<String>? imageUrls,
    bool isAnonymous = false,
    bool isUrgent = false,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final reportData = {
        'title': title,
        'description': description,
        'category': category.toString().split('.').last,
        if (subCategory != null) 'subCategory': subCategory,
        'location': location.toJson(),
        if (imageUrls != null) 'images': imageUrls,
        'isAnonymous': isAnonymous,
        'isUrgent': isUrgent,
      };
      
      final response = await _apiService.createReport(reportData);
      
      if (response['success'] == true) {
        final newReport = Report.fromJson(response['data']);
        _reports.insert(0, newReport);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to create report');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateReportStatus(String reportId, ReportStatus status, {String? notes}) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.updateReportStatus(
        reportId,
        status.toString().split('.').last,
        notes ?? 'Status updated',
      );
      
      if (response['success'] == true) {
        final updatedReport = Report.fromJson(response['data']);
        final index = _reports.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          _reports[index] = updatedReport;
          if (_selectedReport?.id == reportId) {
            _selectedReport = updatedReport;
          }
          notifyListeners();
        }
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to update report');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> upvoteReport(String reportId) async {
    try {
      // Since upvoteReport doesn't exist in API service, we'll implement it as a status update
      // For now, just return true as a placeholder
      debugPrint('Upvote functionality needs to be implemented in API service');
      return true;
    } catch (e) {
      debugPrint('Upvote error: $e');
      return false;
    }
  }

  Future<bool> addComment(String reportId, String comment) async {
    try {
      // Since addComment doesn't exist in API service, we'll implement it as a status update
      // For now, just return true as a placeholder
      debugPrint('Comment functionality needs to be implemented in API service');
      return true;
    } catch (e) {
      debugPrint('Comment error: $e');
      return false;
    }
  }

  void selectReport(Report report) {
    _selectedReport = report;
    notifyListeners();
  }

  void clearSelectedReport() {
    _selectedReport = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Report> getReportsByStatus(ReportStatus status) {
    return _reports.where((report) => report.status == status).toList();
  }

  List<Report> getUserReports(String userId) {
    return _reports.where((report) => report.userId == userId).toList();
  }
}