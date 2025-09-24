import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/password_reset_request.dart';

class PasswordResetManagementScreen extends StatefulWidget {
  const PasswordResetManagementScreen({super.key});

  @override
  State<PasswordResetManagementScreen> createState() => _PasswordResetManagementScreenState();
}

class _PasswordResetManagementScreenState extends State<PasswordResetManagementScreen> {
  List<PasswordResetRequest> passwordResetRequests = [];
  bool isLoading = true;
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadPasswordResetRequests();
  }

  Future<void> _loadPasswordResetRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final requests = await _databaseService.getAllPasswordResetRequests();
      setState(() {
        passwordResetRequests = requests;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Failed to load password reset requests: $e');
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      // Get the request details first
      final allRequests = await _databaseService.getAllPasswordResetRequests();
      final request = allRequests.firstWhere((r) => r.id == requestId);
      
      await _databaseService.updatePasswordResetRequestStatus(
        requestId, 
        PasswordResetStatus.approved,
        'Request approved for password reset',
        'Admin' // TODO: Get actual admin name from session
      );

      // Create notification for the user
      await NotificationService.instance.createPasswordResetApprovedNotification(
        request.email,
        request.fullName,
        requestId,
      );

      _showSuccessDialog('Password reset request approved. User has been notified and can now set a new password.');
      _loadPasswordResetRequests(); // Reload the list
    } catch (e) {
      _showErrorDialog('Failed to approve request: $e');
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      // Get the request details first
      final allRequests = await _databaseService.getAllPasswordResetRequests();
      final request = allRequests.firstWhere((r) => r.id == requestId);
      
      await _databaseService.updatePasswordResetRequestStatus(
        requestId, 
        PasswordResetStatus.rejected,
        'Request rejected by admin',
        'Admin' // TODO: Get actual admin name from session
      );

      // Create notification for the user
      await NotificationService.instance.createPasswordResetRejectedNotification(
        request.email,
        request.fullName,
        'Request rejected by admin',
        requestId,
      );

      _showSuccessDialog('Password reset request rejected. User has been notified.');
      _loadPasswordResetRequests(); // Reload the list
    } catch (e) {
      _showErrorDialog('Failed to reject request: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showRequestDetails(PasswordResetRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Password Reset Request Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow('Request ID:', request.id),
                _DetailRow('Email:', request.email),
                _DetailRow('Full Name:', request.fullName),
                _DetailRow('Status:', request.status.toString().split('.').last.toUpperCase()),
                _DetailRow('Requested:', _formatDateTime(request.requestDate)),
                if (request.responseDate != null)
                  _DetailRow('Reviewed:', _formatDateTime(request.responseDate!)),
                if (request.reason.isNotEmpty)
                  _DetailRow('Reason:', request.reason),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (request.isPending) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _rejectRequest(request.id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _approveRequest(request.id);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Approve'),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(PasswordResetStatus status) {
    switch (status) {
      case PasswordResetStatus.pending:
        return Colors.orange;
      case PasswordResetStatus.approved:
        return Colors.green;
      case PasswordResetStatus.rejected:
        return Colors.red;
      case PasswordResetStatus.completed:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(PasswordResetStatus status) {
    switch (status) {
      case PasswordResetStatus.pending:
        return Icons.pending;
      case PasswordResetStatus.approved:
        return Icons.check_circle;
      case PasswordResetStatus.rejected:
        return Icons.cancel;
      case PasswordResetStatus.completed:
        return Icons.done_all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Password Reset Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadPasswordResetRequests,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Requests',
                    count: passwordResetRequests.length,
                    color: Colors.blue,
                    icon: Icons.password,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Pending',
                    count: passwordResetRequests.where((r) => r.isPending).length,
                    color: Colors.orange,
                    icon: Icons.pending,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    title: 'Approved',
                    count: passwordResetRequests.where((r) => r.isApproved).length,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Request List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : passwordResetRequests.isEmpty
                      ? const Center(
                          child: Text(
                            'No password reset requests found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: passwordResetRequests.length,
                          itemBuilder: (context, index) {
                            final request = passwordResetRequests[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(request.status),
                                  child: Icon(
                                    _getStatusIcon(request.status),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  request.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(request.email),
                                    Text(
                                      'Requested: ${_formatDateTime(request.requestDate)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(
                                        request.status.toString().split('.').last.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: _getStatusColor(request.status),
                                    ),
                                    const SizedBox(width: 8),
                                    if (request.isPending) ...[
                                      IconButton(
                                        onPressed: () => _rejectRequest(request.id),
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        tooltip: 'Reject',
                                      ),
                                      IconButton(
                                        onPressed: () => _approveRequest(request.id),
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        tooltip: 'Approve',
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () => _showRequestDetails(request),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}