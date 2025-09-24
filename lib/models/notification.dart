import 'package:uuid/uuid.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? userId; // null for system-wide notifications
  final String? issueId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    String? id,
    required this.title,
    required this.message,
    required this.type,
    this.userId,
    this.issueId,
    this.data,
    this.isRead = false,
    DateTime? createdAt,
    this.readAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (type) => type.name == json['type'],
      ),
      userId: json['userId'],
      issueId: json['issueId'],
      data: json['data'] != null 
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'userId': userId,
      'issueId': issueId,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? title,
    String? message,
    NotificationType? type,
    String? userId,
    String? issueId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      issueId: issueId ?? this.issueId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  AppNotification markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}

enum NotificationType {
  issueCreated,
  issueUpdated,
  issueAssigned,
  issueCompleted,
  issueRejected,
  systemAnnouncement,
  governmentNotice,
  reminder,
  warning;

  String get displayName {
    switch (this) {
      case NotificationType.issueCreated:
        return 'New Issue';
      case NotificationType.issueUpdated:
        return 'Issue Updated';
      case NotificationType.issueAssigned:
        return 'Issue Assigned';
      case NotificationType.issueCompleted:
        return 'Issue Completed';
      case NotificationType.issueRejected:
        return 'Issue Rejected';
      case NotificationType.systemAnnouncement:
        return 'System Announcement';
      case NotificationType.governmentNotice:
        return 'Government Notice';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.warning:
        return 'Warning';
    }
  }
}