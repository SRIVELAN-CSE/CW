import 'package:uuid/uuid.dart';
import 'user.dart';

class Issue {
  final String id;
  final String title;
  final String description;
  final Department department;
  final IssueStatus status;
  final Priority priority;
  final String reportedBy; // User ID
  final String? assignedTo; // Officer ID
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final int upvotes;
  final int comments;
  final bool isPublic;

  Issue({
    String? id,
    required this.title,
    required this.description,
    required this.department,
    this.status = IssueStatus.todo,
    this.priority = Priority.medium,
    required this.reportedBy,
    this.assignedTo,
    required this.location,
    this.latitude,
    this.longitude,
    this.mediaUrls = const [],
    DateTime? createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.upvotes = 0,
    this.comments = 0,
    this.isPublic = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      department: Department.values.firstWhere(
        (dept) => dept.name == json['department'],
      ),
      status: IssueStatus.values.firstWhere(
        (status) => status.name == json['status'],
      ),
      priority: Priority.values.firstWhere(
        (priority) => priority.name == json['priority'],
      ),
      reportedBy: json['reportedBy'],
      assignedTo: json['assignedTo'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      resolutionNotes: json['resolutionNotes'],
      upvotes: json['upvotes'] ?? 0,
      comments: json['comments'] ?? 0,
      isPublic: json['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'department': department.name,
      'status': status.name,
      'priority': priority.name,
      'reportedBy': reportedBy,
      'assignedTo': assignedTo,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'mediaUrls': mediaUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'upvotes': upvotes,
      'comments': comments,
      'isPublic': isPublic,
    };
  }

  Issue copyWith({
    String? title,
    String? description,
    Department? department,
    IssueStatus? status,
    Priority? priority,
    String? assignedTo,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? mediaUrls,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
    int? upvotes,
    int? comments,
    bool? isPublic,
  }) {
    return Issue(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      department: department ?? this.department,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      reportedBy: reportedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      upvotes: upvotes ?? this.upvotes,
      comments: comments ?? this.comments,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  String get issueNumber {
    return '${department.code}-${id.substring(0, 8).toUpperCase()}';
  }

  Duration get age {
    return DateTime.now().difference(createdAt);
  }

  bool get isOverdue {
    final daysSinceCreated = age.inDays;
    switch (priority) {
      case Priority.critical:
        return daysSinceCreated > 1 && status != IssueStatus.completed;
      case Priority.high:
        return daysSinceCreated > 3 && status != IssueStatus.completed;
      case Priority.medium:
        return daysSinceCreated > 7 && status != IssueStatus.completed;
      case Priority.low:
        return daysSinceCreated > 14 && status != IssueStatus.completed;
    }
  }

  @override
  String toString() {
    return 'Issue(id: $id, title: $title, status: $status, priority: $priority)';
  }
}

enum IssueStatus {
  todo,
  inProgress,
  completed,
  rejected;

  String get displayName {
    switch (this) {
      case IssueStatus.todo:
        return 'To Do';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.completed:
        return 'Completed';
      case IssueStatus.rejected:
        return 'Rejected';
    }
  }
}

enum Priority {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical';
    }
  }

  int get weight {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
      case Priority.critical:
        return 4;
    }
  }
}