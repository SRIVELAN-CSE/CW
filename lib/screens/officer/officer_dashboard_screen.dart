import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/report.dart';
import '../../models/registration_request.dart';
import '../../core/utils/image_display_helper.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _selectedIndex = 0;

  // Controllers for user input
  final _commentController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  List<Widget> get _pages => [
    const OfficerHome(),
    AssignedIssuesScreen(onUpdateStatus: _showUpdateStatusDialog),
    const DepartmentReportsScreen(),
    const OfficerProfileScreen(),
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, String>?>(
          future: DatabaseService.instance.getCurrentUserSession(),
          builder: (context, snapshot) {
            final department = snapshot.data?['department'];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Officer Portal'),
                if (department != null && department.isNotEmpty)
                  Text(
                    department,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
              ],
            );
          },
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // Debug session button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSessionDebugDialog(context),
            tooltip: 'Debug Session',
          ),
          FutureBuilder<Map<String, String>?>(
            future: DatabaseService.instance.getCurrentUserSession(),
            builder: (context, snapshot) {
              final userSession = snapshot.data;
              return NotificationWidget(
                userRole: userSession?['userRole'] ?? 'officer',
                userId: userSession?['userId'] ?? 'unknown',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'My Issues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _showSessionDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Debug Info'),
          content: FutureBuilder<Map<String, String>?>(
            future: DatabaseService.instance.getCurrentUserSession(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              final session = snapshot.data;
              if (session == null) {
                return const Text('No session found');
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User ID: ${session['userId']}'),
                  Text('Name: ${session['userName']}'),
                  Text('Email: ${session['userEmail']}'),
                  Text('Role: ${session['userRole']}'),
                  Text('Department: ${session['department']}'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await DatabaseService.instance.clearUserSession();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session cleared! Please re-login.'),
                  ),
                );
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Clear & Re-login'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                try {
                  // Clear user session from localStorage/SharedPreferences
                  await DatabaseService.instance.clearUserSession();

                  // Navigate to home screen and clear navigation stack
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                } catch (e) {
                  // Show error if logout fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateStatusDialog(
    BuildContext context,
    String reportId,
    String currentStatus,
  ) {
    final statusOptions = ['NOT SEEN', 'RESOLVE SOON', 'IN PROGRESS', 'DONE'];

    // Map current status to valid officer status or default to NOT SEEN
    String selectedStatus;
    if (statusOptions.contains(currentStatus)) {
      selectedStatus = currentStatus;
    } else {
      // If current status is not in officer options (like "Submitted"), default to "NOT SEEN"
      selectedStatus = 'NOT SEEN';
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Status - $reportId'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Status: $currentStatus'),
                  const SizedBox(height: 8),
                  const Text('Select new status:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Status',
                    ),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Comments (Optional)',
                      hintText: 'Add your comments here...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _commentController.clear();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save the status update
                    _updateIssueStatus(
                      reportId,
                      selectedStatus,
                      _commentController.text,
                    );
                    _commentController.clear();
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Status updated to $selectedStatus for $reportId',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateIssueStatus(
    String reportId,
    String newStatus,
    String comment,
  ) async {
    try {
      // Get the current report
      final report = await DatabaseService.instance.getReportById(reportId);
      if (report != null) {
        // Map status string to enum
        ReportStatus status;
        switch (newStatus) {
          case 'NOT SEEN':
            status = ReportStatus.notSeen;
            break;
          case 'RESOLVE SOON':
            status = ReportStatus.resolveSoon;
            break;
          case 'IN PROGRESS':
            status = ReportStatus.inProgress;
            break;
          case 'DONE':
            status = ReportStatus.done;
            break;
          default:
            status = ReportStatus.submitted;
        }

        // Update the report status
        final updatedReport = report.copyWith(
          status: status,
          updatedAt: DateTime.now(),
          updates: [
            ...report.updates,
            ReportUpdate(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              message: comment.isNotEmpty
                  ? comment
                  : 'Status updated to $newStatus',
              timestamp: DateTime.now(),
              updatedBy:
                  (await DatabaseService.instance
                      .getCurrentUserSession())?['userName'] ??
                  'Officer',
              updatedByRole: 'officer',
              statusChange: status,
            ),
          ],
        );

        // Save the updated report
        await DatabaseService.instance.updateReport(updatedReport);

        // Create notification for the citizen who submitted the report
        await DatabaseService.instance.createStatusUpdateNotification(
          reportId: reportId,
          reportTitle: report.title,
          reporterId: report.reporterId,
          newStatus: newStatus,
          officerName:
              (await DatabaseService.instance
                  .getCurrentUserSession())?['userName'] ??
              'Officer',
          comment: comment,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report $reportId status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Officer Home Dashboard
class OfficerHome extends StatefulWidget {
  const OfficerHome({super.key});

  @override
  State<OfficerHome> createState() => _OfficerHomeState();
}

class _OfficerHomeState extends State<OfficerHome> {
  List<Report> allReports = [];
  Map<String, int> reportStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user session to fetch department
      final userSession = await DatabaseService.instance
          .getCurrentUserSession();
      final department = userSession?['department'];

      List<Report> reports;
      if (department != null && department.isNotEmpty) {
        // Load only reports for the officer's department
        reports = await DatabaseService.instance.getReportsByDepartment(
          department,
        );
        print(
          '🏠 Officer Home: Loaded ${reports.length} reports for department: $department',
        );
      } else {
        // Fallback to all reports if department not found
        reports = await DatabaseService.instance.getAllReports();
        print('⚠️ Officer Home: Department not found, showing all reports');
      }

      final stats = await DatabaseService.instance.getReportStatistics();

      setState(() {
        allReports = reports;
        reportStats = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.badge, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<RegistrationRequest?>(
                      future: DatabaseService.instance
                          .getCurrentUserRegistrationData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Loading...'),
                              Text('Fetching user data...'),
                            ],
                          );
                        }

                        final userData = snapshot.data;
                        if (userData == null) {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome, Officer'),
                              Text('Department: Not specified'),
                              Text('Status: Active'),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${userData.fullName}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${userData.department ?? 'General Department'}',
                            ),
                            Text('ID: ${userData.idNumber}'),
                            if (userData.designation != null)
                              Text('${userData.designation}'),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Overview
          Text(
            'Today\'s Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Issues',
                  value: '${reportStats['total'] ?? 0}',
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'New',
                  value: '${reportStats['submitted'] ?? 0}',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: 'Done',
                  value: '${reportStats['done'] ?? 0}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Priority Issues
          Text('Recent Reports', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...allReports
              .where(
                (report) =>
                    report.priority == 'High' || report.priority == 'Critical',
              )
              .take(5)
              .map(
                (report) => _PriorityIssueCard(
                  title: report.title,
                  location: report.location,
                  priority: report.priority,
                  priorityColor: _getPriorityColor(report.priority),
                  timeAgo: _formatDate(report.createdAt),
                  reportId: '#${report.id}',
                ),
              ),
          const SizedBox(height: 16),

          // Quick Actions
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_task,
                  title: 'Update Status',
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Update Status - Coming Soon!'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.location_on,
                  title: 'Field Visit',
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Field Visit - Coming Soon!'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.report,
                  title: 'Generate Report',
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generate Report - Coming Soon!'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ActivityItem(
              icon: Icons.check_circle,
              title: 'Completed: Pothole Repair',
              subtitle: 'Park Avenue - 2 hours ago',
              color: Colors.green,
            ),
            const Divider(),
            _ActivityItem(
              icon: Icons.update,
              title: 'Updated: Street Cleaning',
              subtitle: 'Sector 3 - Status: In Progress',
              color: Colors.blue,
            ),
            const Divider(),
            _ActivityItem(
              icon: Icons.assignment,
              title: 'Assigned: New Issue',
              subtitle: 'Traffic Signal Malfunction',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

// Assigned Issues Screen
class AssignedIssuesScreen extends StatefulWidget {
  final Function(BuildContext, String, String)? onUpdateStatus;

  const AssignedIssuesScreen({super.key, this.onUpdateStatus});

  @override
  State<AssignedIssuesScreen> createState() => _AssignedIssuesScreenState();
}

class _AssignedIssuesScreenState extends State<AssignedIssuesScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Submitted',
    'NOT SEEN',
    'RESOLVE SOON',
    'IN PROGRESS',
    'DONE',
  ];
  List<Report> allReports = [];
  List<Report> filteredReports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user session to fetch department
      final userSession = await DatabaseService.instance
          .getCurrentUserSession();
      final department = userSession?['department'];

      List<Report> reports;
      if (department != null && department.isNotEmpty) {
        // Load only reports for the officer's department
        reports = await DatabaseService.instance.getReportsByDepartment(
          department,
        );
        print(
          '🔍 Loaded ${reports.length} reports for department: $department',
        );
      } else {
        // Fallback to all reports if department not found
        reports = await DatabaseService.instance.getAllReports();
        print('⚠️ Department not found in session, showing all reports');
      }

      setState(() {
        allReports = reports;
        _filterReports();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterReports() {
    if (_selectedFilter == 'All') {
      filteredReports = allReports;
    } else {
      ReportStatus? status;
      switch (_selectedFilter) {
        case 'Submitted':
          status = ReportStatus.submitted;
          break;
        case 'NOT SEEN':
          status = ReportStatus.notSeen;
          break;
        case 'RESOLVE SOON':
          status = ReportStatus.resolveSoon;
          break;
        case 'IN PROGRESS':
          status = ReportStatus.inProgress;
          break;
        case 'DONE':
          status = ReportStatus.done;
          break;
      }
      if (status != null) {
        filteredReports = allReports
            .where((report) => report.status == status)
            .toList();
      }
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return Colors.blue;
      case ReportStatus.notSeen:
        return Colors.grey;
      case ReportStatus.resolveSoon:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.purple;
      case ReportStatus.done:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.closed:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Text('Filter Issues', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _filterReports();
                      });
                    },
                    selectedColor: Colors.green.withOpacity(0.3),
                    checkmarkColor: Colors.green,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Issues List
          Text(
            'Assigned Issues ($_selectedFilter)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedFilter issues found',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Issues will appear here when citizens submit reports',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return _IssueCard(
                        report: report,
                        onUpdateStatus: widget.onUpdateStatus,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Department Reports Screen
class DepartmentReportsScreen extends StatefulWidget {
  const DepartmentReportsScreen({super.key});

  @override
  State<DepartmentReportsScreen> createState() =>
      _DepartmentReportsScreenState();
}

class _DepartmentReportsScreenState extends State<DepartmentReportsScreen> {
  bool isLoading = true;
  String? department;
  Map<String, int> departmentStats = {
    'total': 0,
    'completed': 0,
    'inProgress': 0,
    'pending': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDepartmentStats();
  }

  Future<void> _loadDepartmentStats() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user's department
      final userSession = await DatabaseService.instance
          .getCurrentUserSession();
      department = userSession?['department'];

      if (department != null && department!.isNotEmpty) {
        // Get all reports for this department
        final reports = await DatabaseService.instance.getReportsByDepartment(
          department!,
        );

        int total = reports.length;
        int completed = reports
            .where((r) => r.status == ReportStatus.done)
            .length;
        int inProgress = reports
            .where((r) => r.status == ReportStatus.inProgress)
            .length;
        int pending = reports
            .where(
              (r) =>
                  r.status == ReportStatus.submitted ||
                  r.status == ReportStatus.notSeen ||
                  r.status == ReportStatus.resolveSoon,
            )
            .length;

        setState(() {
          departmentStats = {
            'total': total,
            'completed': completed,
            'inProgress': inProgress,
            'pending': pending,
          };
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading department stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (department != null && department!.isNotEmpty)
            Text(
              department!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 16),

          // Monthly Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Department Performance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ReportStatCard(
                          title: 'Total Issues',
                          value: '${departmentStats['total']}',
                          change: 'Live Data',
                          isPositive: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ReportStatCard(
                          title: 'Completed',
                          value: '${departmentStats['completed']}',
                          change: 'Live Data',
                          isPositive: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ReportStatCard(
                          title: 'In Progress',
                          value: '${departmentStats['inProgress']}',
                          change: 'Live Data',
                          isPositive: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ReportStatCard(
                          title: 'Pending',
                          value: '${departmentStats['pending']}',
                          change: 'Live Data',
                          isPositive: departmentStats['pending'] == 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Report Actions
          Text(
            'Generate Reports',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _ReportActionCard(
                  title: 'Daily Summary',
                  icon: Icons.today,
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Daily Summary - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ReportActionCard(
                  title: 'Weekly Report',
                  icon: Icons.date_range,
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weekly Report - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ReportActionCard(
                  title: 'Performance',
                  icon: Icons.analytics,
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Performance Report - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ReportActionCard(
                  title: 'Export Data',
                  icon: Icons.download,
                  color: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export Data - Coming Soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Officer Profile Screen
class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({super.key});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  bool isLoading = true;
  RegistrationRequest? userRegistrationData;
  Map<String, String>? userSession;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Get user session
      userSession = await DatabaseService.instance.getCurrentUserSession();

      // Get registration data
      userRegistrationData = await DatabaseService.instance
          .getCurrentUserRegistrationData();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading profile: $e';
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfileData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final regData = userRegistrationData;
    final session = userSession;

    // If no registration data, show basic session info
    final displayName =
        regData?.fullName ?? session?['userName'] ?? 'Unknown User';
    final displayEmail = regData?.email ?? session?['userEmail'] ?? 'No email';
    final displayDepartment =
        regData?.department ?? session?['department'] ?? 'Unknown Department';
    final displayPhone = regData?.phone ?? 'Not provided';
    final displayAddress = regData?.address ?? 'Not provided';
    final displayDesignation = regData?.designation ?? 'Officer';
    final joinDate = regData?.requestDate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(displayDepartment),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ${regData?.id ?? session?['userId'] ?? 'Unknown'}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Profile Details
          _ProfileDetailCard(
            title: 'Contact Information',
            items: [
              _ProfileItem(
                icon: Icons.email,
                label: 'Email',
                value: displayEmail,
              ),
              _ProfileItem(
                icon: Icons.phone,
                label: 'Phone',
                value: displayPhone,
              ),
              _ProfileItem(
                icon: Icons.location_on,
                label: 'Address',
                value: displayAddress,
              ),
            ],
          ),
          _ProfileDetailCard(
            title: 'Department Details',
            items: [
              _ProfileItem(
                icon: Icons.business,
                label: 'Department',
                value: displayDepartment,
              ),
              _ProfileItem(
                icon: Icons.work,
                label: 'Designation',
                value: displayDesignation,
              ),
              _ProfileItem(
                icon: Icons.date_range,
                label: 'Joined',
                value: _formatDate(joinDate),
              ),
            ],
          ),

          // Data Source Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Source',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        regData != null ? Icons.cloud_done : Icons.storage,
                        color: regData != null ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        regData != null
                            ? 'Registration Database'
                            : 'Session Data Only',
                        style: TextStyle(
                          color: regData != null ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (regData == null)
                    const Text(
                      'Some profile details may be limited. Please ensure your registration is complete.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityIssueCard extends StatelessWidget {
  final String title;
  final String location;
  final String priority;
  final Color priorityColor;
  final String timeAgo;
  final String reportId;

  const _PriorityIssueCard({
    required this.title,
    required this.location,
    required this.priority,
    required this.priorityColor,
    required this.timeAgo,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.priority_high, color: priorityColor),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: priorityColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(color: priorityColor, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Text(timeAgo, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Text(
          reportId,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _IssueCard extends StatelessWidget {
  final Report report;
  final Function(BuildContext, String, String)? onUpdateStatus;

  const _IssueCard({required this.report, this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.status);
    final formattedDate = _formatDate(report.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(report.title),
        subtitle: Text(report.location),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.report_problem, color: statusColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${report.description}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Priority: ${report.priority}'),
                    const Spacer(),
                    Text('Reported: $formattedDate'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        report.status.displayName,
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      report.id,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Display images if available
                if (report.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Attached Images:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ImageDisplayHelper.displayImageGrid(
                      report.imageUrls,
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportDetailScreen(reportId: report.id),
                            ),
                          );
                        },
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (onUpdateStatus != null) {
                            onUpdateStatus!(
                              context,
                              report.id,
                              report.status.displayName,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Update Status - Coming Soon!'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return Colors.blue;
      case ReportStatus.notSeen:
        return Colors.grey;
      case ReportStatus.resolveSoon:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.purple;
      case ReportStatus.done:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.closed:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _ReportStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;

  const _ReportStatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailCard extends StatelessWidget {
  final String title;
  final List<_ProfileItem> items;

  const _ProfileDetailCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(item.icon, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      '${item.label}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(item.value),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

// Report Detail Screen for Officers
class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Report? report;
  bool isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedReport = await DatabaseService.instance.getReportById(
        widget.reportId,
      );
      setState(() {
        report = loadedReport;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return Colors.blue;
      case ReportStatus.notSeen:
        return Colors.grey;
      case ReportStatus.resolveSoon:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.purple;
      case ReportStatus.done:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showUpdateStatusDialog() {
    if (report == null) return;

    final statusOptions = ['NOT SEEN', 'RESOLVE SOON', 'IN PROGRESS', 'DONE'];
    final currentStatusDisplay = report!.status.displayName;

    // Map current status to valid officer status or default to NOT SEEN
    String selectedStatus;
    if (statusOptions.contains(currentStatusDisplay)) {
      selectedStatus = currentStatusDisplay;
    } else {
      // If current status is not in officer options (like "Submitted"), default to "NOT SEEN"
      selectedStatus = 'NOT SEEN';
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Status - ${report!.id}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Status: $currentStatusDisplay'),
                  const SizedBox(height: 8),
                  const Text('Select new status:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Status',
                    ),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Comments (Optional)',
                      hintText: 'Add your comments here...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _commentController.clear();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateReportStatus(
                      selectedStatus,
                      _commentController.text,
                    );
                    _commentController.clear();
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateReportStatus(String newStatus, String comment) async {
    if (report == null) return;

    try {
      // Map status string to enum
      ReportStatus status;
      switch (newStatus) {
        case 'NOT SEEN':
          status = ReportStatus.notSeen;
          break;
        case 'RESOLVE SOON':
          status = ReportStatus.resolveSoon;
          break;
        case 'IN PROGRESS':
          status = ReportStatus.inProgress;
          break;
        case 'DONE':
          status = ReportStatus.done;
          break;
        default:
          status = ReportStatus.submitted;
      }

      // Get current user session for officer information
      final userSession = await DatabaseService.instance
          .getCurrentUserSession();
      final officerName = userSession?['userName'] ?? 'Officer';

      // For completed reports, include additional completion details
      String statusMessage = comment.isNotEmpty
          ? comment
          : 'Status updated to $newStatus';
      if (newStatus == 'DONE') {
        statusMessage = comment.isNotEmpty
            ? 'Issue resolved: $comment'
            : 'Issue has been successfully resolved by $officerName from ${report!.department} department';
      }

      // Update the report status
      final updatedReport = report!.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        assignedOfficerName: officerName, // Ensure officer name is recorded
        updates: [
          ...report!.updates,
          ReportUpdate(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            message: statusMessage,
            timestamp: DateTime.now(),
            updatedBy: officerName,
            updatedByRole: 'officer',
            statusChange: status,
          ),
        ],
      );

      // Save the updated report
      await DatabaseService.instance.updateReport(updatedReport);

      // Create notification for the citizen who submitted the report
      await DatabaseService.instance.createStatusUpdateNotification(
        reportId: report!.id,
        reportTitle: report!.title,
        reporterId: report!.reporterId,
        newStatus: newStatus,
        officerName: officerName,
        comment: comment,
      );

      // If report is completed, create additional notification for admin analytics
      if (newStatus == 'DONE') {
        try {
          await DatabaseService.instance.createCompletionNotification(
            reportId: report!.id,
            reportTitle: report!.title,
            department: report!.department,
            officerName: officerName,
            completionTime: DateTime.now(),
            resolutionComment: comment,
          );
        } catch (e) {
          print('Warning: Could not create completion notification: $e');
          // Continue execution - this is not critical
        }
      }

      // Reload the report to show updated data
      await _loadReport();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'DONE'
                  ? 'Report completed successfully! 🎉'
                  : 'Report status updated to $newStatus',
            ),
            backgroundColor: newStatus == 'DONE' ? Colors.green : Colors.blue,
            duration: Duration(seconds: newStatus == 'DONE' ? 4 : 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details - ${widget.reportId}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (report != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showUpdateStatusDialog,
              tooltip: 'Update Status',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : report == null
          ? const Center(
              child: Text(
                'Report not found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and Priority Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info,
                                      color: _getStatusColor(report!.status),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      report!.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        report!.status,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    report!.status.displayName,
                                    style: TextStyle(
                                      color: _getStatusColor(report!.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.priority_high,
                                      color: _getPriorityColor(
                                        report!.priority,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Priority',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(
                                      report!.priority,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getPriorityColor(
                                        report!.priority,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    report!.priority,
                                    style: TextStyle(
                                      color: _getPriorityColor(
                                        report!.priority,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Report Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Information',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            icon: Icons.title,
                            label: 'Title',
                            value: report!.title,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.description,
                            label: 'Description',
                            value: report!.description,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.category,
                            label: 'Category',
                            value: report!.category,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.location_on,
                            label: 'Location',
                            value: report!.location,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.domain,
                            label: 'Department',
                            value: report!.department,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reporter Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reporter Information',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            icon: Icons.person,
                            label: 'Name',
                            value: report!.reporterName,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: report!.reporterEmail,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.access_time,
                            label: 'Reported At',
                            value:
                                '${report!.createdAt.day}/${report!.createdAt.month}/${report!.createdAt.year} at ${report!.createdAt.hour}:${report!.createdAt.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Department Contact Information
                  if (report!.departmentContact.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Department Contact',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            if (report!.departmentContact['phone'] != null)
                              _DetailRow(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: report!.departmentContact['phone']!,
                              ),
                            if (report!.departmentContact['email'] != null) ...[
                              const SizedBox(height: 12),
                              _DetailRow(
                                icon: Icons.email,
                                label: 'Email',
                                value: report!.departmentContact['email']!,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.schedule,
                              label: 'Estimated Resolution',
                              value: report!.estimatedResolutionTime,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Status Updates History
                  if (report!.updates.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Updates History',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ...report!.updates.map(
                              (update) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.update,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            update.updatedBy,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${update.timestamp.day}/${update.timestamp.month}/${update.timestamp.year}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(update.message),
                                      if (update.statusChange != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Status changed to: ${update.statusChange!.displayName}',
                                          style: TextStyle(
                                            color: _getStatusColor(
                                              update.statusChange!,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Update Status Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showUpdateStatusDialog,
                      icon: const Icon(Icons.edit),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
