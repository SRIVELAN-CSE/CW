class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? userId;
  final String? reportId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final NotificationChannel channel;
  final NotificationPriority priority;
  final String? actionUrl;
  final DateTime? scheduledAt;
  final bool isSent;
  final DateTime? sentAt;
  final String? error;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.userId,
    this.reportId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data,
    required this.channel,
    required this.priority,
    this.actionUrl,
    this.scheduledAt,
    required this.isSent,
    this.sentAt,
    this.error,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(json['type']),
      userId: json['userId'],
      reportId: json['reportId'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      data: json['data'],
      channel: _parseNotificationChannel(json['channel']),
      priority: _parseNotificationPriority(json['priority']),
      actionUrl: json['actionUrl'],
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      isSent: json['isSent'] ?? false,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'userId': userId,
      'reportId': reportId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
      'channel': channel.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'actionUrl': actionUrl,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'isSent': isSent,
      'sentAt': sentAt?.toIso8601String(),
      'error': error,
    };
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'report_status_update':
        return NotificationType.reportStatusUpdate;
      case 'new_report_assigned':
        return NotificationType.newReportAssigned;
      case 'report_resolved':
        return NotificationType.reportResolved;
      case 'report_rejected':
        return NotificationType.reportRejected;
      case 'new_comment':
        return NotificationType.newComment;
      case 'system_announcement':
        return NotificationType.systemAnnouncement;
      case 'maintenance_alert':
        return NotificationType.maintenanceAlert;
      case 'account_verification':
        return NotificationType.accountVerification;
      case 'password_reset':
        return NotificationType.passwordReset;
      case 'general':
        return NotificationType.general;
      default:
        return NotificationType.general;
    }
  }

  static NotificationChannel _parseNotificationChannel(String? channel) {
    switch (channel) {
      case 'push':
        return NotificationChannel.push;
      case 'email':
        return NotificationChannel.email;
      case 'sms':
        return NotificationChannel.sms;
      case 'in_app':
        return NotificationChannel.inApp;
      default:
        return NotificationChannel.inApp;
    }
  }

  static NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      userId: userId,
      reportId: reportId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      data: data,
      channel: channel,
      priority: priority,
      actionUrl: actionUrl,
      scheduledAt: scheduledAt,
      isSent: isSent,
      sentAt: sentAt,
      error: error,
    );
  }

  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }
}

enum NotificationType {
  reportStatusUpdate,
  newReportAssigned,
  reportResolved,
  reportRejected,
  newComment,
  systemAnnouncement,
  maintenanceAlert,
  accountVerification,
  passwordReset,
  general;

  String get displayName {
    switch (this) {
      case NotificationType.reportStatusUpdate:
        return 'Report Status Update';
      case NotificationType.newReportAssigned:
        return 'New Report Assigned';
      case NotificationType.reportResolved:
        return 'Report Resolved';
      case NotificationType.reportRejected:
        return 'Report Rejected';
      case NotificationType.newComment:
        return 'New Comment';
      case NotificationType.systemAnnouncement:
        return 'System Announcement';
      case NotificationType.maintenanceAlert:
        return 'Maintenance Alert';
      case NotificationType.accountVerification:
        return 'Account Verification';
      case NotificationType.passwordReset:
        return 'Password Reset';
      case NotificationType.general:
        return 'General';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.reportStatusUpdate:
        return '📋';
      case NotificationType.newReportAssigned:
        return '📌';
      case NotificationType.reportResolved:
        return '✅';
      case NotificationType.reportRejected:
        return '❌';
      case NotificationType.newComment:
        return '💬';
      case NotificationType.systemAnnouncement:
        return '📢';
      case NotificationType.maintenanceAlert:
        return '🔧';
      case NotificationType.accountVerification:
        return '✔️';
      case NotificationType.passwordReset:
        return '🔐';
      case NotificationType.general:
        return '📳';
    }
  }
}

enum NotificationChannel {
  push,
  email,
  sms,
  inApp;

  String get displayName {
    switch (this) {
      case NotificationChannel.push:
        return 'Push Notification';
      case NotificationChannel.email:
        return 'Email';
      case NotificationChannel.sms:
        return 'SMS';
      case NotificationChannel.inApp:
        return 'In-App';
    }
  }
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
}