import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'report_service.dart';
import '../utils/web_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _reportsFileName = 'citizen_reports.json';
  static const String _userDataFileName = 'user_data.json';
  static const String _appDataFileName = 'app_data.json';

  // Get application documents directory
  Future<Directory> get _applicationDirectory async {
    if (kIsWeb) {
      // For web, we'll use a fallback directory
      return Directory.current;
    }
    return await getApplicationDocumentsDirectory();
  }

  // Save reports to local storage
  Future<bool> saveReports(List<Report> reports) async {
    try {
      if (kIsWeb) {
        // For web platform, use localStorage simulation
        return await _saveReportsWeb(reports);
      }

      final directory = await _applicationDirectory;
      final file = File('${directory.path}/$_reportsFileName');
      
      final reportsJson = reports.map((report) => _reportToJson(report)).toList();
      final jsonString = jsonEncode({
        'reports': reportsJson,
        'lastUpdated': DateTime.now().toIso8601String(),
        'totalReports': reports.length,
      });
      
      await file.writeAsString(jsonString);
      print('Successfully saved ${reports.length} reports to storage');
      return true;
    } catch (e) {
      print('Error saving reports: $e');
      return false;
    }
  }

  // Load reports from local storage
  Future<List<Report>> loadReports() async {
    try {
      if (kIsWeb) {
        // For web platform, use localStorage simulation
        return await _loadReportsWeb();
      }

      final directory = await _applicationDirectory;
      final file = File('${directory.path}/$_reportsFileName');
      
      if (!await file.exists()) {
        print('Reports file does not exist, returning empty list');
        return [];
      }
      
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);
      
      if (jsonData['reports'] != null) {
        final List<dynamic> reportsJson = jsonData['reports'];
        final reports = reportsJson.map((json) => _reportFromJson(json)).toList();
        print('Successfully loaded ${reports.length} reports from storage');
        return reports;
      }
      
      return [];
    } catch (e) {
      print('Error loading reports: $e');
      return [];
    }
  }

  // Save individual report (append to existing)
  Future<bool> saveReport(Report report) async {
    try {
      final existingReports = await loadReports();
      
      // Check if report already exists (update) or add new
      final existingIndex = existingReports.indexWhere((r) => r.id == report.id);
      if (existingIndex != -1) {
        existingReports[existingIndex] = report;
      } else {
        existingReports.add(report);
      }
      
      return await saveReports(existingReports);
    } catch (e) {
      print('Error saving individual report: $e');
      return false;
    }
  }

  // Save user session data
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      if (kIsWeb) {
        return await _saveUserDataWeb(userData);
      }

      final directory = await _applicationDirectory;
      final file = File('${directory.path}/$_userDataFileName');
      
      final dataWithTimestamp = {
        ...userData,
        'lastLogin': DateTime.now().toIso8601String(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      await file.writeAsString(jsonEncode(dataWithTimestamp));
      print('User data saved successfully');
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Load user session data
  Future<Map<String, dynamic>?> loadUserData() async {
    try {
      if (kIsWeb) {
        return await _loadUserDataWeb();
      }

      final directory = await _applicationDirectory;
      final file = File('${directory.path}/$_userDataFileName');
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonString = await file.readAsString();
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }

  // Save app statistics and settings
  Future<bool> saveAppData(Map<String, dynamic> appData) async {
    try {
      if (kIsWeb) {
        return await _saveAppDataWeb(appData);
      }

      final directory = await _applicationDirectory;
      final file = File('${directory.path}/$_appDataFileName');
      
      final dataWithTimestamp = {
        ...appData,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await file.writeAsString(jsonEncode(dataWithTimestamp));
      return true;
    } catch (e) {
      print('Error saving app data: $e');
      return false;
    }
  }

  // Load app statistics and settings
  Future<Map<String, dynamic>?> loadAppData() async {
    try {
      if (kIsWeb) {
        return await _loadAppDataWeb();
      }

      final directory = await _applicationDirectory;
      final file = File('${directory.path}/$_appDataFileName');
      
      if (!await file.exists()) {
        return null;
      }
      
      final jsonString = await file.readAsString();
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error loading app data: $e');
      return null;
    }
  }

  // Clear all stored data
  Future<bool> clearAllData() async {
    try {
      if (kIsWeb) {
        return await _clearAllDataWeb();
      }

      final directory = await _applicationDirectory;
      final files = [
        File('${directory.path}/$_reportsFileName'),
        File('${directory.path}/$_userDataFileName'),
        File('${directory.path}/$_appDataFileName'),
      ];
      
      for (final file in files) {
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      print('All stored data cleared successfully');
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final reports = await loadReports();
      final userData = await loadUserData();
      final appData = await loadAppData();
      
      return {
        'totalReports': reports.length,
        'hasUserData': userData != null,
        'hasAppData': appData != null,
        'lastReportDate': reports.isNotEmpty 
            ? reports.map((r) => r.reportedTime).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
            : null,
        'reportsByCategory': _getReportsByCategory(reports),
        'reportsByStatus': _getReportsByStatus(reports),
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {};
    }
  }

  // Helper methods for web platform (simplified localStorage simulation)
  Future<bool> _saveReportsWeb(List<Report> reports) async {
    try {
      final reportsJson = reports.map((report) => _reportToJson(report)).toList();
      WebStorage.setList('citizen_reports', reportsJson);
      print('Web: Successfully saved ${reports.length} reports to localStorage');
      return true;
    } catch (e) {
      print('Web: Error saving reports: $e');
      return false;
    }
  }

  Future<List<Report>> _loadReportsWeb() async {
    try {
      final reportsJson = WebStorage.getList('citizen_reports') ?? [];
      final reports = reportsJson.map((json) => _reportFromJson(json as Map<String, dynamic>)).toList();
      print('Web: Successfully loaded ${reports.length} reports from localStorage');
      return reports;
    } catch (e) {
      print('Web: Error loading reports: $e');
      return [];
    }
  }

  Future<bool> _saveUserDataWeb(Map<String, dynamic> userData) async {
    try {
      WebStorage.setJson('user_data', userData);
      print('Web: Successfully saved user data to localStorage');
      return true;
    } catch (e) {
      print('Web: Error saving user data: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _loadUserDataWeb() async {
    try {
      final userData = WebStorage.getJson('user_data');
      if (userData != null) {
        print('Web: Successfully loaded user data from localStorage');
      } else {
        print('Web: No user data found in localStorage');
      }
      return userData;
    } catch (e) {
      print('Web: Error loading user data: $e');
      return null;
    }
  }

  Future<bool> _saveAppDataWeb(Map<String, dynamic> appData) async {
    try {
      WebStorage.setJson('app_data', appData);
      print('Web: Successfully saved app data to localStorage');
      return true;
    } catch (e) {
      print('Web: Error saving app data: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _loadAppDataWeb() async {
    try {
      final appData = WebStorage.getJson('app_data');
      if (appData != null) {
        print('Web: Successfully loaded app data from localStorage');
      } else {
        print('Web: No app data found in localStorage');
      }
      return appData;
    } catch (e) {
      print('Web: Error loading app data: $e');
      return null;
    }
  }

  Future<bool> _clearAllDataWeb() async {
    try {
      WebStorage.remove('citizen_reports');
      WebStorage.remove('user_data');
      WebStorage.remove('app_data');
      print('Web: Successfully cleared all data from localStorage');
      return true;
    } catch (e) {
      print('Web: Error clearing data: $e');
      return false;
    }
  }

  // Convert Report object to JSON
  Map<String, dynamic> _reportToJson(Report report) {
    return {
      'id': report.id,
      'title': report.title,
      'description': report.description,
      'location': report.location,
      'category': report.category,
      'priority': report.priority,
      'status': report.status,
      'reportedTime': report.reportedTime.toIso8601String(),
      'reportedBy': report.reportedBy,
      'assignedOfficer': report.assignedOfficer,
      'comments': report.comments,
      'imageAttachments': report.imageAttachments,
    };
  }

  // Convert JSON to Report object
  Report _reportFromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      category: json['category'],
      priority: json['priority'],
      status: json['status'],
      reportedTime: DateTime.parse(json['reportedTime']),
      reportedBy: json['reportedBy'],
      assignedOfficer: json['assignedOfficer'],
      comments: List<String>.from(json['comments'] ?? []),
      imageAttachments: List<String>.from(json['imageAttachments'] ?? []),
    );
  }

  // Get reports grouped by category
  Map<String, int> _getReportsByCategory(List<Report> reports) {
    final Map<String, int> categoryCount = {};
    for (final report in reports) {
      categoryCount[report.category] = (categoryCount[report.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  // Get reports grouped by status
  Map<String, int> _getReportsByStatus(List<Report> reports) {
    final Map<String, int> statusCount = {};
    for (final report in reports) {
      statusCount[report.status] = (statusCount[report.status] ?? 0) + 1;
    }
    return statusCount;
  }
}