import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/registration_request.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
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
    final displayPhone = regData?.phone ?? 'Not provided';
    final displayAddress = regData?.address ?? 'Not provided';
    final displayIdNumber = regData?.idNumber ?? 'Not provided';
    final registrationDate = regData?.requestDate;

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
                    backgroundColor: Colors.blue,
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
                  const Text('Citizen'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
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

          // Contact Information
          _buildProfileCard(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            children: [
              _buildProfileItem(Icons.email, 'Email', displayEmail),
              _buildProfileItem(Icons.phone, 'Phone', displayPhone),
              _buildProfileItem(Icons.location_on, 'Address', displayAddress),
            ],
          ),

          // Personal Details
          _buildProfileCard(
            title: 'Personal Details',
            icon: Icons.person,
            children: [
              _buildProfileItem(Icons.badge, 'ID Number', displayIdNumber),
              _buildProfileItem(
                Icons.date_range,
                'Registered',
                _formatDate(registrationDate),
              ),
              _buildProfileItem(
                Icons.account_circle,
                'Account Type',
                'Citizen',
              ),
            ],
          ),

          if (regData?.reason != null)
            _buildProfileCard(
              title: 'Registration Details',
              icon: Icons.info,
              children: [
                _buildProfileItem(
                  Icons.description,
                  'Registration Reason',
                  regData!.reason,
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
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Data Source',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
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

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadProfileData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit Profile - Coming Soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
