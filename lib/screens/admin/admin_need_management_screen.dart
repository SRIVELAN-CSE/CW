import 'package:flutter/material.dart';
import '../../models/need_request.dart';
import '../../services/database_service.dart';

class AdminNeedManagementScreen extends StatefulWidget {
  const AdminNeedManagementScreen({super.key});

  @override
  State<AdminNeedManagementScreen> createState() => _AdminNeedManagementScreenState();
}

class _AdminNeedManagementScreenState extends State<AdminNeedManagementScreen> with TickerProviderStateMixin {
  List<NeedRequest> _allRequests = [];
  List<NeedRequest> _filteredRequests = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedPriority = 'all';
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadNeedRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNeedRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final requests = await DatabaseService.instance.getAllNeedRequests();
      setState(() {
        _allRequests = requests;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<NeedRequest> filtered = List.from(_allRequests);

    // Filter by status
    if (_selectedFilter != 'all') {
      final targetStatus = _parseStatusFilter(_selectedFilter);
      if (targetStatus != null) {
        filtered = filtered.where((r) => r.status == targetStatus).toList();
      }
    }

    // Filter by priority
    if (_selectedPriority != 'all') {
      final targetPriority = _parsePriorityFilter(_selectedPriority);
      if (targetPriority != null) {
        filtered = filtered.where((r) => r.priority == targetPriority).toList();
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) => 
        r.title.toLowerCase().contains(query) ||
        r.description.toLowerCase().contains(query) ||
        r.location.toLowerCase().contains(query) ||
        r.requesterName.toLowerCase().contains(query)
      ).toList();
    }

    // Sort by created date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _filteredRequests = filtered;
    });
  }

  NeedStatus? _parseStatusFilter(String filter) {
    switch (filter) {
      case 'submitted': return NeedStatus.submitted;
      case 'under_review': return NeedStatus.underReview;
      case 'approved': return NeedStatus.approved;
      case 'in_progress': return NeedStatus.inProgress;
      case 'completed': return NeedStatus.completed;
      case 'rejected': return NeedStatus.rejected;
      default: return null;
    }
  }

  NeedPriority? _parsePriorityFilter(String filter) {
    switch (filter) {
      case 'low': return NeedPriority.low;
      case 'medium': return NeedPriority.medium;
      case 'high': return NeedPriority.high;
      case 'urgent': return NeedPriority.urgent;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Need Requests Management'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'All (${_getCountByStatus(null)})'),
            Tab(text: 'Pending (${_getCountByStatus(NeedStatus.submitted)})'),
            Tab(text: 'In Review (${_getCountByStatus(NeedStatus.underReview)})'),
            Tab(text: 'In Progress (${_getCountByStatus(NeedStatus.inProgress)})'),
            Tab(text: 'Completed (${_getCountByStatus(NeedStatus.completed)})'),
          ],
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0: _selectedFilter = 'all'; break;
                case 1: _selectedFilter = 'submitted'; break;
                case 2: _selectedFilter = 'under_review'; break;
                case 3: _selectedFilter = 'in_progress'; break;
                case 4: _selectedFilter = 'completed'; break;
              }
              _applyFilters();
            });
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search requests...',
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
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPriority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                            DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                            DropdownMenuItem(value: 'high', child: Text('High')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'low', child: Text('Low')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value!;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _loadNeedRequests,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Results Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${_filteredRequests.length} of ${_allRequests.length} requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Last updated: ${DateTime.now().toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Request List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRequests.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = _filteredRequests[index];
                            return _buildRequestCard(request);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCountByStatus(NeedStatus? status) {
    if (status == null) return _allRequests.length;
    return _allRequests.where((r) => r.status == status).length;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No requests found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(NeedRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(request.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPriorityLabel(request.priority),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(request.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Request Type Icon
                  Icon(
                    _getTypeIcon(request.needType),
                    color: Colors.indigo[600],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                request.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description (truncated)
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Location and Details Row
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${request.estimatedBeneficiaries} people',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Requester and Date Row
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    request.requesterName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(request.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              if (request.status == NeedStatus.submitted || request.status == NeedStatus.underReview)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showApprovalDialog(request),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateRequestStatus(request, NeedStatus.rejected),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(NeedPriority priority) {
    switch (priority) {
      case NeedPriority.low: return Colors.green;
      case NeedPriority.medium: return Colors.orange;
      case NeedPriority.high: return Colors.red;
      case NeedPriority.urgent: return Colors.red[800]!;
    }
  }

  String _getPriorityLabel(NeedPriority priority) {
    switch (priority) {
      case NeedPriority.low: return 'LOW';
      case NeedPriority.medium: return 'MEDIUM';
      case NeedPriority.high: return 'HIGH';
      case NeedPriority.urgent: return 'URGENT';
    }
  }

  Color _getStatusColor(NeedStatus status) {
    switch (status) {
      case NeedStatus.submitted: return Colors.blue;
      case NeedStatus.underReview: return Colors.orange;
      case NeedStatus.approved: return Colors.green;
      case NeedStatus.inProgress: return Colors.purple;
      case NeedStatus.completed: return Colors.indigo;
      case NeedStatus.rejected: return Colors.red;
    }
  }

  String _getStatusLabel(NeedStatus status) {
    switch (status) {
      case NeedStatus.submitted: return 'SUBMITTED';
      case NeedStatus.underReview: return 'UNDER REVIEW';
      case NeedStatus.approved: return 'APPROVED';
      case NeedStatus.inProgress: return 'IN PROGRESS';
      case NeedStatus.completed: return 'COMPLETED';
      case NeedStatus.rejected: return 'REJECTED';
    }
  }

  IconData _getTypeIcon(String needType) {
    switch (needType) {
      case NeedType.healthcare: return Icons.local_hospital;
      case NeedType.education: return Icons.school;
      case NeedType.infrastructure: return Icons.engineering;
      case NeedType.transportation: return Icons.directions_bus;
      case NeedType.safety: return Icons.security;
      case NeedType.environment: return Icons.eco;
      case NeedType.utilities: return Icons.electrical_services;
      case NeedType.social: return Icons.people;
      default: return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showRequestDetails(NeedRequest request) {
    showDialog(
      context: context,
      builder: (context) => _RequestDetailsDialog(
        request: request,
        onStatusUpdate: (newStatus) {
          if (newStatus == NeedStatus.approved) {
            Navigator.pop(context); // Close details dialog first
            _showApprovalDialog(request); // Then show approval dialog
          } else {
            _updateRequestStatus(request, newStatus);
          }
        },
      ),
    );
  }

  void _showApprovalDialog(NeedRequest request) {
    showDialog(
      context: context,
      builder: (context) => _ApprovalDialog(
        request: request,
        onApprove: (estimatedDays, timeline) async {
          await DatabaseService.instance.updateNeedRequestStatus(
            request.id,
            NeedStatus.approved,
            adminNotes: 'Approved by admin with timeline: $timeline',
            estimatedImplementationDays: estimatedDays,
            implementationTimeline: timeline,
          );
          
          await _loadNeedRequests(); // Reload data
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Request approved and citizen notified!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _updateRequestStatus(NeedRequest request, NeedStatus newStatus) async {
    try {
      await DatabaseService.instance.updateNeedRequestStatus(
        request.id,
        newStatus,
        adminNotes: 'Status updated by admin',
      );
      
      await _loadNeedRequests(); // Reload data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${_getStatusLabel(newStatus).toLowerCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _RequestDetailsDialog extends StatefulWidget {
  final NeedRequest request;
  final Function(NeedStatus) onStatusUpdate;

  const _RequestDetailsDialog({
    required this.request,
    required this.onStatusUpdate,
  });

  @override
  State<_RequestDetailsDialog> createState() => _RequestDetailsDialogState();
}

class _RequestDetailsDialogState extends State<_RequestDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(widget.request.needType),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.request.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and Priority Row
                    Row(
                      children: [
                        _buildInfoChip(
                          'Priority',
                          _getPriorityLabel(widget.request.priority),
                          _getPriorityColor(widget.request.priority),
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          'Status',
                          _getStatusLabel(widget.request.status),
                          _getStatusColor(widget.request.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildDetailSection('Description', widget.request.description),
                    
                    // Facility Type
                    _buildDetailSection('Facility Type', 
                      NeedType.displayNames[widget.request.needType] ?? widget.request.needType),

                    // Location
                    _buildDetailSection('Location', widget.request.location),

                    // Address (if provided)
                    if (widget.request.address != null)
                      _buildDetailSection('Address', widget.request.address!),

                    // Estimated Beneficiaries
                    _buildDetailSection('Estimated Beneficiaries', 
                      '${widget.request.estimatedBeneficiaries} people'),

                    // Justification (if provided)
                    if (widget.request.justification != null)
                      _buildDetailSection('Justification', widget.request.justification!),

                    // Requester Information
                    _buildDetailSection('Requested By', widget.request.requesterName),
                    
                    if (widget.request.requesterEmail.isNotEmpty)
                      _buildDetailSection('Email', widget.request.requesterEmail),

                    // Dates
                    _buildDetailSection('Submitted On', 
                      '${widget.request.createdAt.toString().split('.')[0]} UTC'),

                    if (widget.request.updatedAt != null)
                      _buildDetailSection('Last Updated', 
                        '${widget.request.updatedAt.toString().split('.')[0]} UTC'),

                    // Admin Notes (if any)
                    if (widget.request.adminNotes != null)
                      _buildDetailSection('Admin Notes', widget.request.adminNotes!),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (widget.request.status == NeedStatus.submitted ||
                      widget.request.status == NeedStatus.underReview) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onStatusUpdate(NeedStatus.approved);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.onStatusUpdate(NeedStatus.rejected);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ] else if (widget.request.status == NeedStatus.approved) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onStatusUpdate(NeedStatus.inProgress);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Progress'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else if (widget.request.status == NeedStatus.inProgress) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onStatusUpdate(NeedStatus.completed);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String needType) {
    switch (needType) {
      case NeedType.healthcare: return Icons.local_hospital;
      case NeedType.education: return Icons.school;
      case NeedType.infrastructure: return Icons.engineering;
      case NeedType.transportation: return Icons.directions_bus;
      case NeedType.safety: return Icons.security;
      case NeedType.environment: return Icons.eco;
      case NeedType.utilities: return Icons.electrical_services;
      case NeedType.social: return Icons.people;
      default: return Icons.category;
    }
  }

  Color _getPriorityColor(NeedPriority priority) {
    switch (priority) {
      case NeedPriority.low: return Colors.green;
      case NeedPriority.medium: return Colors.orange;
      case NeedPriority.high: return Colors.red;
      case NeedPriority.urgent: return Colors.red[800]!;
    }
  }

  String _getPriorityLabel(NeedPriority priority) {
    switch (priority) {
      case NeedPriority.low: return 'LOW';
      case NeedPriority.medium: return 'MEDIUM';
      case NeedPriority.high: return 'HIGH';
      case NeedPriority.urgent: return 'URGENT';
    }
  }

  Color _getStatusColor(NeedStatus status) {
    switch (status) {
      case NeedStatus.submitted: return Colors.blue;
      case NeedStatus.underReview: return Colors.orange;
      case NeedStatus.approved: return Colors.green;
      case NeedStatus.inProgress: return Colors.purple;
      case NeedStatus.completed: return Colors.indigo;
      case NeedStatus.rejected: return Colors.red;
    }
  }

  String _getStatusLabel(NeedStatus status) {
    switch (status) {
      case NeedStatus.submitted: return 'SUBMITTED';
      case NeedStatus.underReview: return 'UNDER REVIEW';
      case NeedStatus.approved: return 'APPROVED';
      case NeedStatus.inProgress: return 'IN PROGRESS';
      case NeedStatus.completed: return 'COMPLETED';
      case NeedStatus.rejected: return 'REJECTED';
    }
  }
}

class _ApprovalDialog extends StatefulWidget {
  final NeedRequest request;
  final Function(int estimatedDays, String timeline) onApprove;

  const _ApprovalDialog({
    required this.request,
    required this.onApprove,
  });

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _daysController = TextEditingController();
  final _timelineController = TextEditingController();
  String _selectedTimeframe = '30'; // Default 30 days
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _daysController.text = _selectedTimeframe;
    _updateTimelineText();
  }

  @override
  void dispose() {
    _daysController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  void _updateTimelineText() {
    final days = int.tryParse(_selectedTimeframe) ?? 30;
    final completionDate = DateTime.now().add(Duration(days: days));
    final formattedDate = '${completionDate.day}/${completionDate.month}/${completionDate.year}';
    
    String timelineText;
    if (days <= 7) {
      timelineText = 'Implementation will begin immediately and complete within $days days (by $formattedDate).';
    } else if (days <= 30) {
      timelineText = 'Implementation will begin within 1-2 weeks and complete within $days days (by $formattedDate).';
    } else if (days <= 90) {
      timelineText = 'Implementation will begin within 3-4 weeks and complete within $days days (by $formattedDate).';
    } else {
      timelineText = 'Implementation will begin within 1-2 months and complete within $days days (by $formattedDate).';
    }
    
    _timelineController.text = timelineText;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Approve Facility Request',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Request Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested by: ${widget.request.requesterName}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Location: ${widget.request.location}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Beneficiaries: ${widget.request.estimatedBeneficiaries} people',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Implementation Timeline Section
            Text(
              'Implementation Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Specify how long the implementation will take. The citizen will be notified with this timeline.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Quick Options
            Text(
              'Quick Timeline Options',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _TimelineChip('7', '1 Week'),
                _TimelineChip('14', '2 Weeks'),
                _TimelineChip('30', '1 Month'),
                _TimelineChip('60', '2 Months'),
                _TimelineChip('90', '3 Months'),
                _TimelineChip('180', '6 Months'),
              ],
            ),
            const SizedBox(height: 16),

            // Custom Days Input
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _daysController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Days',
                      border: OutlineInputBorder(),
                      suffixText: 'days',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeframe = value;
                        _updateTimelineText();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Expected completion: ${_getCompletionDate()}',
                    style: TextStyle(
                      color: Colors.indigo[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline Message
            TextFormField(
              controller: _timelineController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Timeline Message (will be sent to citizen)',
                border: OutlineInputBorder(),
                helperText: 'This message will be included in the approval notification',
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleApproval,
                    icon: _isSubmitting 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSubmitting ? 'Approving...' : 'Approve & Notify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _TimelineChip(String days, String label) {
    final isSelected = _selectedTimeframe == days;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTimeframe = days;
            _daysController.text = days;
            _updateTimelineText();
          });
        }
      },
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
    );
  }

  String _getCompletionDate() {
    final days = int.tryParse(_selectedTimeframe) ?? 30;
    final completionDate = DateTime.now().add(Duration(days: days));
    return '${completionDate.day}/${completionDate.month}/${completionDate.year}';
  }

  Future<void> _handleApproval() async {
    if (_timelineController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a timeline message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final estimatedDays = int.tryParse(_selectedTimeframe) ?? 30;
      await widget.onApprove(estimatedDays, _timelineController.text.trim());
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}