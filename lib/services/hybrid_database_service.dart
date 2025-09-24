import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/report.dart';
import '../models/user.dart';
import '../models/notification.dart';

class HybridDatabaseService {
  static const String _prefix = 'civic_welfare_';
  static SharedPreferences? _prefs;

  // Initialize the service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('🔧 LocalDatabaseService initialized (Firestore removed)');
  }

  static SharedPreferences get _preferences {
    if (_prefs == null) {
      throw Exception('LocalDatabaseService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ==================== REPORT OPERATIONS ====================

  /// Save report to local storage only
  static Future<bool> saveReport(Report report) async {
    try {
      print('💾 [LOCAL] Saving report: ${report.title}');
      
      // Save to local storage only
      bool localSaved = await _saveReportLocally(report);
      print('📱 Local save result: $localSaved');
      
      return localSaved;
    } catch (e) {
      print('❌ Error in local save: $e');
      return false;
    }
  }

  /// Get all reports from local storage
  static Future<List<Report>> getAllReports() async {
    try {
      List<Report> localReports = await _getReportsLocally();
      print('📱 Retrieved ${localReports.length} reports from local storage');
      return localReports;
    } catch (e) {
      print('❌ Error getting reports: $e');
      return [];
    }
  }

  /// Get reports stream (local data only)
  static Stream<List<Report>> getReportsStream() {
    try {
      // Return a stream with local data only
      return Stream.fromFuture(_getReportsLocally());
    } catch (e) {
      print('❌ Error creating reports stream: $e');
      return Stream.value([]);
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Save user to local storage
  static Future<bool> saveUser(User user) async {
    try {
      print('👤 [LOCAL] Saving user: ${user.name}');
      
      bool localSaved = await _saveUserLocally(user);
      print('📱 User local save: $localSaved');
      
      return localSaved;
    } catch (e) {
      print('❌ Error saving user: $e');
      return false;
    }
  }

  /// Get all users from local storage
  static Future<List<User>> getAllUsers() async {
    try {
      List<User> localUsers = await _getUsersLocally();
      print('📱 Retrieved ${localUsers.length} users from local storage');
      return localUsers;
    } catch (e) {
      print('❌ Error getting users: $e');
      return [];
    }
  }

  // ==================== NOTIFICATION OPERATIONS ====================

  /// Save notification to local storage
  static Future<bool> saveNotification(AppNotification notification) async {
    try {
      print('🔔 [LOCAL] Saving notification for user: ${notification.userId}');
      bool localSaved = await _saveNotificationLocally(notification);
      return localSaved;
    } catch (e) {
      print('❌ Error saving notification: $e');
      return false;
    }
  }

  /// Get notifications for user from local storage
  static Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    try {
      List<AppNotification> localNotifications = await _getNotificationsLocally(userId);
      print('� Retrieved ${localNotifications.length} notifications for user $userId');
      return localNotifications;
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  // ==================== LOCAL STORAGE HELPERS ====================

  static Future<bool> _saveReportLocally(Report report) async {
    try {
      List<Report> existingReports = await _getReportsLocally();
      
      // Remove existing report with same ID
      existingReports.removeWhere((r) => r.id == report.id);
      
      // Add new report
      existingReports.add(report);
      
      // Save back to local storage
      List<String> reportStrings = existingReports.map((r) => jsonEncode(r.toJson())).toList();
      return await _preferences.setStringList('${_prefix}reports', reportStrings);
    } catch (e) {
      print('❌ Error saving report locally: $e');
      return false;
    }
  }

  static Future<List<Report>> _getReportsLocally() async {
    try {
      List<String>? reportStrings = _preferences.getStringList('${_prefix}reports');
      if (reportStrings == null) return [];
      
      return reportStrings.map((str) {
        Map<String, dynamic> json = jsonDecode(str);
        return Report.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Error loading reports locally: $e');
      return [];
    }
  }

  static Future<bool> _saveUserLocally(User user) async {
    try {
      List<User> existingUsers = await _getUsersLocally();
      existingUsers.removeWhere((u) => u.id == user.id);
      existingUsers.add(user);
      
      List<String> userStrings = existingUsers.map((u) => jsonEncode(u.toJson())).toList();
      return await _preferences.setStringList('${_prefix}users', userStrings);
    } catch (e) {
      print('❌ Error saving user locally: $e');
      return false;
    }
  }

  static Future<List<User>> _getUsersLocally() async {
    try {
      List<String>? userStrings = _preferences.getStringList('${_prefix}users');
      if (userStrings == null) return [];
      
      return userStrings.map((str) {
        Map<String, dynamic> json = jsonDecode(str);
        return User.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Error loading users locally: $e');
      return [];
    }
  }

  static Future<bool> _saveNotificationLocally(AppNotification notification) async {
    try {
      List<AppNotification> existing = await _getNotificationsLocally(notification.userId ?? '');
      existing.removeWhere((n) => n.id == notification.id);
      existing.add(notification);
      
      List<String> notificationStrings = existing.map((n) => jsonEncode(n.toJson())).toList();
      return await _preferences.setStringList('${_prefix}notifications_${notification.userId}', notificationStrings);
    } catch (e) {
      print('❌ Error saving notification locally: $e');
      return false;
    }
  }

  static Future<List<AppNotification>> _getNotificationsLocally(String userId) async {
    try {
      List<String>? notificationStrings = _preferences.getStringList('${_prefix}notifications_$userId');
      if (notificationStrings == null) return [];
      
      return notificationStrings.map((str) {
        Map<String, dynamic> json = jsonDecode(str);
        return AppNotification.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ Error loading notifications locally: $e');
      return [];
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Test local storage connectivity
  static Future<Map<String, bool>> testConnectivity() async {
    bool localWorking = false;
    
    try {
      // Test local storage
      await _preferences.setString('test', 'local_test');
      String? result = _preferences.getString('test');
      localWorking = result == 'local_test';
      await _preferences.remove('test');
    } catch (e) {
      print('❌ Local storage test failed: $e');
    }
    
    return {
      'local': localWorking,
      'cloud': false, // Cloud removed
    };
  }

  /// Clear all local data
  static Future<bool> clearLocalData() async {
    try {
      await _preferences.clear();
      print('🗑️ All local data cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing local data: $e');
      return false;
    }
  }

  /// Get storage statistics
  static Future<Map<String, int>> getStorageStats() async {
    try {
      List<Report> reports = await _getReportsLocally();
      List<User> users = await _getUsersLocally();
      
      return {
        'localReports': reports.length,
        'localUsers': users.length,
        'cloudReports': 0, // Cloud removed
        'cloudUsers': 0, // Cloud removed
      };
    } catch (e) {
      print('❌ Error getting storage stats: $e');
      return {};
    }
  }

  /// Delete a report by ID
  static Future<bool> deleteReport(String reportId) async {
    try {
      List<Report> reports = await _getReportsLocally();
      int initialLength = reports.length;
      reports.removeWhere((r) => r.id == reportId);
      
      if (reports.length < initialLength) {
        List<String> reportStrings = reports.map((r) => jsonEncode(r.toJson())).toList();
        bool saved = await _preferences.setStringList('${_prefix}reports', reportStrings);
        print('🗑️ Report $reportId deleted from local storage');
        return saved;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting report: $e');
      return false;
    }
  }

  /// Update a report
  static Future<bool> updateReport(Report report) async {
    try {
      return await _saveReportLocally(report);
    } catch (e) {
      print('❌ Error updating report: $e');
      return false;
    }
  }
}