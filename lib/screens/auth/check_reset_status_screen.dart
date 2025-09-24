import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/password_reset_request.dart';
import 'password_reset_screen.dart';

class CheckResetStatusScreen extends StatefulWidget {
  const CheckResetStatusScreen({super.key});

  @override
  State<CheckResetStatusScreen> createState() => _CheckResetStatusScreenState();
}

class _CheckResetStatusScreenState extends State<CheckResetStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  PasswordResetRequest? _resetRequest;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkResetStatus() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final allRequests = await DatabaseService.instance.getAllPasswordResetRequests();
      
      // Find the most recent request for this email
      final userRequests = allRequests.where((r) => r.email == email).toList();
      userRequests.sort((a, b) => b.requestDate.compareTo(a.requestDate));
      
      if (userRequests.isEmpty) {
        _showStatusDialog(
          'No Reset Request Found',
          'No password reset request found for this email address.',
          'not_found',
          null,
        );
        return;
      }

      final latestRequest = userRequests.first;
      setState(() => _resetRequest = latestRequest);

      String title;
      String message;
      String status;

      switch (latestRequest.status) {
        case PasswordResetStatus.pending:
          title = 'Request Pending';
          message = 'Your password reset request is pending admin approval.\n\nRequest ID: ${latestRequest.id}\nSubmitted: ${_formatDateTime(latestRequest.requestDate)}';
          status = 'pending';
          break;
        case PasswordResetStatus.approved:
          title = 'Request Approved!';
          message = 'Your password reset request has been approved. You can now create a new password.';
          status = 'approved';
          break;
        case PasswordResetStatus.rejected:
          title = 'Request Rejected';
          message = 'Your password reset request was rejected.\n\nReason: ${latestRequest.adminResponse ?? 'No reason provided'}';
          status = 'rejected';
          break;
        case PasswordResetStatus.completed:
          title = 'Password Already Reset';
          message = 'Your password has already been reset for this request.\n\nCompleted: ${latestRequest.completedDate != null ? _formatDateTime(latestRequest.completedDate!) : 'Unknown'}';
          status = 'completed';
          break;
      }

      _showStatusDialog(title, message, status, latestRequest);
    } catch (e) {
      _showStatusDialog(
        'Error',
        'Failed to check reset status: $e',
        'error',
        null,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showStatusDialog(String title, String message, String status, PasswordResetRequest? request) {
    IconData icon;
    Color iconColor;
    
    switch (status) {
      case 'pending':
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange;
        break;
      case 'approved':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'completed':
        icon = Icons.done_all;
        iconColor = Colors.blue;
        break;
      case 'not_found':
        icon = Icons.search_off;
        iconColor = Colors.grey;
        break;
      default:
        icon = Icons.error;
        iconColor = Colors.red;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: iconColor, size: 64),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (status == 'approved' && request != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ready to Reset Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PasswordResetScreen(
                              email: request.email,
                              requestId: request.id,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reset Password Now'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Reset Status'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Header
              const Icon(
                Icons.manage_search,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Check Reset Status',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email to check the status of your password reset request',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  helperText: 'Enter the email you used for the reset request',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Check Status Button
              ElevatedButton(
                onPressed: _isLoading ? null : _checkResetStatus,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Check Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),

              // Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Reset Status Guide',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatusInfo('Pending', 'Waiting for admin approval', Colors.orange),
                    _StatusInfo('Approved', 'Ready to reset password', Colors.green),
                    _StatusInfo('Rejected', 'Request was denied', Colors.red),
                    _StatusInfo('Completed', 'Password already reset', Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final String status;
  final String description;
  final Color color;

  const _StatusInfo(this.status, this.description, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$status: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}