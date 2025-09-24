import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../screens/auth/password_reset_screen.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  // Get notifications for current user role
  Future<List<AppNotification>> getNotificationsForRole(String role, [String? userId]) async {
    final notifications = await DatabaseService.instance.getNotificationsForRole(role, userId);
    return notifications.map((n) => AppNotification.fromJson(n)).toList();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await DatabaseService.instance.markNotificationAsRead(notificationId);
  }

  // Get unread count for role
  Future<int> getUnreadCount(String role, [String? userId]) async {
    final notifications = await getNotificationsForRole(role, userId);
    return notifications.where((n) => !n.isRead).length;
  }

  // Create password reset approval notification
  Future<void> createPasswordResetApprovedNotification(String userEmail, String userName, String requestId) async {
    await DatabaseService.instance.createNotification(
      title: 'Password Reset Approved',
      message: 'Your password reset request has been approved. You can now create a new password.',
      reportId: requestId,
      targetRoles: ['public'],
      targetUserId: userEmail, // Using email as identifier
      type: 'NotificationType.passwordResetApproved',
    );
  }

  // Create password reset rejection notification
  Future<void> createPasswordResetRejectedNotification(String userEmail, String userName, String reason, String requestId) async {
    await DatabaseService.instance.createNotification(
      title: 'Password Reset Rejected',
      message: 'Your password reset request was rejected. Reason: $reason',
      reportId: requestId,
      targetRoles: ['public'],
      targetUserId: userEmail, // Using email as identifier
      type: 'NotificationType.passwordResetRejected',
    );
  }

  // Create password reset completion notification
  Future<void> createPasswordResetCompletedNotification(String userEmail, String userName, String requestId) async {
    await DatabaseService.instance.createNotification(
      title: 'Password Reset Completed',
      message: 'Your password has been successfully reset. You can now log in with your new password.',
      reportId: requestId,
      targetRoles: ['public'],
      targetUserId: userEmail, // Using email as identifier
      type: 'NotificationType.passwordResetCompleted',
    );
  }

  // Show notification popup
  void showNotificationSnackBar(BuildContext context, AppNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notification.message),
          ],
        ),
        backgroundColor: _getNotificationColor(notification.type),
        duration: const Duration(seconds: 4),
        action: notification.reportId != null
            ? SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navigate to report details
                },
              )
            : null,
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newReport:
        return Colors.blue;
      case NotificationType.statusUpdate:
        return Colors.orange;
      case NotificationType.assignment:
        return Colors.purple;
      case NotificationType.urgent:
        return Colors.red;
      case NotificationType.info:
        return Colors.green;
      case NotificationType.passwordResetApproved:
        return Colors.green;
      case NotificationType.passwordResetRejected:
        return Colors.red;
      case NotificationType.passwordResetCompleted:
        return Colors.blue;
      case NotificationType.needApproval:
        return Colors.green;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String? reportId;
  final List<String> targetRoles;
  final String? targetUserId;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.reportId,
    required this.targetRoles,
    this.targetUserId,
    required this.timestamp,
    required this.isRead,
    this.type = NotificationType.info,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      reportId: json['reportId'],
      targetRoles: List<String>.from(json['targetRoles'] ?? []),
      targetUserId: json['targetUserId'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => NotificationType.info,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'reportId': reportId,
      'targetRoles': targetRoles,
      'targetUserId': targetUserId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.toString(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

enum NotificationType {
  newReport,
  statusUpdate,
  assignment,
  urgent,
  info,
  passwordResetApproved,
  passwordResetRejected,
  passwordResetCompleted,
  needApproval,
}

// Notification Widget for dashboards
class NotificationWidget extends StatefulWidget {
  final String userRole;
  final String? userId;
  final VoidCallback? onNotificationTap;

  const NotificationWidget({
    super.key,
    required this.userRole,
    this.userId,
    this.onNotificationTap,
  });

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.instance.getUnreadCount(
      widget.userRole,
      widget.userId,
    );
    setState(() {
      unreadCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            widget.onNotificationTap?.call();
            _showNotificationPanel(context);
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NotificationPanel(
        userRole: widget.userRole,
        userId: widget.userId,
        onNotificationRead: _loadUnreadCount,
      ),
    );
  }
}

class NotificationPanel extends StatefulWidget {
  final String userRole;
  final String? userId;
  final VoidCallback? onNotificationRead;

  const NotificationPanel({
    super.key,
    required this.userRole,
    this.userId,
    this.onNotificationRead,
  });

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  List<AppNotification> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifs = await NotificationService.instance.getNotificationsForRole(
      widget.userRole,
      widget.userId,
    );
    setState(() {
      notifications = notifs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (notifications.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    onTap: () async {
                      if (!notification.isRead) {
                        await NotificationService.instance.markAsRead(notification.id);
                        widget.onNotificationRead?.call();
                        setState(() {
                          notifications[index] = AppNotification(
                            id: notification.id,
                            title: notification.title,
                            message: notification.message,
                            reportId: notification.reportId,
                            targetRoles: notification.targetRoles,
                            targetUserId: notification.targetUserId,
                            timestamp: notification.timestamp,
                            isRead: true,
                            type: notification.type,
                          );
                        });
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.isRead ? null : Colors.blue.withOpacity(0.1),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message),
                const SizedBox(height: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            onTap: onTap,
            trailing: notification.isRead ? null : const Icon(Icons.fiber_new, color: Colors.blue),
          ),
          // Add action button for password reset approved notifications
          if (notification.type == NotificationType.passwordResetApproved && notification.reportId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close notification panel
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PasswordResetScreen(
                          email: notification.targetUserId ?? '',
                          requestId: notification.reportId!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset Password Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newReport:
        return Icons.report_problem;
      case NotificationType.statusUpdate:
        return Icons.update;
      case NotificationType.assignment:
        return Icons.assignment_ind;
      case NotificationType.urgent:
        return Icons.priority_high;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.passwordResetApproved:
        return Icons.check_circle;
      case NotificationType.passwordResetRejected:
        return Icons.cancel;
      case NotificationType.passwordResetCompleted:
        return Icons.lock_reset;
      case NotificationType.needApproval:
        return Icons.approval;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newReport:
        return Colors.blue;
      case NotificationType.statusUpdate:
        return Colors.orange;
      case NotificationType.assignment:
        return Colors.purple;
      case NotificationType.urgent:
        return Colors.red;
      case NotificationType.info:
        return Colors.green;
      case NotificationType.passwordResetApproved:
        return Colors.green;
      case NotificationType.passwordResetRejected:
        return Colors.red;
      case NotificationType.passwordResetCompleted:
        return Colors.blue;
      case NotificationType.needApproval:
        return Colors.green;
    }
  }
}