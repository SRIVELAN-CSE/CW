import 'package:flutter/material.dart';
import 'storage_service.dart';

class Report {
  final String id;
  final String title;
  final String description;
  final String location;
  final String category;
  final String priority;
  final String status;
  final DateTime reportedTime;
  final String reportedBy;
  final String? assignedOfficer;
  final List<String> comments;
  final List<String> imageAttachments; // List of image file paths

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.priority,
    required this.status,
    required this.reportedTime,
    required this.reportedBy,
    this.assignedOfficer,
    this.comments = const [],
    this.imageAttachments = const [],
  });

  Report copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? category,
    String? priority,
    String? status,
    DateTime? reportedTime,
    String? reportedBy,
    String? assignedOfficer,
    List<String>? comments,
    List<String>? imageAttachments,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      reportedTime: reportedTime ?? this.reportedTime,
      reportedBy: reportedBy ?? this.reportedBy,
      assignedOfficer: assignedOfficer ?? this.assignedOfficer,
      comments: comments ?? this.comments,
      imageAttachments: imageAttachments ?? this.imageAttachments,
    );
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'new':
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'critical':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(reportedTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class ReportService extends ChangeNotifier {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal() {
    _loadReportsFromStorage();
  }

  final StorageService _storageService = StorageService();
  final List<Report> _reports = [];

  // Load reports from storage on initialization
  Future<void> _loadReportsFromStorage() async {
    try {
      final storedReports = await _storageService.loadReports();
      _reports.clear();
      _reports.addAll(storedReports);
      
      notifyListeners();
      print('Loaded ${_reports.length} reports from storage');
    } catch (e) {
      print('Error loading reports from storage: $e');
      // No fallback sample data - start with empty list
    }
  }

  List<Report> get allReports => List.unmodifiable(_reports);
  
  List<Report> get newReports => _reports.where((r) => r.status == 'New').toList();
  
  List<Report> get inProgressReports => _reports.where((r) => r.status == 'In Progress').toList();
  
  List<Report> get resolvedReports => _reports.where((r) => r.status == 'Resolved').toList();

  List<Report> getReportsByStatus(String status) {
    if (status == 'All') return allReports;
    return _reports.where((r) => r.status == status).toList();
  }

  List<Report> getReportsByCategory(String category) {
    if (category == 'All') return allReports;
    return _reports.where((r) => r.category == category).toList();
  }

  List<Report> getReportsByPriority(String priority) {
    if (priority == 'All') return allReports;
    return _reports.where((r) => r.priority == priority).toList();
  }

  Future<void> addReport(Report report) async {
    _reports.add(report);
    print('Report added: ${report.title} - Total reports: ${_reports.length}');
    notifyListeners();
    print('Listeners notified for new report');
    
    // Save to persistent storage
    try {
      await _storageService.saveReport(report);
      print('Report ${report.id} saved to storage successfully');
    } catch (e) {
      print('Error saving report to storage: $e');
    }
  }

  Future<void> updateReportStatus(String reportId, String newStatus, String comment) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      final updatedComments = [...report.comments];
      if (comment.isNotEmpty) {
        updatedComments.add('${DateTime.now().toString()}: $comment');
      }
      
      _reports[index] = report.copyWith(
        status: newStatus,
        comments: updatedComments,
      );
      notifyListeners();
      
      // Save updated report to storage
      try {
        await _storageService.saveReport(_reports[index]);
        print('Report $reportId status updated and saved to storage');
      } catch (e) {
        print('Error saving updated report to storage: $e');
      }
    }
  }

  Future<void> assignOfficer(String reportId, String officerId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index] = _reports[index].copyWith(assignedOfficer: officerId);
      notifyListeners();
      
      // Save updated report to storage
      try {
        await _storageService.saveReport(_reports[index]);
        print('Officer assigned to report $reportId and saved to storage');
      } catch (e) {
        print('Error saving officer assignment to storage: $e');
      }
    }
  }

  Report? getReportById(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  int get totalReports => _reports.length;
  int get newReportsCount => newReports.length;
  int get inProgressReportsCount => inProgressReports.length;
  int get resolvedReportsCount => resolvedReports.length;

  // Statistics for dashboards
  Map<String, int> get reportsByCategory {
    final Map<String, int> categoryCount = {};
    for (final report in _reports) {
      categoryCount[report.category] = (categoryCount[report.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  Map<String, int> get reportsByStatus {
    final Map<String, int> statusCount = {};
    for (final report in _reports) {
      statusCount[report.status] = (statusCount[report.status] ?? 0) + 1;
    }
    return statusCount;
  }

  // Generate unique ID for new reports
  String generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'RPT${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }
}