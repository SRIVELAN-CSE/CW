import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../models/registration_request.dart';
import '../models/password_reset_request.dart';
import '../models/need_request.dart';
import '../models/feedback.dart';
import '../models/certificate.dart';
import '../core/utils/web_storage.dart';
import '../core/config/environment_switcher.dart';
import 'backend_api_service.dart';

class DatabaseService {
  // Live backend API service
  final BackendApiService _backendApi = BackendApiService();

  // Local storage keys for browser cache
  static const String _reportsKey = 'civic_welfare_reports';
  static const String _notificationsKey = 'civic_welfare_notifications';
  static const String _registrationRequestsKey =
      'civic_welfare_registration_requests';
  static const String _passwordResetRequestsKey =
      'civic_welfare_password_reset_requests';
  static const String _approvedUsersKey = 'civic_welfare_approved_users';
  static const String _feedbackKey = 'civic_welfare_feedback';
  static const String _certificatesKey = 'civic_welfare_certificates';
  static const String _currentUserIdKey = 'current_user_id';
  static const String _currentUserNameKey = 'current_user_name';
  static const String _currentUserEmailKey = 'current_user_email';
  static const String _currentUserRoleKey = 'current_user_role';
  static const String _authTokenKey = 'auth_token';

  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  // LIVE AUTHENTICATION WITH BACKEND
  Future<Map<String, dynamic>?> authenticateUser(
    String email,
    String password,
  ) async {
    try {
      print('[AUTH] Attempting live authentication for: $email');
      print('[AUTH] Environment: ${EnvironmentSwitcher.currentEnvironment}');
      print('[AUTH] API URL: ${EnvironmentSwitcher.baseUrl}');

      final response = await _backendApi.login(email, password);

      if (response != null && response['access_token'] != null) {
        final userInfo = response['user'];
        final token = response['access_token'];

        // Save authentication token
        await _saveAuthToken(token);

        // Save user session with live data
        await saveUserSession(
          userId: userInfo['id'],
          userName: userInfo['name'],
          userEmail: userInfo['email'],
          userRole: userInfo['userType'],
          department: userInfo['department'],
        );

        print('[SUCCESS] Live authentication successful!');
        print('User: ${userInfo['name']} (${userInfo['userType']})');
        print('Department: ${userInfo['department']}');
        print('Environment: ${EnvironmentSwitcher.currentEnvironment}');
        print('✅ Connected to ${EnvironmentSwitcher.isProduction ? 'CLOUD' : 'LOCAL'} database');

        return {'success': true, 'user': userInfo, 'token': token};
      }

      print('[ERROR] Authentication failed');
      return null;
    } catch (e) {
      print('[ERROR] Authentication error: $e');
      return null;
    }
  }

  // REGISTER NEW USER (LIVE DATA)
  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String location,
    required String userType,
    String? department,
  }) async {
    try {
      print('[REGISTER] Registering new user: $email');
      print('[REGISTER] Environment: ${EnvironmentSwitcher.currentEnvironment}');
      print('[REGISTER] API URL: ${EnvironmentSwitcher.baseUrl}');

      final response = await _backendApi.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        location: location,
        userType: userType,
        department: department,
      );

      if (response != null) {
        print('[SUCCESS] User registered successfully!');
        print('New user: $name ($userType)');
        print('✅ Data saved to ${EnvironmentSwitcher.isProduction ? 'CLOUD' : 'LOCAL'} database');
        return true;
      }

      print('[ERROR] Registration failed');
      return false;
    } catch (e) {
      print('[ERROR] Registration error: $e');
      return false;
    }
  }

  // SAVE AUTH TOKEN
  Future<void> _saveAuthToken(String token) async {
    try {
      if (kIsWeb) {
        WebStorage.setString(_authTokenKey, token);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_authTokenKey, token);
      }
    } catch (e) {
      print('Error saving auth token: $e');
    }
  }

  // GET AUTH TOKEN
  Future<String?> getAuthToken() async {
    try {
      if (kIsWeb) {
        return WebStorage.getString(_authTokenKey);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_authTokenKey);
      }
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Save current user session
  Future<void> saveUserSession({
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
    String? department,
  }) async {
    try {
      if (kIsWeb) {
        // Use localStorage for web
        final userData = {
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'userRole': userRole,
          'department': department ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        };
        WebStorage.setJson('user_session', userData);

        print('SESSION SAVED to browser localStorage');
        print('User: $userName ($userRole)');
        if (department != null) print('Department: $department');
        print('Will persist after app restart!');
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentUserIdKey, userId);
        await prefs.setString(_currentUserNameKey, userName);
        await prefs.setString(_currentUserEmailKey, userEmail);
        await prefs.setString(_currentUserRoleKey, userRole);
        if (department != null) {
          await prefs.setString('current_user_department', department);
        }
      }
    } catch (e) {
      print('Error saving user session: $e');
      // For web compatibility, we'll just print and continue
    }
  }

  // Get current user session
  Future<Map<String, String>?> getCurrentUserSession() async {
    try {
      if (kIsWeb) {
        // Use localStorage for web
        final userData = WebStorage.getJson('user_session');
        if (userData == null) return null;

        final session = {
          'userId': userData['userId']?.toString() ?? '',
          'userName': userData['userName']?.toString() ?? '',
          'userEmail': userData['userEmail']?.toString() ?? '',
          'userRole': userData['userRole']?.toString() ?? '',
          'department': userData['department']?.toString() ?? '',
        };

        print('🔍 [SESSION] Retrieved user session from localStorage:');
        print('   User: ${session['userName']} (${session['userRole']})');
        print('   Department: ${session['department']}');

        return session;
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString(_currentUserIdKey);
        final userName = prefs.getString(_currentUserNameKey);
        final userEmail = prefs.getString(_currentUserEmailKey);
        final userRole = prefs.getString(_currentUserRoleKey);
        final department = prefs.getString('current_user_department');

        if (userId == null ||
            userName == null ||
            userEmail == null ||
            userRole == null) {
          return null;
        }

        final session = {
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'userRole': userRole,
          'department': department ?? '',
        };

        print('🔍 [SESSION] Retrieved user session from SharedPreferences:');
        print('   User: ${session['userName']} (${session['userRole']})');
        print('   Department: ${session['department']}');

        return session;
      }
    } catch (e) {
      print('Error getting user session: $e');
      return null;
    }
  }

  // Clear user session
  Future<void> clearUserSession() async {
    try {
      if (kIsWeb) {
        // Use localStorage for web
        WebStorage.remove('user_session');
        print('🗑️ [SESSION] Cleared user session from localStorage');
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_currentUserIdKey);
        await prefs.remove(_currentUserNameKey);
        await prefs.remove(_currentUserEmailKey);
        await prefs.remove(_currentUserRoleKey);
        await prefs.remove('current_user_department');
        print('🗑️ [SESSION] Cleared user session from SharedPreferences');
      }
    } catch (e) {
      print('Error clearing user session: $e');
    }
  }

  // Save a new report
  Future<void> saveReport(Report report) async {
    try {
      // First, save to local storage (existing functionality)
      if (kIsWeb) {
        // Use localStorage for web
        print('🔍 [DEBUG] Saving report on web platform...');
        final reports = await getAllReports();
        print('🔍 [DEBUG] Current reports count: ${reports.length}');
        reports.add(report);
        print('🔍 [DEBUG] Reports count after adding new: ${reports.length}');
        final reportsJson = reports.map((r) => r.toJson()).toList();
        print('🔍 [DEBUG] JSON data size: ${reportsJson.length} items');
        final saveResult = WebStorage.setList('reports', reportsJson);
        print('🔍 [DEBUG] Save result: $saveResult');

        // Verify the save by reading it back
        final verifyReports = WebStorage.getList('reports');
        print(
          '🔍 [DEBUG] Verification: localStorage has ${verifyReports?.length ?? 0} reports',
        );
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        final reports = await getAllReports();
        reports.add(report);
        final reportsJson = reports.map((r) => r.toJson()).toList();
        await prefs.setString(_reportsKey, jsonEncode(reportsJson));
      }

      // PRIMARY: Save to backend database (cloud/local server)
      try {
        print('🔍 [BACKEND] Saving report to ${EnvironmentSwitcher.currentEnvironment} database...');
        print('🌐 [BACKEND] Using server: ${EnvironmentSwitcher.baseUrl}');
        
        final backendResult = await BackendApiService.createReport(report);
        if (backendResult != null) {
          print('✅ [BACKEND] Report successfully saved to ${EnvironmentSwitcher.isProduction ? 'CLOUD' : 'LOCAL'} database!');
          print('🔍 [BACKEND] Backend Report ID: ${backendResult['id']}');
        } else {
          print('⚠️ [BACKEND] Failed to save to backend, but local cache succeeded');
        }
      } catch (e) {
        print('⚠️ [BACKEND] Backend save failed: $e');
        print('ℹ️ [BACKEND] Data is cached locally and will sync when connection is restored');
      }

      // Create notification for officers and admins
      await _createNotification(
        title: 'New Report Submitted',
        message: '${report.reporterName} submitted: ${report.title}',
        reportId: report.id,
        targetRoles: ['officer', 'admin'],
        type: 'NotificationType.newReport',
      );
    } catch (e) {
      print('Error saving report: $e');
    }
  }

  // Get all reports (prioritize backend data)
  Future<List<Report>> getAllReports() async {
    try {
      // First try to get data from backend if connected
      if (await BackendApiService.testConnection()) {
        print('🔍 [LIVE] Loading reports from backend database...');
        final backendReports = await BackendApiService.getAllReports();
        if (backendReports.isNotEmpty) {
          final reports = backendReports
              .map((json) => Report.fromJson(json))
              .toList();
          print(
            '✅ [LIVE] Successfully loaded ${reports.length} reports from backend',
          );

          // Cache the data locally for offline access
          await _cacheReportsLocally(reports);
          return reports;
        }
      }

      // Fallback to local storage if backend not available
      print('🔍 [LOCAL] Loading reports from local storage...');
      if (kIsWeb) {
        // Use localStorage for web
        final reportsData = WebStorage.getList('reports');
        if (reportsData == null) {
          print('🔍 [LOCAL] No reports data found in localStorage');
          return [];
        }

        try {
          final reports = reportsData
              .map((json) => Report.fromJson(json))
              .toList();
          print(
            '🔍 [LOCAL] Successfully parsed ${reports.length} reports from localStorage',
          );
          return reports;
        } catch (e) {
          print('❌ [ERROR] Error parsing local reports: $e');
          return [];
        }
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        final reportsString = prefs.getString(_reportsKey);

        if (reportsString == null) {
          return [];
        }

        try {
          final reportsJson = jsonDecode(reportsString) as List<dynamic>;
          final reports = reportsJson
              .map((json) => Report.fromJson(json))
              .toList();
          print(
            '🔍 [LOCAL] Successfully loaded ${reports.length} reports from SharedPreferences',
          );
          return reports;
        } catch (e) {
          print('❌ [ERROR] Error loading local reports: $e');
          return [];
        }
      }
    } catch (e) {
      print('❌ [ERROR] Error accessing reports: $e');
      return [];
    }
  }

  // Cache reports locally for offline access
  Future<void> _cacheReportsLocally(List<Report> reports) async {
    try {
      final reportsJson = reports.map((report) => report.toJson()).toList();

      if (kIsWeb) {
        WebStorage.setList('reports', reportsJson);
        print('💾 [CACHE] Reports cached in localStorage');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_reportsKey, jsonEncode(reportsJson));
        print('💾 [CACHE] Reports cached in SharedPreferences');
      }
    } catch (e) {
      print('❌ [ERROR] Failed to cache reports locally: $e');
    }
  }

  // Get reports by user ID
  Future<List<Report>> getReportsByUserId(String userId) async {
    final allReports = await getAllReports();
    return allReports.where((report) => report.reporterId == userId).toList();
  }

  // Get reports by department (for officers)
  Future<List<Report>> getReportsByDepartment(String department) async {
    try {
      // First try to get department-specific data from backend
      if (await BackendApiService.testConnection()) {
        print(
          '🔍 [LIVE] Loading reports for department: $department from backend...',
        );
        final backendReports = await BackendApiService.getReportsByDepartment(
          department,
        );
        if (backendReports.isNotEmpty) {
          final reports = backendReports
              .map((json) => Report.fromJson(json))
              .toList();
          print(
            '✅ [LIVE] Successfully loaded ${reports.length} reports for department: $department',
          );
          return reports;
        }
      }

      // Fallback to filtering all reports locally
      print('🔍 [LOCAL] Filtering local reports for department: $department');
      final allReports = await getAllReports();
      final departmentReports = allReports
          .where(
            (report) =>
                report.department.toLowerCase() == department.toLowerCase(),
          )
          .toList();
      print(
        '🔍 [LOCAL] Found ${departmentReports.length} reports for department: $department',
      );
      return departmentReports;
    } catch (e) {
      print('❌ [ERROR] Error getting reports by department: $e');
      return [];
    }
  }

  // Get reports by department and status (for officers)
  Future<List<Report>> getReportsByDepartmentAndStatus(
    String department,
    ReportStatus? status,
  ) async {
    final departmentReports = await getReportsByDepartment(department);
    if (status == null) {
      return departmentReports;
    }
    return departmentReports
        .where((report) => report.status == status)
        .toList();
  }

  // Update a report
  Future<void> updateReport(Report updatedReport) async {
    try {
      final reports = await getAllReports();
      Report? originalReport;

      // Find and update the report
      for (int i = 0; i < reports.length; i++) {
        if (reports[i].id == updatedReport.id) {
          originalReport = reports[i];
          reports[i] = updatedReport;
          break;
        }
      }

      // Save back to storage
      if (kIsWeb) {
        // Use localStorage for web
        final reportsJson = reports.map((r) => r.toJson()).toList();
        WebStorage.setList('reports', reportsJson);
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        final reportsJson = reports.map((r) => r.toJson()).toList();
        await prefs.setString(_reportsKey, jsonEncode(reportsJson));
      }

      // Check if report was resolved and generate certificate
      print('🔍 [CERTIFICATE DEBUG] Checking certificate generation conditions:');
      print('   Original report exists: ${originalReport != null}');
      if (originalReport != null) {
        print('   Original status: ${originalReport.status}');
        print('   Updated status: ${updatedReport.status}');
        print('   Status changed to done: ${updatedReport.status == ReportStatus.done}');
        print('   Original was not done: ${originalReport.status != ReportStatus.done}');
      }
      
      if (originalReport != null && 
          originalReport.status != ReportStatus.done && 
          updatedReport.status == ReportStatus.done) {
        
        print('🏆 [CERTIFICATE] Conditions met! Generating certificate for resolved report...');
        try {
          // Generate certificate for the citizen who reported the issue
          final certificate = await generateCertificateForResolvedReport(updatedReport);
          
          // Create notification about certificate award
          await _createNotification(
            title: '🏆 Certificate Awarded!',
            message: 'Congratulations! You earned a certificate for helping resolve "${updatedReport.title}". Points awarded: ${certificate.pointsAwarded}',
            reportId: updatedReport.id,
            targetRoles: ['citizen'],
            targetUserId: updatedReport.reporterId,
            type: 'NotificationType.certificate',
          );
          
          print('🎉 Certificate generated and notification sent for resolved report: ${updatedReport.id}');
        } catch (e) {
          print('⚠️ Failed to generate certificate for resolved report: $e');
          // Continue with normal status update even if certificate generation fails
        }
      }

      // Create notification for status updates
      await _createNotification(
        title: 'Report Status Updated',
        message:
            'Report "${updatedReport.title}" status changed to ${updatedReport.status.displayName}',
        reportId: updatedReport.id,
        targetRoles: ['citizen'],
        targetUserId: updatedReport.reporterId,
        type: 'NotificationType.statusUpdate',
      );
    } catch (e) {
      print('Error updating report: $e');
    }
  }

  // Get report by ID
  Future<Report?> getReportById(String reportId) async {
    final reports = await getAllReports();
    try {
      return reports.firstWhere((report) => report.id == reportId);
    } catch (e) {
      return null;
    }
  }

  // Delete a report
  Future<void> deleteReport(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reports = await getAllReports();

      // Remove the report
      reports.removeWhere((report) => report.id == reportId);

      // Save back to storage
      final reportsJson = reports.map((r) => r.toJson()).toList();
      await prefs.setString(_reportsKey, jsonEncode(reportsJson));
    } catch (e) {
      print('Error deleting report: $e');
    }
  }

  // Get reports by status
  Future<List<Report>> getReportsByStatus(ReportStatus status) async {
    final allReports = await getAllReports();
    return allReports.where((report) => report.status == status).toList();
  }

  // Get reports by category
  Future<List<Report>> getReportsByCategory(String category) async {
    final allReports = await getAllReports();
    return allReports.where((report) => report.category == category).toList();
  }

  // Search reports
  Future<List<Report>> searchReports(String query) async {
    final allReports = await getAllReports();
    query = query.toLowerCase();

    return allReports
        .where(
          (report) =>
              report.title.toLowerCase().contains(query) ||
              report.description.toLowerCase().contains(query) ||
              report.category.toLowerCase().contains(query) ||
              report.location.toLowerCase().contains(query),
        )
        .toList();
  }

  // Create status update notification for citizen
  Future<void> createStatusUpdateNotification({
    required String reportId,
    required String reportTitle,
    required String reporterId,
    required String newStatus,
    required String officerName,
    String? comment,
  }) async {
    await _createNotification(
      title: 'Report Status Updated',
      message:
          'Your report "$reportTitle" status has been changed to $newStatus by $officerName${comment != null && comment.isNotEmpty ? '. Note: $comment' : ''}',
      reportId: reportId,
      targetRoles: ['citizen'],
      targetUserId: reporterId,
      type: 'NotificationType.statusUpdate',
    );
  }

  // Create general notification (public method)
  Future<void> createNotification({
    required String title,
    required String message,
    required String reportId,
    required List<String> targetRoles,
    String? targetUserId,
    String type = 'info',
  }) async {
    await _createNotification(
      title: title,
      message: message,
      reportId: reportId,
      targetRoles: targetRoles,
      targetUserId: targetUserId,
      type: type,
    );
  }

  // Create notification
  Future<void> _createNotification({
    required String title,
    required String message,
    required String reportId,
    required List<String> targetRoles,
    String? targetUserId,
    String type = 'info',
  }) async {
    try {
      final notifications = await getNotifications();

      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'message': message,
        'reportId': reportId,
        'targetRoles': targetRoles,
        'targetUserId': targetUserId,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': type,
      };

      notifications.add(notification);

      if (kIsWeb) {
        // Use localStorage for web
        WebStorage.setList('notifications', notifications);
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_notificationsKey, jsonEncode(notifications));
      }
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      if (kIsWeb) {
        // Use localStorage for web
        final notificationsData = WebStorage.getList('notifications');
        if (notificationsData == null) return [];

        try {
          return List<Map<String, dynamic>>.from(notificationsData);
        } catch (e) {
          print('Error parsing notifications: $e');
          return [];
        }
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        final notificationsString = prefs.getString(_notificationsKey);

        if (notificationsString == null) {
          return [];
        }

        try {
          return List<Map<String, dynamic>>.from(
            jsonDecode(notificationsString),
          );
        } catch (e) {
          print('Error loading notifications: $e');
          return [];
        }
      }
    } catch (e) {
      print('Error accessing storage for notifications: $e');
      return [];
    }
  }

  // Get notifications for user role
  Future<List<Map<String, dynamic>>> getNotificationsForRole(
    String role, [
    String? userId,
  ]) async {
    final allNotifications = await getNotifications();

    return allNotifications.where((notification) {
      final targetRoles = List<String>.from(notification['targetRoles'] ?? []);
      final targetUserId = notification['targetUserId'];

      // Check if notification is for this role
      if (targetRoles.contains(role)) {
        return true;
      }

      // Check if notification is for specific user
      if (userId != null && targetUserId == userId) {
        return true;
      }

      return false;
    }).toList();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notifications = await getNotifications();

      for (var notification in notifications) {
        if (notification['id'] == notificationId) {
          notification['isRead'] = true;
          break;
        }
      }

      if (kIsWeb) {
        // Use localStorage for web
        WebStorage.setList('notifications', notifications);
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_notificationsKey, jsonEncode(notifications));
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get statistics
  Future<Map<String, int>> getReportStatistics() async {
    final reports = await getAllReports();

    final stats = <String, int>{
      'total': reports.length,
      'submitted': 0,
      'notSeen': 0,
      'resolveSoon': 0,
      'inProgress': 0,
      'done': 0,
      'rejected': 0,
      'closed': 0,
    };

    for (final report in reports) {
      switch (report.status) {
        case ReportStatus.submitted:
          stats['submitted'] = (stats['submitted'] ?? 0) + 1;
          break;
        case ReportStatus.notSeen:
          stats['notSeen'] = (stats['notSeen'] ?? 0) + 1;
          break;
        case ReportStatus.resolveSoon:
          stats['resolveSoon'] = (stats['resolveSoon'] ?? 0) + 1;
          break;
        case ReportStatus.inProgress:
          stats['inProgress'] = (stats['inProgress'] ?? 0) + 1;
          break;
        case ReportStatus.done:
          stats['done'] = (stats['done'] ?? 0) + 1;
          break;
        case ReportStatus.rejected:
          stats['rejected'] = (stats['rejected'] ?? 0) + 1;
          break;
        case ReportStatus.closed:
          stats['closed'] = (stats['closed'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }

  // Get all completed reports
  Future<List<Report>> getCompletedReports() async {
    final reports = await getAllReports();
    return reports
        .where((report) => report.status == ReportStatus.done)
        .toList();
  }

  // Get completed reports by department
  Future<List<Report>> getCompletedReportsByDepartment(
    String department,
  ) async {
    final completedReports = await getCompletedReports();
    return completedReports
        .where(
          (report) =>
              report.department.toLowerCase() == department.toLowerCase(),
        )
        .toList();
  }

  // Get department-wise completion statistics
  Future<Map<String, Map<String, int>>> getDepartmentWiseStats() async {
    final reports = await getAllReports();
    final departmentStats = <String, Map<String, int>>{};

    for (final report in reports) {
      final dept = report.department;
      if (!departmentStats.containsKey(dept)) {
        departmentStats[dept] = {
          'total': 0,
          'completed': 0,
          'inProgress': 0,
          'pending': 0,
        };
      }

      departmentStats[dept]!['total'] =
          (departmentStats[dept]!['total'] ?? 0) + 1;

      switch (report.status) {
        case ReportStatus.done:
          departmentStats[dept]!['completed'] =
              (departmentStats[dept]!['completed'] ?? 0) + 1;
          break;
        case ReportStatus.inProgress:
          departmentStats[dept]!['inProgress'] =
              (departmentStats[dept]!['inProgress'] ?? 0) + 1;
          break;
        default:
          departmentStats[dept]!['pending'] =
              (departmentStats[dept]!['pending'] ?? 0) + 1;
          break;
      }
    }

    return departmentStats;
  }

  // Get completed reports for admin analytics with additional details
  Future<List<Map<String, dynamic>>> getCompletedReportsForAnalytics() async {
    final completedReports = await getCompletedReports();
    return completedReports.map((report) {
      return {
        'id': report.id,
        'title': report.title,
        'department': report.department,
        'category': report.category,
        'location': report.location,
        'completedAt': report.updatedAt,
        'assignedOfficer': report.assignedOfficerName ?? 'Unassigned',
        'resolutionTime': _calculateResolutionTime(
          report.createdAt,
          report.updatedAt,
        ),
        'priority': report.priority,
        'reporterName': report.reporterName,
      };
    }).toList();
  }

  // Helper method to calculate resolution time
  String _calculateResolutionTime(DateTime createdAt, DateTime completedAt) {
    final difference = completedAt.difference(createdAt);
    if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inMinutes} minutes';
    }
  }

  // Create completion notification for admin analytics
  Future<void> createCompletionNotification({
    required String reportId,
    required String reportTitle,
    required String department,
    required String officerName,
    required DateTime completionTime,
    required String resolutionComment,
  }) async {
    try {
      final notification = {
        'id': 'completion_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'completion',
        'reportId': reportId,
        'reportTitle': reportTitle,
        'department': department,
        'officerName': officerName,
        'completionTime': completionTime.toIso8601String(),
        'resolutionComment': resolutionComment,
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      };

      if (kIsWeb) {
        // Use localStorage for web
        final existingNotifications =
            WebStorage.getList('admin_notifications') ?? [];
        existingNotifications.add(notification);
        WebStorage.setList('admin_notifications', existingNotifications);
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        final existingNotifications =
            prefs.getStringList('admin_notifications') ?? [];
        existingNotifications.add(jsonEncode(notification));
        await prefs.setStringList('admin_notifications', existingNotifications);
      }
    } catch (e) {
      print('Error creating completion notification: $e');
      // Don't throw - this is supplementary functionality
    }
  }

  // Get completion notifications for admin
  Future<List<Map<String, dynamic>>> getCompletionNotifications() async {
    try {
      List<Map<String, dynamic>> notifications = [];

      if (kIsWeb) {
        // Use localStorage for web
        final notificationsList =
            WebStorage.getList('admin_notifications') ?? [];
        notifications = notificationsList
            .where((item) => item is Map<String, dynamic>)
            .cast<Map<String, dynamic>>()
            .toList();
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        final notificationStrings =
            prefs.getStringList('admin_notifications') ?? [];
        notifications = notificationStrings
            .map((str) => jsonDecode(str) as Map<String, dynamic>)
            .toList();
      }

      return notifications
          .where((notification) => notification['type'] == 'completion')
          .toList()
        ..sort(
          (a, b) => b['createdAt'].compareTo(a['createdAt']),
        ); // Most recent first
    } catch (e) {
      print('Error getting completion notifications: $e');
      return [];
    }
  }

  // ===== REGISTRATION REQUEST METHODS =====

  // Submit a new registration request (officers require admin approval)
  Future<bool> submitRegistrationRequest(RegistrationRequest request) async {
    try {
      RegistrationRequest finalRequest;

      if (request.userType == 'officer') {
        // Officers require admin approval - keep as pending
        finalRequest = request; // Keep original status (notified)
      } else {
        // Public users are auto-approved
        finalRequest = request.copyWith(
          status: RegistrationStatus.registered,
          responseDate: DateTime.now(),
          adminResponse: 'Account automatically activated',
        );
      }

      // Store the registration record
      if (kIsWeb) {
        // Use localStorage for web
        final existingRequests =
            WebStorage.getList('registration_requests') ?? [];
        existingRequests.add(jsonEncode(finalRequest.toJson()));
        WebStorage.setList('registration_requests', existingRequests);
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        final existingRequests =
            prefs.getStringList(_registrationRequestsKey) ?? [];
        existingRequests.add(jsonEncode(finalRequest.toJson()));
        await prefs.setStringList(_registrationRequestsKey, existingRequests);
      }

      // Create notification for admin
      await _createRegistrationNotification(finalRequest);

      return true;
    } catch (e) {
      print('Error submitting registration request: $e');
      return false;
    }
  }

  // Create notification for admin about new registration
  Future<void> _createRegistrationNotification(
    RegistrationRequest request,
  ) async {
    try {
      final notification = {
        'id': 'new_user_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'new_registration',
        'title': 'New User Registration',
        'message':
            '${request.fullName} has registered as a ${request.userType}',
        'userDetails': {
          'name': request.fullName,
          'email': request.email,
          'phone': request.phone,
          'userType': request.userType,
          'department': request.department,
          'designation': request.designation,
          'registeredAt': request.requestDate.toIso8601String(),
        },
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
        'priority': 'info',
      };

      if (kIsWeb) {
        final existingNotifications =
            WebStorage.getList('admin_notifications') ?? [];
        existingNotifications.add(jsonEncode(notification));
        WebStorage.setList('admin_notifications', existingNotifications);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final existingNotifications =
            prefs.getStringList('admin_notifications') ?? [];
        existingNotifications.add(jsonEncode(notification));
        await prefs.setStringList('admin_notifications', existingNotifications);
      }
    } catch (e) {
      print('Error creating registration notification: $e');
    }
  }

  // Get all registration requests
  Future<List<RegistrationRequest>> getAllRegistrationRequests() async {
    try {
      List<String> requestStrings;

      if (kIsWeb) {
        // Use localStorage for web
        requestStrings =
            WebStorage.getList('registration_requests')?.cast<String>() ?? [];
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        requestStrings = prefs.getStringList(_registrationRequestsKey) ?? [];
      }

      return requestStrings
          .map((str) => RegistrationRequest.fromJson(jsonDecode(str)))
          .toList()
        ..sort(
          (a, b) => b.requestDate.compareTo(a.requestDate),
        ); // Most recent first
    } catch (e) {
      print('Error getting registration requests: $e');
      return [];
    }
  }

  // Get new registration notifications (for admin review)
  Future<List<RegistrationRequest>> getNewRegistrationNotifications() async {
    final allRequests = await getAllRegistrationRequests();
    return allRequests
        .where((request) => request.isNotified || request.isRegistered)
        .toList();
  }

  // Mark registration notification as read
  Future<bool> markRegistrationNotificationRead(String requestId) async {
    try {
      final allRequests = await getAllRegistrationRequests();
      final requestIndex = allRequests.indexWhere((r) => r.id == requestId);

      if (requestIndex == -1) {
        print('Registration request not found: $requestId');
        return false;
      }

      // Update the request to notified status (marking as read)
      final updatedRequest = allRequests[requestIndex].copyWith(
        status: RegistrationStatus.notified,
      );

      allRequests[requestIndex] = updatedRequest;

      // Save back to storage
      final requestStrings = allRequests
          .map((r) => jsonEncode(r.toJson()))
          .toList();

      if (kIsWeb) {
        WebStorage.setList('registration_requests', requestStrings);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_registrationRequestsKey, requestStrings);
      }

      return true;
    } catch (e) {
      print('Error marking registration notification as read: $e');
      return false;
    }
  }

  // Archive registration notification
  Future<bool> archiveRegistrationNotification(String requestId) async {
    try {
      final allRequests = await getAllRegistrationRequests();
      final requestIndex = allRequests.indexWhere((r) => r.id == requestId);

      if (requestIndex == -1) {
        print('Registration request not found: $requestId');
        return false;
      }

      // Update the request to archived status
      final updatedRequest = allRequests[requestIndex].copyWith(
        status: RegistrationStatus.archived,
      );

      allRequests[requestIndex] = updatedRequest;

      // Save back to storage
      final requestStrings = allRequests
          .map((r) => jsonEncode(r.toJson()))
          .toList();

      if (kIsWeb) {
        WebStorage.setList('registration_requests', requestStrings);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_registrationRequestsKey, requestStrings);
      }

      return true;
    } catch (e) {
      print('Error archiving registration notification: $e');
      return false;
    }
  }

  // Approve officer registration request
  Future<bool> approveOfficerRegistration(
    String requestId,
    String adminComment,
  ) async {
    try {
      final allRequests = await getAllRegistrationRequests();
      final requestIndex = allRequests.indexWhere((r) => r.id == requestId);

      if (requestIndex == -1) {
        print('Registration request not found: $requestId');
        return false;
      }

      final request = allRequests[requestIndex];

      // Only approve officer requests that are pending
      if (request.userType != 'officer') {
        print('Only officer registrations can be approved through this method');
        return false;
      }

      // Update the request to approved status
      final updatedRequest = request.copyWith(
        status: RegistrationStatus.registered,
        responseDate: DateTime.now(),
        adminResponse: adminComment.isNotEmpty
            ? adminComment
            : 'Officer registration approved by admin',
      );

      allRequests[requestIndex] = updatedRequest;

      // Save back to storage
      final requestStrings = allRequests
          .map((r) => jsonEncode(r.toJson()))
          .toList();

      if (kIsWeb) {
        WebStorage.setList('registration_requests', requestStrings);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_registrationRequestsKey, requestStrings);
      }

      // Send approval notification to the officer
      await _sendOfficerApprovalNotification(updatedRequest);

      return true;
    } catch (e) {
      print('Error approving officer registration: $e');
      return false;
    }
  }

  // Reject officer registration request
  Future<bool> rejectOfficerRegistration(
    String requestId,
    String rejectionReason,
  ) async {
    try {
      final allRequests = await getAllRegistrationRequests();
      final requestIndex = allRequests.indexWhere((r) => r.id == requestId);

      if (requestIndex == -1) {
        print('Registration request not found: $requestId');
        return false;
      }

      final request = allRequests[requestIndex];

      // Only reject officer requests that are pending
      if (request.userType != 'officer') {
        print('Only officer registrations can be rejected through this method');
        return false;
      }

      // Update the request to archived status with rejection reason
      final updatedRequest = request.copyWith(
        status: RegistrationStatus.archived,
        responseDate: DateTime.now(),
        adminResponse: rejectionReason.isNotEmpty
            ? rejectionReason
            : 'Officer registration rejected by admin',
      );

      allRequests[requestIndex] = updatedRequest;

      // Save back to storage
      final requestStrings = allRequests
          .map((r) => jsonEncode(r.toJson()))
          .toList();

      if (kIsWeb) {
        WebStorage.setList('registration_requests', requestStrings);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_registrationRequestsKey, requestStrings);
      }

      // Send rejection notification to the officer
      await _sendOfficerRejectionNotification(updatedRequest);

      return true;
    } catch (e) {
      print('Error rejecting officer registration: $e');
      return false;
    }
  }

  // Send approval notification to officer
  Future<void> _sendOfficerApprovalNotification(
    RegistrationRequest request,
  ) async {
    try {
      final notification = {
        'id': 'officer_approved_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'officer_approval',
        'title': '🎉 Officer Registration Approved',
        'message':
            'Your officer registration has been approved! You can now log in to access your officer dashboard.',
        'userEmail': request.email,
        'targetRoles': ['officer'],
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
        'priority': 'high',
      };

      await _storeNotification(notification);
    } catch (e) {
      print('Error sending officer approval notification: $e');
    }
  }

  // Send rejection notification to officer
  Future<void> _sendOfficerRejectionNotification(
    RegistrationRequest request,
  ) async {
    try {
      final notification = {
        'id': 'officer_rejected_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'officer_rejection',
        'title': '❌ Officer Registration Not Approved',
        'message':
            'Your officer registration request has been reviewed and could not be approved at this time. Reason: ${request.adminResponse}',
        'userEmail': request.email,
        'targetRoles': ['officer'],
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
        'priority': 'high',
      };

      await _storeNotification(notification);
    } catch (e) {
      print('Error sending officer rejection notification: $e');
    }
  }

  // Helper method to store notifications
  Future<void> _storeNotification(Map<String, dynamic> notification) async {
    try {
      if (kIsWeb) {
        final existingNotifications =
            WebStorage.getList('civic_welfare_notifications') ?? [];
        existingNotifications.add(jsonEncode(notification));
        WebStorage.setList(
          'civic_welfare_notifications',
          existingNotifications,
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        final existingNotifications =
            prefs.getStringList(_notificationsKey) ?? [];
        existingNotifications.add(jsonEncode(notification));
        await prefs.setStringList(_notificationsKey, existingNotifications);
      }
    } catch (e) {
      print('Error storing notification: $e');
    }
  }

  // Validate user login with email and password
  Future<RegistrationRequest?> validateUserLogin(
    String email,
    String password,
  ) async {
    try {
      final allRequests = await getAllRegistrationRequests();

      // Find user with matching email and registered status
      final user = allRequests
          .where(
            (request) =>
                request.email.toLowerCase() == email.toLowerCase() &&
                request.isRegistered,
          )
          .firstWhere(
            (request) => request.password == password,
            orElse: () => throw StateError('User not found'),
          );

      return user;
    } catch (e) {
      print('Error validating user login: $e');
      return null;
    }
  }

  // Check if user email is in approved users list (legacy method for existing data)
  Future<bool> isUserApproved(String email) async {
    try {
      // First check new registration system
      final registeredUser = await getRegistrationRequestByEmail(email);
      if (registeredUser != null && registeredUser.isRegistered) {
        return true;
      }

      // Fallback to old approved users list for existing data
      List<String> approvedUserStrings;

      if (kIsWeb) {
        approvedUserStrings =
            WebStorage.getList('approved_users')?.cast<String>() ?? [];
      } else {
        final prefs = await SharedPreferences.getInstance();
        approvedUserStrings = prefs.getStringList(_approvedUsersKey) ?? [];
      }

      final approvedUsers = approvedUserStrings
          .map((str) => jsonDecode(str) as Map<String, dynamic>)
          .toList();

      return approvedUsers.any((user) => user['email'] == email);
    } catch (e) {
      print('Error checking user approval status: $e');
      return false;
    }
  }

  // Get approved user details by email
  Future<Map<String, dynamic>?> getApprovedUserDetails(String email) async {
    try {
      List<String> approvedUserStrings;

      if (kIsWeb) {
        approvedUserStrings =
            WebStorage.getList('approved_users')?.cast<String>() ?? [];
      } else {
        final prefs = await SharedPreferences.getInstance();
        approvedUserStrings = prefs.getStringList(_approvedUsersKey) ?? [];
      }

      final approvedUsers = approvedUserStrings
          .map((str) => jsonDecode(str) as Map<String, dynamic>)
          .toList();

      return approvedUsers.firstWhere(
        (user) => user['email'] == email,
        orElse: () => {},
      );
    } catch (e) {
      print('Error getting approved user details: $e');
      return null;
    }
  }

  // Check if email already has a registration
  Future<bool> hasExistingRegistration(String email) async {
    final allRequests = await getAllRegistrationRequests();
    return allRequests.any((request) => request.email == email);
  }

  // Get registration request by email
  Future<RegistrationRequest?> getRegistrationRequestByEmail(
    String email,
  ) async {
    final allRequests = await getAllRegistrationRequests();
    try {
      return allRequests.firstWhere((request) => request.email == email);
    } catch (e) {
      return null;
    }
  }

  // Get current user's registration data from session
  Future<RegistrationRequest?> getCurrentUserRegistrationData() async {
    try {
      final session = await getCurrentUserSession();
      if (session == null || session['userEmail'] == null) {
        print('❌ No user session found');
        return null;
      }

      final userEmail = session['userEmail']!;
      print('🔍 Getting registration data for email: $userEmail');

      final registrationData = await getRegistrationRequestByEmail(userEmail);
      if (registrationData != null) {
        print('✅ Found registration data for: ${registrationData.fullName}');
        print('   Department: ${registrationData.department}');
        print('   User Type: ${registrationData.userType}');
      } else {
        print('❌ No registration data found for: $userEmail');
      }

      return registrationData;
    } catch (e) {
      print('❌ Error getting current user registration data: $e');
      return null;
    }
  }

  // === PASSWORD RESET METHODS ===

  // Submit password reset request
  Future<bool> submitPasswordResetRequest(PasswordResetRequest request) async {
    try {
      List<String> existingRequests;

      if (kIsWeb) {
        existingRequests =
            WebStorage.getList('password_reset_requests')?.cast<String>() ?? [];
      } else {
        final prefs = await SharedPreferences.getInstance();
        existingRequests = prefs.getStringList(_passwordResetRequestsKey) ?? [];
      }

      // Add new request
      existingRequests.add(jsonEncode(request.toJson()));

      // Save back to storage
      if (kIsWeb) {
        WebStorage.setList('password_reset_requests', existingRequests);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_passwordResetRequestsKey, existingRequests);
      }

      return true;
    } catch (e) {
      print('Error submitting password reset request: $e');
      return false;
    }
  }

  // Get all password reset requests
  Future<List<PasswordResetRequest>> getAllPasswordResetRequests() async {
    try {
      List<String> requestStrings;

      if (kIsWeb) {
        requestStrings =
            WebStorage.getList('password_reset_requests')?.cast<String>() ?? [];
      } else {
        final prefs = await SharedPreferences.getInstance();
        requestStrings = prefs.getStringList(_passwordResetRequestsKey) ?? [];
      }

      return requestStrings
          .map((str) => PasswordResetRequest.fromJson(jsonDecode(str)))
          .toList()
        ..sort(
          (a, b) => b.requestDate.compareTo(a.requestDate),
        ); // Most recent first
    } catch (e) {
      print('Error getting password reset requests: $e');
      return [];
    }
  }

  // Get pending password reset requests (for admin)
  Future<List<PasswordResetRequest>> getPendingPasswordResetRequests() async {
    final allRequests = await getAllPasswordResetRequests();
    return allRequests.where((request) => request.isPending).toList();
  }

  // Check if user has pending password reset request
  Future<bool> hasPendingPasswordResetRequest(String email) async {
    final allRequests = await getAllPasswordResetRequests();
    return allRequests.any(
      (request) =>
          request.email.toLowerCase() == email.toLowerCase() &&
          request.isPending,
    );
  }

  // Update password reset request status (approve/reject)
  Future<bool> updatePasswordResetRequestStatus(
    String requestId,
    PasswordResetStatus newStatus,
    String adminResponse,
    String adminName,
  ) async {
    try {
      final allRequests = await getAllPasswordResetRequests();
      final requestIndex = allRequests.indexWhere((r) => r.id == requestId);

      if (requestIndex == -1) {
        print('Password reset request not found: $requestId');
        return false;
      }

      // Update the request
      final updatedRequest = allRequests[requestIndex].copyWith(
        status: newStatus,
        adminResponse: adminResponse,
        responseDate: DateTime.now(),
        respondedBy: adminName,
      );

      allRequests[requestIndex] = updatedRequest;

      // Save back to storage
      final requestStrings = allRequests
          .map((r) => jsonEncode(r.toJson()))
          .toList();

      if (kIsWeb) {
        WebStorage.setList('password_reset_requests', requestStrings);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_passwordResetRequestsKey, requestStrings);
      }

      return true;
    } catch (e) {
      print('Error updating password reset request: $e');
      return false;
    }
  }

  // Get approved password reset request by email
  Future<PasswordResetRequest?> getApprovedPasswordResetRequest(
    String email,
  ) async {
    final allRequests = await getAllPasswordResetRequests();
    try {
      return allRequests.firstWhere(
        (request) =>
            request.email.toLowerCase() == email.toLowerCase() &&
            request.isApproved,
      );
    } catch (e) {
      return null;
    }
  }

  // Complete password reset (update user's password)
  Future<bool> completePasswordReset(
    String email,
    String newPassword,
    String resetRequestId,
  ) async {
    try {
      // Update the user's password in registration data
      final allRegistrations = await getAllRegistrationRequests();
      final userIndex = allRegistrations.indexWhere(
        (r) => r.email.toLowerCase() == email.toLowerCase(),
      );

      if (userIndex == -1) {
        print('User not found for password reset: $email');
        return false;
      }

      // Update user's password
      final updatedUser = allRegistrations[userIndex].copyWith(
        password: newPassword,
      );
      allRegistrations[userIndex] = updatedUser;

      // Save updated registration data
      final registrationStrings = allRegistrations
          .map((r) => jsonEncode(r.toJson()))
          .toList();

      if (kIsWeb) {
        WebStorage.setList('registration_requests', registrationStrings);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _registrationRequestsKey,
          registrationStrings,
        );
      }

      // Mark password reset request as completed
      final allResetRequests = await getAllPasswordResetRequests();
      final resetIndex = allResetRequests.indexWhere(
        (r) => r.id == resetRequestId,
      );

      if (resetIndex != -1) {
        final completedRequest = allResetRequests[resetIndex].copyWith(
          status: PasswordResetStatus.completed,
          completedDate: DateTime.now(),
        );
        allResetRequests[resetIndex] = completedRequest;

        // Save updated reset requests
        final resetStrings = allResetRequests
            .map((r) => jsonEncode(r.toJson()))
            .toList();

        if (kIsWeb) {
          WebStorage.setList('password_reset_requests', resetStrings);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(_passwordResetRequestsKey, resetStrings);
        }
      }

      return true;
    } catch (e) {
      print('Error completing password reset: $e');
      return false;
    }
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      if (kIsWeb) {
        // Use localStorage for web
        WebStorage.remove('reports');
        WebStorage.remove('notifications');
        WebStorage.remove('user_session');
        WebStorage.remove('admin_notifications');
        WebStorage.remove('registration_requests');
        WebStorage.remove('approved_users');
      } else {
        // Use SharedPreferences for mobile
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_reportsKey);
        await prefs.remove(_notificationsKey);
        await prefs.remove('admin_notifications');
        await prefs.remove(_registrationRequestsKey);
        await prefs.remove(_approvedUsersKey);
        await clearUserSession();
      }
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }

  // Draft report management methods
  Future<void> saveDraftReport(Map<String, dynamic> draftData) async {
    try {
      if (kIsWeb) {
        WebStorage.setJson('draft_report', draftData);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('draft_report', jsonEncode(draftData));
      }
      print('Draft report saved');
    } catch (e) {
      print('Error saving draft report: $e');
    }
  }

  Future<Map<String, dynamic>?> getDraftReport() async {
    try {
      if (kIsWeb) {
        final draft = WebStorage.getJson('draft_report');
        return draft?.cast<String, dynamic>();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final draftString = prefs.getString('draft_report');
        if (draftString != null) {
          return jsonDecode(draftString);
        }
      }
      return null;
    } catch (e) {
      print('Error getting draft report: $e');
      return null;
    }
  }

  // NEW: Backend synchronization methods

  /// Test if backend is available
  Future<bool> testBackendConnection() async {
    return await BackendApiService.testConnection();
  }

  /// Sync all local data to backend database
  Future<bool> syncToBackend() async {
    try {
      print('🔄 Starting sync to backend database...');

      // Test connection first
      final isConnected = await testBackendConnection();
      if (!isConnected) {
        print('❌ Backend not available for sync');
        return false;
      }

      // Get all local reports
      final reports = await getAllReports();
      if (reports.isEmpty) {
        print('ℹ️ No local reports to sync');
        return true;
      }

      // Convert reports to backend format
      final reportsData = reports.map((report) => report.toJson()).toList();

      // Sync to backend
      final success = await BackendApiService.syncLocalDataToBackend(
        reportsData,
      );

      if (success) {
        print('✅ Successfully synced ${reports.length} reports to backend');
      } else {
        print('❌ Failed to sync reports to backend');
      }

      return success;
    } catch (e) {
      print('❌ Error during backend sync: $e');
      return false;
    }
  }

  /// Get reports from backend database
  Future<List<Map<String, dynamic>>> getBackendReports() async {
    try {
      return await BackendApiService.getAllReports();
    } catch (e) {
      print('❌ Error fetching backend reports: $e');
      return [];
    }
  }

  /// Initialize backend connection and sync on app start
  Future<void> initializeBackendSync() async {
    try {
      print('🔍 Initializing backend synchronization...');

      final isConnected = await testBackendConnection();
      if (isConnected) {
        print('✅ Backend database connected successfully');

        // Auto-sync local data to backend
        await syncToBackend();
      } else {
        print('⚠️ Backend database not available - using local storage only');
      }
    } catch (e) {
      print('❌ Error initializing backend sync: $e');
    }
  }

  Future<void> clearDraftReport() async {
    try {
      if (kIsWeb) {
        WebStorage.remove('draft_report');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('draft_report');
      }
      print('Draft report cleared');
    } catch (e) {
      print('Error clearing draft report: $e');
    }
  }

  // NEED REQUEST MANAGEMENT
  static const String _needRequestsKey = 'civic_welfare_need_requests';

  /// Save a need request to local storage
  Future<void> saveNeedRequest(NeedRequest needRequest) async {
    try {
      print('💾 Saving need request: ${needRequest.title}');

      // Get existing need requests
      final requests = await getAllNeedRequests();

      // Add new request
      requests.add(needRequest);

      // Save back to storage
      final requestMaps = requests.map((r) => r.toJson()).toList();

      if (kIsWeb) {
        WebStorage.setString(_needRequestsKey, jsonEncode(requestMaps));
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_needRequestsKey, jsonEncode(requestMaps));
      }

      print('✅ Need request saved successfully');
    } catch (e) {
      print('❌ Error saving need request: $e');
      rethrow;
    }
  }

  /// Get all need requests from storage
  Future<List<NeedRequest>> getAllNeedRequests() async {
    try {
      String? requestsJson;

      if (kIsWeb) {
        requestsJson = WebStorage.getString(_needRequestsKey);
      } else {
        final prefs = await SharedPreferences.getInstance();
        requestsJson = prefs.getString(_needRequestsKey);
      }

      if (requestsJson == null || requestsJson.isEmpty) {
        return [];
      }

      final List<dynamic> requestMaps = jsonDecode(requestsJson);
      return requestMaps.map((map) => NeedRequest.fromJson(map)).toList();
    } catch (e) {
      print('Error loading need requests: $e');
      return [];
    }
  }

  /// Get need requests by status
  Future<List<NeedRequest>> getNeedRequestsByStatus(NeedStatus status) async {
    final allRequests = await getAllNeedRequests();
    return allRequests.where((request) => request.status == status).toList();
  }

  /// Update need request status (for admin use)
  Future<void> updateNeedRequestStatus(
    String requestId,
    NeedStatus newStatus, {
    String? adminNotes,
    int? estimatedImplementationDays,
    String? implementationTimeline,
  }) async {
    try {
      final requests = await getAllNeedRequests();
      final requestIndex = requests.indexWhere((r) => r.id == requestId);

      if (requestIndex != -1) {
        final originalRequest = requests[requestIndex];

        // Calculate expected completion date if implementation days provided
        DateTime? expectedCompletionDate;
        if (estimatedImplementationDays != null) {
          expectedCompletionDate = DateTime.now().add(
            Duration(days: estimatedImplementationDays),
          );
        }

        final updatedRequest = originalRequest.copyWith(
          status: newStatus,
          adminNotes: adminNotes,
          updatedAt: DateTime.now(),
          estimatedImplementationDays: estimatedImplementationDays,
          expectedCompletionDate: expectedCompletionDate,
          implementationTimeline: implementationTimeline,
        );

        requests[requestIndex] = updatedRequest;

        // Save back to storage
        final requestMaps = requests.map((r) => r.toJson()).toList();

        if (kIsWeb) {
          WebStorage.setString(_needRequestsKey, jsonEncode(requestMaps));
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_needRequestsKey, jsonEncode(requestMaps));
        }

        // Send notification to the citizen if status is approved
        if (newStatus == NeedStatus.approved) {
          await _sendApprovalNotification(updatedRequest);
        }

        print('✅ Need request status updated to $newStatus');
      }
    } catch (e) {
      print('❌ Error updating need request status: $e');
      rethrow;
    }
  }

  /// Send approval notification to citizen
  Future<void> _sendApprovalNotification(NeedRequest request) async {
    try {
      final timelineText =
          request.implementationTimeline ??
          (request.estimatedImplementationDays != null
              ? 'Expected completion in ${request.estimatedImplementationDays} days'
              : 'Timeline to be determined');

      // Use the standard notification creation method
      await _createNotification(
        title: '🎉 Facility Request Approved!',
        message:
            'Your request for "${request.title}" has been approved. $timelineText',
        reportId: request.id,
        targetRoles: [
          'public',
          'citizen',
        ], // Target all public users and citizens
        type: 'NotificationType.needApproval', // Use the enum string format
      );

      print('📬 Approval notification sent for request: ${request.title}');
    } catch (e) {
      print('❌ Error sending approval notification: $e');
    }
  }

  // FEEDBACK MANAGEMENT METHODS

  /// Save feedback to storage
  Future<bool> saveFeedback(Feedback feedback) async {
    try {
      print('💬 Saving feedback for report: ${feedback.reportId}');

      // Save to local storage
      print('📱 [LOCAL] Saving feedback locally...');
      await _saveFeedbackLocal(feedback);

      return true;
    } catch (e) {
      print('❌ Error saving feedback: $e');
      return false;
    }
  }

  /// Save feedback locally
  Future<void> _saveFeedbackLocal(Feedback feedback) async {
    try {
      final feedbackList = await getAllFeedback();

      // Remove existing feedback for the same report from same user (if any)
      feedbackList.removeWhere(
        (f) => f.reportId == feedback.reportId && f.userId == feedback.userId,
      );

      // Add new feedback
      feedbackList.add(feedback);

      // Save to storage
      final jsonData = feedbackList.map((f) => f.toJson()).toList();

      if (kIsWeb) {
        WebStorage.setString(_feedbackKey, jsonEncode(jsonData));
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_feedbackKey, jsonEncode(jsonData));
      }

      print('✅ [LOCAL] Feedback saved locally');
    } catch (e) {
      print('❌ Error saving feedback locally: $e');
      rethrow;
    }
  }

  /// Get all feedback
  Future<List<Feedback>> getAllFeedback() async {
    try {
      // Load from local storage
      return await _getFeedbackLocal();
    } catch (e) {
      print('❌ Error getting feedback: $e');
      return [];
    }
  }

  /// Get feedback from local storage
  Future<List<Feedback>> _getFeedbackLocal() async {
    try {
      print('🔍 [LOCAL] Loading feedback from local storage...');

      String? jsonString;
      if (kIsWeb) {
        jsonString = WebStorage.getString(_feedbackKey);
      } else {
        final prefs = await SharedPreferences.getInstance();
        jsonString = prefs.getString(_feedbackKey);
      }

      if (jsonString == null || jsonString.isEmpty) {
        print('🔍 [LOCAL] No feedback data found in localStorage');
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final feedback = jsonList
          .map((json) => Feedback.fromJson(json as Map<String, dynamic>))
          .toList();

      print(
        '🔍 [LOCAL] Successfully parsed ${feedback.length} feedback items from localStorage',
      );
      return feedback;
    } catch (e) {
      print('❌ Error loading feedback from local storage: $e');
      return [];
    }
  }

  /// Get feedback for a specific report
  Future<List<Feedback>> getFeedbackForReport(String reportId) async {
    try {
      final allFeedback = await getAllFeedback();
      return allFeedback.where((f) => f.reportId == reportId).toList();
    } catch (e) {
      print('❌ Error getting feedback for report: $e');
      return [];
    }
  }

  /// Get feedback by a specific user
  Future<List<Feedback>> getFeedbackByUser(String userId) async {
    try {
      final allFeedback = await getAllFeedback();
      return allFeedback.where((f) => f.userId == userId).toList();
    } catch (e) {
      print('❌ Error getting feedback by user: $e');
      return [];
    }
  }

  /// Check if user has already provided feedback for a report
  Future<bool> hasUserProvidedFeedback(String reportId, String userId) async {
    try {
      final feedback = await getFeedbackForReport(reportId);
      return feedback.any((f) => f.userId == userId);
    } catch (e) {
      print('❌ Error checking user feedback: $e');
      return false;
    }
  }

  /// Get feedback statistics for admin dashboard
  Future<Map<String, dynamic>> getFeedbackStatistics() async {
    try {
      final allFeedback = await getAllFeedback();

      if (allFeedback.isEmpty) {
        return {
          'total': 0,
          'averageRating': 0.0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          'positive': 0,
          'neutral': 0,
          'negative': 0,
          'recentFeedback': <Feedback>[],
        };
      }

      // Calculate statistics
      final total = allFeedback.length;
      final totalRating = allFeedback.fold(0, (sum, f) => sum + f.rating);
      final averageRating = totalRating / total;

      // Rating distribution
      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final feedback in allFeedback) {
        ratingDistribution[feedback.rating] =
            (ratingDistribution[feedback.rating] ?? 0) + 1;
      }

      // Sentiment analysis
      final positive = allFeedback.where((f) => f.isPositive).length;
      final neutral = allFeedback.where((f) => f.isNeutral).length;
      final negative = allFeedback.where((f) => f.isNegative).length;

      // Recent feedback (last 10)
      final recentFeedback = allFeedback
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recent = recentFeedback.take(10).toList();

      return {
        'total': total,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
        'positive': positive,
        'neutral': neutral,
        'negative': negative,
        'recentFeedback': recent,
      };
    } catch (e) {
      print('❌ Error getting feedback statistics: $e');
      return {
        'total': 0,
        'averageRating': 0.0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        'positive': 0,
        'neutral': 0,
        'negative': 0,
        'recentFeedback': <Feedback>[],
      };
    }
  }

  /// Delete feedback (admin only)
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      // Delete from local storage
      await _deleteFeedbackLocal(feedbackId);
      return true;
    } catch (e) {
      print('❌ Error deleting feedback: $e');
      return false;
    }
  }

  /// Delete feedback locally
  Future<void> _deleteFeedbackLocal(String feedbackId) async {
    try {
      final feedbackList = await getAllFeedback();
      feedbackList.removeWhere((f) => f.id == feedbackId);

      final jsonData = feedbackList.map((f) => f.toJson()).toList();

      if (kIsWeb) {
        WebStorage.setString(_feedbackKey, jsonEncode(jsonData));
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_feedbackKey, jsonEncode(jsonData));
      }

      print('✅ [LOCAL] Feedback deleted locally');
    } catch (e) {
      print('❌ Error deleting feedback locally: $e');
      rethrow;
    }
  }

  // ========================
  // CERTIFICATE MANAGEMENT
  // ========================

  /// Generates and saves a certificate when a report is resolved
  Future<Certificate> generateCertificateForResolvedReport(Report report) async {
    try {
      final session = await getCurrentUserSession();
      final citizenName = session?['name'] ?? 'Unknown Citizen';
      final citizenEmail = session?['email'] ?? '';
      final citizenId = session?['id'] ?? '';

      final certificate = Certificate.createCivicEngagementCertificate(
        reportId: report.id,
        reportTitle: report.title,
        reportCategory: report.category,
        reportDepartment: report.department,
        citizenId: citizenId,
        citizenName: citizenName,
        citizenEmail: citizenEmail,
      );

      await _saveCertificate(certificate);
      
      print('🏆 Certificate generated for resolved report: ${report.id}');
      print('   Points awarded: ${certificate.pointsAwarded}');
      print('   Certificate ID: ${certificate.id}');
      
      return certificate;
    } catch (e) {
      print('❌ Error generating certificate: $e');
      rethrow;
    }
  }

  /// Saves certificate to local storage
  Future<void> _saveCertificate(Certificate certificate) async {
    try {
      final certificates = await getAllCertificates();
      certificates.add(certificate);

      final jsonData = certificates.map((cert) => cert.toJson()).toList();

      if (kIsWeb) {
        WebStorage.setString(_certificatesKey, jsonEncode(jsonData));
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_certificatesKey, jsonEncode(jsonData));
      }

      print('✅ Certificate saved locally: ${certificate.id}');
    } catch (e) {
      print('❌ Error saving certificate: $e');
      rethrow;
    }
  }

  /// Gets all certificates for current user
  Future<List<Certificate>> getAllCertificates() async {
    try {
      final session = await getCurrentUserSession();
      final userEmail = session?['email'] ?? '';

      String? jsonString;
      if (kIsWeb) {
        jsonString = WebStorage.getString(_certificatesKey);
      } else {
        final prefs = await SharedPreferences.getInstance();
        jsonString = prefs.getString(_certificatesKey);
      }

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonData = jsonDecode(jsonString);
      final allCertificates = jsonData
          .map((json) => Certificate.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter certificates for current user
      final userCertificates = allCertificates
          .where((cert) => cert.citizenEmail == userEmail)
          .toList();

      // Sort by issued date (newest first)
      userCertificates.sort((a, b) => b.issuedDate.compareTo(a.issuedDate));

      return userCertificates;
    } catch (e) {
      print('❌ Error loading certificates: $e');
      return [];
    }
  }

  /// Gets certificate statistics for current user
  Future<CitizenGamificationStats> getCitizenGamificationStats() async {
    try {
      final session = await getCurrentUserSession();
      final citizenName = session?['name'] ?? 'Unknown Citizen';
      final citizenId = session?['id'] ?? '';
      
      final certificates = await getAllCertificates();
      
      if (certificates.isEmpty) {
        return CitizenGamificationStats(
          citizenId: citizenId,
          citizenName: citizenName,
          totalCertificates: 0,
          totalPoints: 0,
          currentLevel: 'Bronze Citizen',
        );
      }

      final totalPoints = certificates.fold<int>(
        0, 
        (sum, cert) => sum + cert.pointsAwarded,
      );

      final categories = certificates
          .map((cert) => cert.reportCategory)
          .toSet()
          .toList();

      final stats = CitizenGamificationStats(
        citizenId: citizenId,
        citizenName: citizenName,
        totalCertificates: certificates.length,
        totalPoints: totalPoints,
        totalReportsResolved: certificates.length,
        categories: categories,
        currentLevel: _calculateLevelFromPoints(totalPoints),
        lastActivity: certificates.isNotEmpty ? certificates.first.issuedDate : DateTime.now(),
      );

      return stats;
    } catch (e) {
      print('❌ Error calculating gamification stats: $e');
      final session = await getCurrentUserSession();
      return CitizenGamificationStats(
        citizenId: session?['id'] ?? '',
        citizenName: session?['name'] ?? 'Unknown Citizen',
        totalCertificates: 0,
        totalPoints: 0,
        currentLevel: 'Bronze Citizen',
      );
    }
  }

  /// Calculate citizen level from points
  String _calculateLevelFromPoints(int points) {
    if (points >= 200) return '🏆 Platinum Citizen';
    if (points >= 100) return '🥇 Gold Citizen';
    if (points >= 50) return '🥈 Silver Citizen';
    return '🥉 Bronze Citizen';
  }

  /// Gets all certificates for admin view (all users)
  Future<List<Certificate>> getAllCertificatesForAdmin() async {
    try {
      String? jsonString;
      if (kIsWeb) {
        jsonString = WebStorage.getString(_certificatesKey);
      } else {
        final prefs = await SharedPreferences.getInstance();
        jsonString = prefs.getString(_certificatesKey);
      }

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonData = jsonDecode(jsonString);
      final certificates = jsonData
          .map((json) => Certificate.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by issued date (newest first)  
      certificates.sort((a, b) => b.issuedDate.compareTo(a.issuedDate));

      return certificates;
    } catch (e) {
      print('❌ Error loading admin certificates: $e');
      return [];
    }
  }

  /// Gets certificate analytics for admin dashboard
  Future<Map<String, dynamic>> getCertificateAnalytics() async {
    try {
      final certificates = await getAllCertificatesForAdmin();
      
      if (certificates.isEmpty) {
        return {
          'totalCertificates': 0,
          'totalPoints': 0,
          'uniqueCitizens': 0,
          'categoryBreakdown': <String, int>{},
          'levelDistribution': <String, int>{},
          'recentCertificates': <Certificate>[],
        };
      }

      final totalPoints = certificates.fold<int>(
        0, 
        (sum, cert) => sum + cert.pointsAwarded,
      );

      final uniqueCitizens = certificates
          .map((cert) => cert.citizenEmail)
          .toSet()
          .length;

      final categoryBreakdown = <String, int>{};
      final levelDistribution = <String, int>{};

      for (final cert in certificates) {
        categoryBreakdown[cert.reportCategory] = 
            (categoryBreakdown[cert.reportCategory] ?? 0) + 1;
        
        final levelName = _calculateLevelFromPoints(cert.pointsAwarded);
        levelDistribution[levelName] = 
            (levelDistribution[levelName] ?? 0) + 1;
      }

      final recentCertificates = certificates.take(10).toList();

      return {
        'totalCertificates': certificates.length,
        'totalPoints': totalPoints,
        'uniqueCitizens': uniqueCitizens,
        'categoryBreakdown': categoryBreakdown,
        'levelDistribution': levelDistribution,
        'recentCertificates': recentCertificates,
      };
    } catch (e) {
      print('❌ Error calculating certificate analytics: $e');
      return {
        'totalCertificates': 0,
        'totalPoints': 0,
        'uniqueCitizens': 0,
        'categoryBreakdown': <String, int>{},
        'levelDistribution': <String, int>{},
        'recentCertificates': <Certificate>[],
      };
    }
  }

  /// Checks if user has earned a new level and returns achievement info
  Future<Map<String, dynamic>?> checkForLevelAchievement(String userEmail) async {
    try {
      final certificates = await getAllCertificates();
      
      if (certificates.isEmpty) return null;

      final totalPoints = certificates.fold<int>(
        0, 
        (sum, cert) => sum + cert.pointsAwarded,
      );

      final currentLevel = _calculateLevelFromPoints(totalPoints);
      
      // Check if this is a recent achievement (last certificate pushed user to new level)
      if (certificates.length >= 2) {
        final previousTotal = totalPoints - certificates.first.pointsAwarded;
        final previousLevel = _calculateLevelFromPoints(previousTotal);
        
        if (currentLevel != previousLevel) {
          return {
            'newLevel': currentLevel,
            'previousLevel': previousLevel,
            'totalPoints': totalPoints,
            'achievement': 'Level Up Achievement!',
          };
        }
      } else if (certificates.length == 1) {
        // First certificate
        return {
          'newLevel': currentLevel,
          'previousLevel': 'New Citizen',
          'totalPoints': totalPoints,
          'achievement': 'First Certificate Achievement!',
        };
      }

      return null;
    } catch (e) {
      print('❌ Error checking level achievement: $e');
      return null;
    }
  }
}
