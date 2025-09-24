import 'package:flutter/material.dart';
import '../../models/registration_request.dart';
import '../../services/database_service.dart';

class RegistrationManagementScreen extends StatefulWidget {
  const RegistrationManagementScreen({super.key});

  @override
  State<RegistrationManagementScreen> createState() => _RegistrationManagementScreenState();
}

class _RegistrationManagementScreenState extends State<RegistrationManagementScreen> {
  List<RegistrationRequest> _allRequests = [];
  List<RegistrationRequest> _filteredRequests = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRegistrationRequests();
  }

  Future<void> _loadRegistrationRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await DatabaseService.instance.getAllRegistrationRequests();
      setState(() {
        _allRequests = requests;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading registration requests: $e');
    }
  }

  void _applyFilters() {
    _filteredRequests = _allRequests.where((request) {
      // Status filter
      bool matchesStatus = true;
      if (_selectedFilter != 'All') {
        switch (_selectedFilter) {
          case 'New':
            matchesStatus = request.isRegistered;
            break;
          case 'Pending':
            matchesStatus = request.isNotified && request.userType == 'officer'; // Officers awaiting approval
            break;
          case 'Notified':
            matchesStatus = request.isNotified && request.userType != 'officer'; // Non-officers already processed
            break;
          case 'Archived':
            matchesStatus = request.isArchived;
            break;
        }
      }

      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          request.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.userType.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Management'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegistrationRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Search
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or user type...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Status Filter and Stats
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['All', 'New', 'Pending', 'Notified', 'Archived']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildStatsCard(),
                  ],
                ),
              ],
            ),
          ),

          // Registration Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          return _buildRegistrationCard(_filteredRequests[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final newCount = _allRequests.where((r) => r.isRegistered).length;
    final notifiedCount = _allRequests.where((r) => r.isNotified).length;
    final archivedCount = _allRequests.where((r) => r.isArchived).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text('New: $newCount', style: const TextStyle(fontSize: 12)),
          Text('Notified: $notifiedCount', style: const TextStyle(fontSize: 12)),
          Text('Archived: $archivedCount', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No registration requests found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registration requests will appear here when users submit them',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(RegistrationRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            request.userType == 'officer' ? Icons.badge : Icons.person,
                            size: 20,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            request.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusChip(request.status),
                    const SizedBox(height: 4),
                    Text(
                      request.registeredTime,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // User details
            _buildDetailRow('User Type', request.userType.toUpperCase()),
            _buildDetailRow('Phone', request.phone),
            _buildDetailRow('Address', request.address),
            _buildDetailRow('ID Number', request.idNumber),
            
            if (request.userType == 'officer') ...[
              if (request.department != null)
                _buildDetailRow('Department', request.department!),
              if (request.designation != null)
                _buildDetailRow('Designation', request.designation!),
            ],

            const SizedBox(height: 12),

            // Reason
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason for Registration:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(request.reason),
                ],
              ),
            ),

            // Registration status info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: request.isRegistered ? Colors.blue[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: request.isRegistered ? Colors.blue[200]! : Colors.green[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        request.isRegistered ? Icons.notifications_active : Icons.check_circle,
                        size: 16,
                        color: request.isRegistered ? Colors.blue[700] : Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRegistrationStatusText(request),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: request.isRegistered ? Colors.blue[700] : 
                                 (request.userType == 'officer' && request.isNotified) ? Colors.orange[700] :
                                 Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.isRegistered 
                        ? 'User has been automatically registered and can now log in.'
                        : 'Admin has been notified about this registration.',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registered on: ${_formatDate(request.requestDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            if (request.isRegistered && request.userType != 'officer') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsNotified(request),
                      icon: const Icon(Icons.mark_email_read, size: 18),
                      label: const Text('Mark as Notified'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _archiveNotification(request),
                      icon: const Icon(Icons.archive, size: 18),
                      label: const Text('Archive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (request.isNotified && request.userType == 'officer') ...[
              // Officer pending approval
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveOfficerRegistration(request),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectOfficerRegistration(request),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (request.isRegistered && request.userType == 'officer') ...[
              // Already approved officer
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _archiveNotification(request),
                  icon: const Icon(Icons.archive, size: 18),
                  label: const Text('Archive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else if (request.isNotified && request.userType != 'officer') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _archiveNotification(request),
                  icon: const Icon(Icons.archive, size: 18),
                  label: const Text('Archive Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getRegistrationStatusText(RegistrationRequest request) {
    if (request.isRegistered) {
      if (request.userType == 'officer') {
        return 'Officer Registration Approved';
      } else {
        return 'New Registration (Auto-Approved)';
      }
    } else if (request.isNotified) {
      if (request.userType == 'officer') {
        return 'Officer Registration Pending Approval';
      } else {
        return 'Notification Viewed';
      }
    } else if (request.isArchived) {
      if (request.userType == 'officer') {
        return 'Officer Registration Rejected';
      } else {
        return 'Archived';
      }
    }
    return 'Unknown Status';
  }

  // Approve officer registration
  Future<void> _approveOfficerRegistration(RegistrationRequest request) async {
    // Show confirmation dialog with comment input
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: 'Approve Officer Registration',
        message: 'Approve ${request.fullName}\'s officer registration?',
        isApproval: true,
      ),
    );

    if (result != null && result['confirmed'] == true) {
      try {
        final success = await DatabaseService.instance.approveOfficerRegistration(
          request.id,
          result['comment'] ?? 'Officer registration approved',
        );

        if (success) {
          _showSuccessSnackBar('Officer registration approved successfully!');
          _loadRegistrationRequests(); // Refresh the list
        } else {
          _showErrorSnackBar('Failed to approve officer registration');
        }
      } catch (e) {
        _showErrorSnackBar('Error approving officer registration: $e');
      }
    }
  }

  // Reject officer registration
  Future<void> _rejectOfficerRegistration(RegistrationRequest request) async {
    // Show confirmation dialog with rejection reason input
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: 'Reject Officer Registration',
        message: 'Reject ${request.fullName}\'s officer registration?',
        isApproval: false,
      ),
    );

    if (result != null && result['confirmed'] == true) {
      try {
        final success = await DatabaseService.instance.rejectOfficerRegistration(
          request.id,
          result['comment'] ?? 'Officer registration rejected',
        );

        if (success) {
          _showSuccessSnackBar('Officer registration rejected');
          _loadRegistrationRequests(); // Refresh the list
        } else {
          _showErrorSnackBar('Failed to reject officer registration');
        }
      } catch (e) {
        _showErrorSnackBar('Error rejecting officer registration: $e');
      }
    }
  }

  Widget _buildStatusChip(RegistrationStatus status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case RegistrationStatus.registered:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case RegistrationStatus.notified:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case RegistrationStatus.archived:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _markAsNotified(RegistrationRequest request) async {
    try {
      final success = await DatabaseService.instance.markRegistrationNotificationRead(request.id);

      if (success) {
        _showSuccessSnackBar('Registration marked as notified successfully!');
        _loadRegistrationRequests(); // Refresh the list
      } else {
        _showErrorSnackBar('Failed to mark registration as notified');
      }
    } catch (e) {
      _showErrorSnackBar('Error marking registration as notified: $e');
    }
  }

  Future<void> _archiveNotification(RegistrationRequest request) async {
    try {
      final success = await DatabaseService.instance.archiveRegistrationNotification(request.id);

      if (success) {
        _showSuccessSnackBar('Registration archived successfully!');
        _loadRegistrationRequests(); // Refresh the list
      } else {
        _showErrorSnackBar('Failed to archive registration');
      }
    } catch (e) {
      _showErrorSnackBar('Error archiving registration: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Approval/Rejection Dialog
class _ApprovalDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool isApproval;

  const _ApprovalDialog({
    required this.title,
    required this.message,
    required this.isApproval,
  });

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: widget.isApproval ? 'Approval Comment (Optional)' : 'Rejection Reason',
              hintText: widget.isApproval 
                  ? 'Enter any additional comments...'
                  : 'Please provide a reason for rejection...',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop({'confirmed': false}),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!widget.isApproval && _commentController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please provide a reason for rejection'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.of(context).pop({
              'confirmed': true,
              'comment': _commentController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isApproval ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isApproval ? 'Approve' : 'Reject'),
        ),
      ],
    );
  }
}