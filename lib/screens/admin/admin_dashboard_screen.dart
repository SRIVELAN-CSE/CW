import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/report.dart';
import '../../models/need_request.dart';
import '../../models/registration_request.dart';
import 'registration_management_screen.dart';
import 'password_reset_management_screen.dart';
import 'admin_need_management_screen.dart';
import 'developer_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Controllers for admin input operations
  final _userSearchController = TextEditingController();
  final _systemMessageController = TextEditingController();
  final _announceController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();

  List<Widget> get _pages => [
    const AdminOverview(),
    SystemManagementScreen(onSystemMessage: _showSystemMessageDialog),
    UserManagementScreen(onAddUser: _showAddUserDialog),
    const RegistrationManagementScreen(),
    const PasswordResetManagementScreen(),
    const AnalyticsScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  void dispose() {
    _userSearchController.dispose();
    _systemMessageController.dispose();
    _announceController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Panel'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () {
              _showSecurityCenter(context);
            },
          ),
          NotificationWidget(
            userRole: 'admin',
            userId: 'admin_001', // TODO: Get from actual user session
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
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'System'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg),
            label: 'Registrations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_reset),
            label: 'Password Resets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showSecurityCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Center',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _SecurityItem(
                title: 'System Status',
                value: 'Secure',
                color: Colors.green,
                icon: Icons.security,
              ),
              _SecurityItem(
                title: 'Active Sessions',
                value: '24 Users',
                color: Colors.blue,
                icon: Icons.people,
              ),
              _SecurityItem(
                title: 'Failed Logins',
                value: '3 Today',
                color: Colors.orange,
                icon: Icons.warning,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Admin Logout'),
          content: const Text(
            'Are you sure you want to logout from the admin panel?',
          ),
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

  void _showAddUserDialog(BuildContext context) {
    String selectedRole = 'Public';
    final roles = ['Public', 'Officer', 'Admin'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'User Role',
                        prefixIcon: Icon(Icons.security),
                      ),
                      items: roles.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                    if (selectedRole == 'Officer') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.domain),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearUserForm();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _createNewUser(selectedRole);
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text(
                    'Create User',
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

  void _clearUserForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _departmentController.clear();
  }

  void _createNewUser(String role) {
    // This would typically create a new user in the backend
    print('Creating user: ${_nameController.text}, Role: $role');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User ${_nameController.text} created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    _clearUserForm();
  }

  void _showSystemMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Send System Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _systemMessageController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Message Title',
                  hintText: 'Enter message title...',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _announceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Message Content',
                  hintText: 'Enter your announcement...',
                ),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _systemMessageController.clear();
                _announceController.clear();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _sendSystemMessage();
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Send', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _sendSystemMessage() {
    // This would typically send a system-wide message
    print('Sending message: ${_systemMessageController.text}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System message sent successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    _systemMessageController.clear();
    _announceController.clear();
  }
}

// Admin Overview Screen
class AdminOverview extends StatefulWidget {
  const AdminOverview({super.key});

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  Map<String, int> reportStats = {};
  Map<String, int> needRequestStats = {};
  Map<String, dynamic> certificateAnalytics = {};
  List<Report> allReports = [];
  List<NeedRequest> allNeedRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final reports = await DatabaseService.instance.getAllReports();
      final stats = await DatabaseService.instance.getReportStatistics();
      final needRequests = await DatabaseService.instance.getAllNeedRequests();
      final certAnalytics = await DatabaseService.instance.getCertificateAnalytics();

      // Calculate need request statistics
      final needStats = <String, int>{
        'total': needRequests.length,
        'submitted': needRequests
            .where((r) => r.status == NeedStatus.submitted)
            .length,
        'under_review': needRequests
            .where((r) => r.status == NeedStatus.underReview)
            .length,
        'approved': needRequests
            .where((r) => r.status == NeedStatus.approved)
            .length,
        'in_progress': needRequests
            .where((r) => r.status == NeedStatus.inProgress)
            .length,
        'completed': needRequests
            .where((r) => r.status == NeedStatus.completed)
            .length,
        'rejected': needRequests
            .where((r) => r.status == NeedStatus.rejected)
            .length,
      };

      if (!mounted) return;
      setState(() {
        allReports = reports;
        allNeedRequests = needRequests;
        reportStats = stats;
        needRequestStats = needStats;
        certificateAnalytics = certAnalytics;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
          // Welcome Header
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, Administrator',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Text('System Administrator'),
                        const Text('Last login: Today, 09:30 AM'),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.green),
                        const SizedBox(width: 4),
                        const Text(
                          'System Online',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // System Overview Stats
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.3,
            children: [
              _OverviewCard(
                title: 'Total Issues',
                value: '${reportStats['total'] ?? 0}',
                change: '+12.5%',
                icon: Icons.report_problem,
                color: Colors.blue,
                isPositive: true,
              ),
              _OverviewCard(
                title: 'New Reports',
                value: '${reportStats['submitted'] ?? 0}',
                change: '+8.3%',
                icon: Icons.new_releases,
                color: Colors.orange,
                isPositive: true,
              ),
              _OverviewCard(
                title: 'In Progress',
                value: '${reportStats['inProgress'] ?? 0}',
                change: '+2.1%',
                icon: Icons.work,
                color: Colors.purple,
                isPositive: true,
              ),
              _OverviewCard(
                title: 'Facility Requests',
                value: '${needRequestStats['total'] ?? 0}',
                change: 'New',
                icon: Icons.add_location_alt,
                color: Colors.indigo,
                isPositive: true,
              ),
              _OverviewCard(
                title: 'Pending Needs',
                value: '${needRequestStats['submitted'] ?? 0}',
                change: 'Action Required',
                icon: Icons.pending_actions,
                color: Colors.red,
                isPositive: false,
              ),
              _OverviewCard(
                title: 'Completed',
                value:
                    '${(reportStats['done'] ?? 0) + (needRequestStats['completed'] ?? 0)}',
                change: '+15.7%',
                icon: Icons.check_circle,
                color: Colors.green,
                isPositive: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Need Requests Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Facility Requests Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNeedManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (needRequestStats['total'] != null &&
              needRequestStats['total']! > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_location_alt,
                          color: Colors.indigo[600],
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Citizen Facility Requests',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Citizens are requesting new facilities and services in your area',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _NeedStatusCard(
                            label: 'Pending Review',
                            count: needRequestStats['submitted'] ?? 0,
                            color: Colors.orange,
                            icon: Icons.pending,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NeedStatusCard(
                            label: 'Approved',
                            count: needRequestStats['approved'] ?? 0,
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NeedStatusCard(
                            label: 'In Progress',
                            count: needRequestStats['in_progress'] ?? 0,
                            color: Colors.blue,
                            icon: Icons.work,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NeedStatusCard(
                            label: 'Completed',
                            count: needRequestStats['completed'] ?? 0,
                            color: Colors.purple,
                            icon: Icons.done_all,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_location_alt_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Facility Requests Yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Citizens haven\'t submitted any facility requests yet. When they do, you\'ll see them here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Certificate Analytics Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏆 Citizen Gamification',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () {
                  _showCertificateAnalyticsDialog(context);
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Details'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCertificateAnalyticsCard(),
          const SizedBox(height: 16),

          // Department Performance
          Text(
            'Department Performance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _DepartmentPerformanceCard(),
          const SizedBox(height: 16),

          // Recent Activities
          Text(
            'Recent System Activities',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _RecentActivitiesCard(),
          const SizedBox(height: 16),

          // Quick Actions
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _QuickActionCard(
                title: 'Need Requests',
                icon: Icons.add_location_alt,
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNeedManagementScreen(),
                    ),
                  );
                },
              ),
              _QuickActionCard(
                title: 'Add User',
                icon: Icons.person_add,
                color: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add User - Coming Soon!')),
                  );
                },
              ),
              _QuickActionCard(
                title: 'System Backup',
                icon: Icons.backup,
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('System Backup - Coming Soon!'),
                    ),
                  );
                },
              ),
              _QuickActionCard(
                title: 'Send Alert',
                icon: Icons.campaign,
                color: Colors.red,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Send Alert - Coming Soon!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateAnalyticsCard() {
    final totalCertificates = certificateAnalytics['totalCertificates'] ?? 0;
    final totalPoints = certificateAnalytics['totalPoints'] ?? 0;
    final uniqueCitizens = certificateAnalytics['uniqueCitizens'] ?? 0;
    final categoryBreakdown = certificateAnalytics['categoryBreakdown'] as Map<String, int>? ?? {};

    if (totalCertificates == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Certificates Issued Yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When citizens help resolve issues, they\'ll earn certificates and points. You\'ll see their achievements here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Citizen Achievements',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rewarding civic engagement with certificates and points',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _CertificateStatCard(
                    title: 'Total Certificates',
                    value: totalCertificates.toString(),
                    icon: Icons.workspace_premium,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CertificateStatCard(
                    title: 'Points Awarded',
                    value: totalPoints.toString(),
                    icon: Icons.stars,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CertificateStatCard(
                    title: 'Active Citizens',
                    value: uniqueCitizens.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            if (categoryBreakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Certificates by Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoryBreakdown.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getCategoryColor(entry.key).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(entry.key),
                          size: 16,
                          color: _getCategoryColor(entry.key),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(entry.key),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCertificateAnalyticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.amber[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Certificate Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Overview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnalyticsOverview(),
                      const SizedBox(height: 20),
                      Text(
                        'Recent Certificates',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRecentCertificatesList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    final totalCertificates = certificateAnalytics['totalCertificates'] ?? 0;
    final totalPoints = certificateAnalytics['totalPoints'] ?? 0;
    final uniqueCitizens = certificateAnalytics['uniqueCitizens'] ?? 0;
    final levelDistribution = certificateAnalytics['levelDistribution'] as Map<String, int>? ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.purple, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      totalCertificates.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const Text('Total Certificates', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.stars, color: Colors.orange, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      totalPoints.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text('Total Points', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.people, color: Colors.blue, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      uniqueCitizens.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text('Active Citizens', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (levelDistribution.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Citizen Levels',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...levelDistribution.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentCertificatesList() {
    final recentCertificates = certificateAnalytics['recentCertificates'] as List? ?? [];
    
    if (recentCertificates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No recent certificates to display',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: recentCertificates.take(5).map<Widget>((cert) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(cert.reportCategory),
                color: _getCategoryColor(cert.reportCategory),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert.citizenName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      cert.reportTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${cert.pointsAwarded}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Colors.orange;
      case 'environment':
        return Colors.green;
      case 'utilities':
        return Colors.blue;
      case 'public safety':
        return Colors.red;
      case 'transportation':
        return Colors.purple;
      case 'emergency':
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Icons.construction;
      case 'environment':
        return Icons.eco;
      case 'utilities':
        return Icons.power;
      case 'public safety':
        return Icons.security;
      case 'transportation':
        return Icons.directions_bus;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.report_problem;
    }
  }
}

// System Management Screen
class SystemManagementScreen extends StatelessWidget {
  final Function(BuildContext)? onSystemMessage;

  const SystemManagementScreen({super.key, this.onSystemMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // System Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SystemStatusItem(
                          title: 'Server',
                          status: 'Online',
                          color: Colors.green,
                          icon: Icons.computer,
                        ),
                      ),
                      Expanded(
                        child: _SystemStatusItem(
                          title: 'Database',
                          status: 'Healthy',
                          color: Colors.green,
                          icon: Icons.storage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SystemStatusItem(
                          title: 'API',
                          status: 'Active',
                          color: Colors.green,
                          icon: Icons.api,
                        ),
                      ),
                      Expanded(
                        child: _SystemStatusItem(
                          title: 'Backup',
                          status: 'Updated',
                          color: Colors.blue,
                          icon: Icons.backup,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Management Actions
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _ManagementActionCard(
                  title: 'Server Logs',
                  icon: Icons.description,
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Server Logs - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ManagementActionCard(
                  title: 'Database Backup',
                  icon: Icons.backup,
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Database Backup - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ManagementActionCard(
                  title: 'System Monitor',
                  icon: Icons.monitor_heart,
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('System Monitor - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ManagementActionCard(
                  title: 'Performance',
                  icon: Icons.speed,
                  color: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Performance Monitor - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ManagementActionCard(
                  title: 'Security Audit',
                  icon: Icons.security,
                  color: Colors.red,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Security Audit - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ManagementActionCard(
                  title: 'System Config',
                  icon: Icons.settings,
                  color: Colors.grey,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('System Config - Coming Soon!'),
                      ),
                    );
                  },
                ),
                _ManagementActionCard(
                  title: 'Send Message',
                  icon: Icons.message,
                  color: Colors.indigo,
                  onTap: () {
                    if (onSystemMessage != null) {
                      onSystemMessage!(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('System Message - Coming Soon!'),
                        ),
                      );
                    }
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

// User Management Screen
class UserManagementScreen extends StatefulWidget {
  final Function(BuildContext)? onAddUser;

  const UserManagementScreen({super.key, this.onAddUser});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _selectedUserType = 'All';
  final List<String> _userTypes = ['All', 'Citizens', 'Officers', 'Admins'];
  List<RegistrationRequest> allUsers = [];
  List<RegistrationRequest> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final users = await DatabaseService.instance.getAllRegistrationRequests();
      // Only show registered users
      final registeredUsers = users.where((user) => user.isRegistered).toList();

      setState(() {
        allUsers = registeredUsers;
        _filterUsers();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading users: $e');
    }
  }

  void _filterUsers() {
    if (_selectedUserType == 'All') {
      filteredUsers = allUsers;
    } else {
      String targetType;
      switch (_selectedUserType) {
        case 'Citizens':
          targetType = 'public';
          break;
        case 'Officers':
          targetType = 'officer';
          break;
        case 'Admins':
          targetType = 'admin';
          break;
        default:
          targetType = 'public';
      }
      filteredUsers = allUsers
          .where((user) => user.userType == targetType)
          .toList();
    }
  }

  String _getUserTypeDisplayName(String userType) {
    switch (userType) {
      case 'public':
        return 'Citizen';
      case 'officer':
        return 'Officer';
      case 'admin':
        return 'Admin';
      default:
        return 'Unknown';
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType) {
      case 'public':
        return Icons.person;
      case 'officer':
        return Icons.badge;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person_outline;
    }
  }

  String _formatRegistrationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just registered';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Management',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onAddUser != null) {
                    widget.onAddUser!(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add New User - Coming Soon!'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Type Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _userTypes.length,
              itemBuilder: (context, index) {
                final userType = _userTypes[index];
                final isSelected = _selectedUserType == userType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(userType),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedUserType = userType;
                        _filterUsers();
                      });
                    },
                    selectedColor: Colors.purple.withOpacity(0.3),
                    checkmarkColor: Colors.purple,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // User Stats
          Row(
            children: [
              Expanded(
                child: _UserStatCard(
                  title: 'Total Users',
                  value: '${allUsers.length}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UserStatCard(
                  title: 'Officers',
                  value:
                      '${allUsers.where((u) => u.userType == 'officer').length}',
                  icon: Icons.badge,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UserStatCard(
                  title: 'Citizens',
                  value:
                      '${allUsers.where((u) => u.userType == 'public').length}',
                  icon: Icons.person_add,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Users List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registered Users (${filteredUsers.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedUserType = 'All';
                    _filterUsers();
                  });
                  _loadUsers();
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Users will appear here after registration',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _UserListItem(
                        name: user.fullName,
                        email: user.email,
                        type: _getUserTypeDisplayName(user.userType),
                        status: user.isRegistered ? 'Active' : 'Pending',
                        avatar: _getUserTypeIcon(user.userType),
                        lastActive: _formatRegistrationDate(user.requestDate),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Analytics Screen
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // New Feedback Notification
          _NewFeedbackNotificationCard(),
          const SizedBox(height: 16),

          // KPI Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: [
              _KPICard(
                title: 'Issue Resolution Rate',
                value: '94.2%',
                trend: '+2.1%',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              _KPICard(
                title: 'Average Response Time',
                value: '2.1 hrs',
                trend: '-15%',
                icon: Icons.trending_down,
                color: Colors.blue,
              ),
              _KPICard(
                title: 'User Satisfaction',
                value: '4.6/5',
                trend: '+0.3',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
              _KPICard(
                title: 'Active Issues',
                value: '127',
                trend: '+12',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Issues Heatmap Dashboard
          Text(
            'Issues Heatmap Dashboard',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _IssuesHeatmapCard(),
          const SizedBox(height: 16),

          // Citizen Feedback Analytics
          Text(
            'Citizen Feedback Analytics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _FeedbackAnalyticsCard(),
          const SizedBox(height: 16),

          // Department Analytics
          Text(
            'Department Performance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _DepartmentAnalyticsCard(),
          const SizedBox(height: 16),

          // Usage Statistics
          Text(
            'Usage Statistics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _UsageStatisticsCard(),
        ],
      ),
    );
  }
}

// Admin Settings Screen
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                _SettingsSection(
                  title: 'System Configuration',
                  items: [
                    _SettingsItem(
                      title: 'General Settings',
                      subtitle: 'App name, logo, and basic configuration',
                      icon: Icons.settings,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      title: 'Notification Settings',
                      subtitle: 'Configure system notifications and alerts',
                      icon: Icons.notifications,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      title: 'Security Settings',
                      subtitle: 'Password policies and security rules',
                      icon: Icons.security,
                      onTap: () {},
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'User Management',
                  items: [
                    _SettingsItem(
                      title: 'User Roles',
                      subtitle: 'Manage user roles and permissions',
                      icon: Icons.admin_panel_settings,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      title: 'Department Setup',
                      subtitle: 'Add and manage departments',
                      icon: Icons.business,
                      onTap: () {},
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'System Maintenance',
                  items: [
                    _SettingsItem(
                      title: 'Database Management',
                      subtitle: 'Backup, restore, and optimize database',
                      icon: Icons.storage,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      title: 'System Logs',
                      subtitle: 'View and manage system logs',
                      icon: Icons.description,
                      onTap: () {},
                    ),
                    _SettingsItem(
                      title: 'Performance Monitor',
                      subtitle: 'Monitor system performance and resources',
                      icon: Icons.speed,
                      onTap: () {},
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Developer Tools',
                  items: [
                    _SettingsItem(
                      title: 'Developer Settings',
                      subtitle: 'Switch between local and cloud servers',
                      icon: Icons.developer_mode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeveloperSettingsScreen(),
                          ),
                        );
                      },
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
}

// Helper Widgets for Admin Dashboard

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final bool isPositive;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
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

class _DepartmentPerformanceCard extends StatelessWidget {
  Future<List<String>> _getDepartmentsList() async {
    try {
      final users = await DatabaseService.instance.getAllRegistrationRequests();
      final departments = users
          .map((user) => user.department)
          .where((dept) => dept != null && dept.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      return departments.isNotEmpty
          ? departments
          : ['Public Works', 'Water & Sewerage', 'Electricity'];
    } catch (e) {
      return ['Public Works', 'Water & Sewerage', 'Electricity'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performing Departments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: _getDepartmentsList(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Column(
                    children: snapshot.data!
                        .take(3)
                        .map(
                          (dept) => _DepartmentItem(
                            name: dept,
                            efficiency: '${90 + (dept.hashCode % 10)}%',
                            issues: '${20 + (dept.hashCode % 30)}',
                            color:
                                Colors.primaries[dept.hashCode %
                                    Colors.primaries.length],
                          ),
                        )
                        .toList(),
                  );
                }
                return const Text('No department data available');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivitiesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<RegistrationRequest>>(
              future: DatabaseService.instance.getAllRegistrationRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final recentUser = snapshot.data!.last;
                  return _ActivityItem(
                    icon: Icons.person_add,
                    title: 'New ${recentUser.userType} Added',
                    subtitle:
                        '${recentUser.fullName} - ${recentUser.department}',
                    time: 'Recently',
                    color: Colors.blue,
                  );
                }
                return _ActivityItem(
                  icon: Icons.info,
                  title: 'No Recent Activity',
                  subtitle: 'No new registrations',
                  time: 'N/A',
                  color: Colors.grey,
                );
              },
            ),
            _ActivityItem(
              icon: Icons.check_circle,
              title: 'Issue Resolved',
              subtitle: 'Water main break - Sector 5',
              time: '15 min ago',
              color: Colors.green,
            ),
            _ActivityItem(
              icon: Icons.warning,
              title: 'System Alert',
              subtitle: 'High server load detected',
              time: '1 hour ago',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemStatusItem extends StatelessWidget {
  final String title;
  final String status;
  final Color color;
  final IconData icon;

  const _SystemStatusItem({
    required this.title,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(status, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class _ManagementActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ManagementActionCard({
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

class _UserStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _UserStatCard({
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final String name;
  final String email;
  final String type;
  final String status;
  final IconData avatar;
  final String lastActive;

  const _UserListItem({
    required this.name,
    required this.email,
    required this.type,
    required this.status,
    required this.avatar,
    required this.lastActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(avatar)),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lastActive,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(fontSize: 12, color: Colors.green),
          ),
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(trend, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DepartmentAnalyticsCard extends StatefulWidget {
  @override
  _DepartmentAnalyticsCardState createState() =>
      _DepartmentAnalyticsCardState();
}

class _DepartmentAnalyticsCardState extends State<_DepartmentAnalyticsCard> {
  Map<String, Map<String, int>> _departmentStats = {};
  List<Map<String, dynamic>> _completedReports = [];
  bool _isLoading = true;
  String _selectedDepartment = 'All';

  @override
  void initState() {
    super.initState();
    _loadDepartmentData();
  }

  Future<void> _loadDepartmentData() async {
    try {
      setState(() => _isLoading = true);

      final stats = await DatabaseService.instance.getDepartmentWiseStats();
      final completedReports = await DatabaseService.instance
          .getCompletedReportsForAnalytics();

      setState(() {
        _departmentStats = stats;
        _completedReports = completedReports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading department data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(
      children: [
        // Department Performance Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Department Performance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _loadDepartmentData,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_departmentStats.isEmpty)
                  Text('No department data available')
                else
                  ..._departmentStats.entries.map((entry) {
                    final department = entry.key;
                    final stats = entry.value;
                    final total = stats['total'] ?? 0;
                    final completed = stats['completed'] ?? 0;
                    final efficiency = total > 0
                        ? (completed / total * 100)
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DepartmentAnalyticsItem(
                        department: department,
                        issues: total,
                        resolved: completed,
                        efficiency: efficiency,
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Completed Reports Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Completed Reports',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    DropdownButton<String>(
                      value: _selectedDepartment,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDepartment = newValue ?? 'All';
                        });
                      },
                      items: ['All', ..._departmentStats.keys]
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_completedReports.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_turned_in,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text('No completed reports yet'),
                        ],
                      ),
                    ),
                  )
                else
                  ..._getFilteredReports().take(5).map((report) {
                    return _CompletedReportItem(report: report);
                  }).toList(),

                if (_getFilteredReports().length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: TextButton(
                        onPressed: () => _showAllCompletedReports(context),
                        child: Text(
                          'View All Completed Reports (${_getFilteredReports().length})',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredReports() {
    if (_selectedDepartment == 'All') {
      return _completedReports;
    }
    return _completedReports
        .where((report) => report['department'] == _selectedDepartment)
        .toList();
  }

  void _showAllCompletedReports(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Completed Reports - $_selectedDepartment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _getFilteredReports().length,
                  itemBuilder: (context, index) {
                    return _CompletedReportItem(
                      report: _getFilteredReports()[index],
                      showFullDetails: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedReportItem extends StatelessWidget {
  final Map<String, dynamic> report;
  final bool showFullDetails;

  const _CompletedReportItem({
    required this.report,
    this.showFullDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final completedAt = report['completedAt'] is DateTime
        ? report['completedAt'] as DateTime
        : DateTime.parse(report['completedAt']);
    final timeAgo = _formatTimeAgo(completedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report['department'],
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report['title'],
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: showFullDetails ? null : 2,
              overflow: showFullDetails ? null : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report['location'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (showFullDetails) ...[
              const SizedBox(height: 8),
              Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  _DetailChip(icon: Icons.category, label: report['category']),
                  const SizedBox(width: 8),
                  _DetailChip(icon: Icons.flag, label: report['priority']),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Officer: ${report['assignedOfficer']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Resolved in: ${report['resolutionTime']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Officer: ${report['assignedOfficer']} • ${report['resolutionTime']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
}

// Feedback Analytics Card
class _FeedbackAnalyticsCard extends StatefulWidget {
  @override
  _FeedbackAnalyticsCardState createState() => _FeedbackAnalyticsCardState();
}

class _FeedbackAnalyticsCardState extends State<_FeedbackAnalyticsCard> {
  Map<String, dynamic> _feedbackStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbackStats();
  }

  Future<void> _loadFeedbackStats() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final stats = await DatabaseService.instance.getFeedbackStatistics();

      if (!mounted) return;
      setState(() {
        _feedbackStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading feedback statistics: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text('Loading feedback data...'),
              ],
            ),
          ),
        ),
      );
    }

    final total = _feedbackStats['total'] ?? 0;
    final averageRating = (_feedbackStats['averageRating'] ?? 0.0).toDouble();
    final positive = _feedbackStats['positive'] ?? 0;
    final neutral = _feedbackStats['neutral'] ?? 0;
    final negative = _feedbackStats['negative'] ?? 0;
    final ratingDistribution =
        _feedbackStats['ratingDistribution'] ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final recentFeedback = _feedbackStats['recentFeedback'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Citizen Feedback Overview',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total > 0
                            ? 'Based on $total feedback responses • Average: ${averageRating.toStringAsFixed(1)}/5.0'
                            : 'No feedback data available yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20),
                  onPressed: _loadFeedbackStats,
                  tooltip: 'Refresh feedback data',
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (total == 0)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.feedback_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No citizen feedback yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Feedback will appear here when citizens rate resolved issues',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              // Overview Stats Row
              Row(
                children: [
                  Expanded(
                    child: _FeedbackStatCard(
                      title: 'Total Responses',
                      value: '$total',
                      color: Colors.blue,
                      icon: Icons.forum,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeedbackStatCard(
                      title: 'Average Rating',
                      value: '${averageRating.toStringAsFixed(1)}/5',
                      color: _getAverageRatingColor(averageRating),
                      icon: Icons.star,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeedbackStatCard(
                      title: 'Satisfaction',
                      value:
                          '${((positive / total) * 100).toStringAsFixed(1)}%',
                      color: Colors.green,
                      icon: Icons.thumb_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rating Distribution
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating Distribution',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(5, (index) {
                      final stars = 5 - index;
                      final count = ratingDistribution[stars] ?? 0;
                      final percentage = total > 0 ? (count / total) : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Row(
                                children: [
                                  Text(
                                    '$stars',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: percentage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getRatingBarColor(stars),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sentiment Analysis
              Row(
                children: [
                  Expanded(
                    child: _SentimentCard(
                      title: 'Positive',
                      count: positive,
                      total: total,
                      color: Colors.green,
                      icon: Icons.sentiment_very_satisfied,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SentimentCard(
                      title: 'Neutral',
                      count: neutral,
                      total: total,
                      color: Colors.orange,
                      icon: Icons.sentiment_neutral,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SentimentCard(
                      title: 'Negative',
                      count: negative,
                      total: total,
                      color: Colors.red,
                      icon: Icons.sentiment_very_dissatisfied,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recent Feedback
              if (recentFeedback.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showAllFeedback(context),
                      child: Text('View All', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...recentFeedback
                    .take(3)
                    .map((feedback) => _RecentFeedbackItem(feedback: feedback)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _getAverageRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.orange;
    if (rating >= 1.5) return Colors.deepOrange;
    return Colors.red;
  }

  Color _getRatingBarColor(int stars) {
    switch (stars) {
      case 5:
        return Colors.green[600]!;
      case 4:
        return Colors.lightGreen[600]!;
      case 3:
        return Colors.orange[600]!;
      case 2:
        return Colors.deepOrange[600]!;
      case 1:
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _showAllFeedback(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => AllFeedbackScreen()));
  }
}

// Helper widgets for feedback analytics
class _FeedbackStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _FeedbackStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentimentCard extends StatelessWidget {
  final String title;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _SentimentCard({
    required this.title,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _RecentFeedbackItem extends StatelessWidget {
  final dynamic feedback;

  const _RecentFeedbackItem({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  feedback.reportDepartment,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < feedback.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            feedback.reportTitle,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            feedback.description,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                feedback.userName,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(feedback.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
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
}

// All Feedback Screen
class AllFeedbackScreen extends StatefulWidget {
  @override
  _AllFeedbackScreenState createState() => _AllFeedbackScreenState();
}

class _AllFeedbackScreenState extends State<AllFeedbackScreen> {
  List<dynamic> _allFeedback = [];
  bool _isLoading = true;
  String _filterRating = 'All';
  List<String> _ratingFilters = [
    'All',
    '5 Stars',
    '4 Stars',
    '3 Stars',
    '2 Stars',
    '1 Star',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllFeedback();
  }

  Future<void> _loadAllFeedback() async {
    try {
      setState(() => _isLoading = true);

      final feedback = await DatabaseService.instance.getAllFeedback();

      if (mounted) {
        setState(() {
          _allFeedback = feedback;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading all feedback: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredFeedback {
    if (_filterRating == 'All') return _allFeedback;

    final rating = int.tryParse(_filterRating.split(' ')[0]);
    if (rating != null) {
      return _allFeedback.where((f) => f.rating == rating).toList();
    }

    return _allFeedback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Feedback (${_filteredFeedback.length})'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          DropdownButton<String>(
            value: _filterRating,
            dropdownColor: Colors.white,
            underline: Container(),
            items: _ratingFilters.map((filter) {
              return DropdownMenuItem(
                value: filter,
                child: Text(
                  filter,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filterRating = value;
                });
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredFeedback.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _filterRating == 'All'
                        ? 'No feedback available'
                        : 'No ${_filterRating.toLowerCase()} feedback',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _filteredFeedback.length,
              itemBuilder: (context, index) {
                final feedback = _filteredFeedback[index];
                return _DetailedFeedbackCard(feedback: feedback);
              },
            ),
    );
  }
}

class _DetailedFeedbackCard extends StatelessWidget {
  final dynamic feedback;

  const _DetailedFeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    feedback.reportDepartment,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < feedback.rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: Colors.amber,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '${feedback.rating}/5',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              feedback.reportTitle,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              feedback.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  feedback.userName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(feedback.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Issues Heatmap Card
class _IssuesHeatmapCard extends StatefulWidget {
  @override
  _IssuesHeatmapCardState createState() => _IssuesHeatmapCardState();
}

class _IssuesHeatmapCardState extends State<_IssuesHeatmapCard> {
  Map<String, int> _departmentIssueCount = {};
  bool _isLoading = true;
  String _selectedTimeframe = 'All Time';
  List<String> _timeframeOptions = [
    'All Time',
    'Last Week',
    'Last Month',
    'Last 3 Months',
  ];

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Get all reports from database
      final allReports = await DatabaseService.instance.getAllReports();

      // Filter reports based on selected timeframe
      final filteredReports = _filterReportsByTimeframe(allReports);

      // Count issues by department
      final departmentCounts = <String, int>{};
      for (final report in filteredReports) {
        final department = report.department.isEmpty
            ? 'General Services'
            : report.department;
        departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() {
        _departmentIssueCount = departmentCounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading heatmap data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Report> _filterReportsByTimeframe(List<Report> reports) {
    final now = DateTime.now();
    switch (_selectedTimeframe) {
      case 'Last Week':
        return reports
            .where((r) => now.difference(r.createdAt).inDays <= 7)
            .toList();
      case 'Last Month':
        return reports
            .where((r) => now.difference(r.createdAt).inDays <= 30)
            .toList();
      case 'Last 3 Months':
        return reports
            .where((r) => now.difference(r.createdAt).inDays <= 90)
            .toList();
      default:
        return reports;
    }
  }

  List<MapEntry<String, int>> get _sortedDepartments {
    var entries = _departmentIssueCount.entries.toList();
    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    ); // Sort by issue count (descending)
    return entries;
  }

  Color _getHeatmapColor(int issueCount, int maxCount) {
    if (maxCount == 0) return Colors.grey[200]!;

    final intensity = (issueCount / maxCount);
    if (intensity >= 0.8) return Colors.red[700]!;
    if (intensity >= 0.6) return Colors.red[500]!;
    if (intensity >= 0.4) return Colors.orange[600]!;
    if (intensity >= 0.2) return Colors.yellow[700]!;
    return Colors.green[300]!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text('Loading heatmap data...'),
              ],
            ),
          ),
        ),
      );
    }

    final sortedDepts = _sortedDepartments;
    final maxCount = sortedDepts.isNotEmpty ? sortedDepts.first.value : 0;
    final totalIssues = _departmentIssueCount.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issues Heatmap Dashboard',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Departments ordered by issue count - Total: $totalIssues issues',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedTimeframe,
                      isDense: true,
                      items: _timeframeOptions.map((timeframe) {
                        return DropdownMenuItem(
                          value: timeframe,
                          child: Text(
                            timeframe,
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && mounted) {
                          setState(() {
                            _selectedTimeframe = value;
                          });
                          _loadHeatmapData();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.refresh, size: 20),
                      onPressed: _loadHeatmapData,
                      tooltip: 'Refresh data',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (sortedDepts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No issues reported yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else ...[
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Less',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(5, (index) {
                    final colors = [
                      Colors.green[300]!,
                      Colors.yellow[700]!,
                      Colors.orange[600]!,
                      Colors.red[500]!,
                      Colors.red[700]!,
                    ];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    'More',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Heatmap Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: sortedDepts.length,
                itemBuilder: (context, index) {
                  final entry = sortedDepts[index];
                  final department = entry.key;
                  final issueCount = entry.value;
                  final color = _getHeatmapColor(issueCount, maxCount);
                  final rank = index + 1;

                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$issueCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                department,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Top 5 Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top 5 Departments by Issues',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sortedDepts.take(5).map((entry) {
                      final index = sortedDepts.indexOf(entry);
                      final percentage = totalIssues > 0
                          ? (entry.value / totalIssues * 100)
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _UsageStatisticsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Usage (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _UsageItem(day: 'Today', users: 1247, issues: 23),
            _UsageItem(day: 'Yesterday', users: 1156, issues: 18),
            _UsageItem(day: '2 days ago', users: 1089, issues: 15),
            _UsageItem(day: '3 days ago', users: 1234, issues: 21),
          ],
        ),
      ),
    );
  }
}

// Additional Helper Widgets
class _DepartmentItem extends StatelessWidget {
  final String name;
  final String efficiency;
  final String issues;
  final Color color;

  const _DepartmentItem({
    required this.name,
    required this.efficiency,
    required this.issues,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text('$efficiency • $issues issues'),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _DepartmentAnalyticsItem extends StatelessWidget {
  final String department;
  final int issues;
  final int resolved;
  final double efficiency;

  const _DepartmentAnalyticsItem({
    required this.department,
    required this.issues,
    required this.resolved,
    required this.efficiency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(department)),
        Expanded(child: Text('$issues')),
        Expanded(child: Text('$resolved')),
        Expanded(child: Text('${efficiency.toStringAsFixed(1)}%')),
      ],
    );
  }
}

class _UsageItem extends StatelessWidget {
  final String day;
  final int users;
  final int issues;

  const _UsageItem({
    required this.day,
    required this.users,
    required this.issues,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(day)),
          Expanded(child: Text('$users users')),
          Expanded(child: Text('$issues issues')),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Card(child: Column(children: items.map((item) => item).toList())),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SecurityItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _NeedStatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _NeedStatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// New Feedback Notification Card Widget
class _NewFeedbackNotificationCard extends StatefulWidget {
  @override
  _NewFeedbackNotificationCardState createState() => _NewFeedbackNotificationCardState();
}

class _NewFeedbackNotificationCardState extends State<_NewFeedbackNotificationCard> {
  int _newFeedbackCount = 0;
  List<dynamic> _recentFeedback = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNewFeedback();
  }

  Future<void> _loadNewFeedback() async {
    try {
      setState(() => _isLoading = true);

      final allFeedback = await DatabaseService.instance.getAllFeedback();
      
      // Get feedback from last 24 hours as "new"
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final newFeedback = allFeedback.where((feedback) {
        try {
          final createdAt = DateTime.parse(feedback.createdAt.toString());
          return createdAt.isAfter(yesterday);
        } catch (e) {
          // If date parsing fails, consider it as new feedback
          return true;
        }
      }).toList();

      if (mounted) {
        setState(() {
          _newFeedbackCount = newFeedback.length;
          _recentFeedback = newFeedback.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading new feedback: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Checking for new feedback...'),
            ],
          ),
        ),
      );
    }

    if (_newFeedbackCount == 0) {
      return const SizedBox.shrink(); // Don't show if no new feedback
    }

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notification_important,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Citizen Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        '$_newFeedbackCount new feedback ${_newFeedbackCount == 1 ? 'entry' : 'entries'} received in the last 24 hours',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_newFeedbackCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (_recentFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Recent Reviews:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ..._recentFeedback.map((feedback) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        feedback.reportDepartment,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < feedback.rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber[600],
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedback.reportTitle.length > 30 
                            ? '${feedback.reportTitle.substring(0, 30)}...'
                            : feedback.reportTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => AllFeedbackScreen()),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View All Feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _newFeedbackCount = 0;
                      _recentFeedback = [];
                    });
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Dismiss'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[600],
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

// Certificate Statistics Card Widget
class _CertificateStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CertificateStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
