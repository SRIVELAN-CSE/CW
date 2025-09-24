import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_service.dart';
import '../../models/registration_request.dart';

class VoiceCallReportingScreen extends StatefulWidget {
  const VoiceCallReportingScreen({super.key});

  @override
  State<VoiceCallReportingScreen> createState() => _VoiceCallReportingScreenState();
}

class _VoiceCallReportingScreenState extends State<VoiceCallReportingScreen> {
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfficerContacts();
  }

  Future<void> _loadOfficerContacts() async {
    setState(() => _isLoading = true);
    try {
      // Get all approved officer registrations from database
      final registrations = await DatabaseService.instance.getAllRegistrationRequests();
      final approvedOfficers = registrations.where((reg) => 
        reg.userType == 'officer' && reg.isRegistered
      ).toList();

      // Group officers by department
      final departmentMap = <String, List<RegistrationRequest>>{};
      for (final officer in approvedOfficers) {
        final department = officer.department ?? 'General';
        if (!departmentMap.containsKey(department)) {
          departmentMap[department] = [];
        }
        departmentMap[department]!.add(officer);
      }

      // Create department list with officer details
      final departments = <Map<String, dynamic>>[];
      
      for (final entry in departmentMap.entries) {
        final departmentName = entry.key;
        final officers = entry.value;
        
        // Get the first officer as primary contact (you can modify this logic)
        final primaryOfficer = officers.first;
        
        departments.add({
          'name': departmentName,
          'description': _getDepartmentDescription(departmentName),
          'officer': primaryOfficer.fullName,
          'phone': primaryOfficer.phone,
          'hours': 'Mon-Fri 9AM-5PM',
          'icon': _getDepartmentIcon(departmentName),
        });
      }

      // Add default departments if no officers registered yet
      if (departments.isEmpty) {
        departments.addAll(_getDefaultDepartments());
      }

      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading officer contacts: $e');
      setState(() {
        _departments = _getDefaultDepartments();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getDefaultDepartments() {
    return [
      {
        'name': 'Public Works',
        'description': 'Road repairs, construction, infrastructure issues',
        'officer': 'Mr. Rajesh Kumar',
        'phone': '+91-9876543210',
        'hours': 'Mon-Fri 9AM-5PM',
        'icon': Icons.construction,
      },
      {
        'name': 'Water & Electricity',
        'description': 'Water supply, power outages, utility issues',
        'officer': 'Ms. Priya Sharma',
        'phone': '+91-9876543212',
        'hours': 'Mon-Fri 9AM-5PM',
        'icon': Icons.water_drop,
      },
      {
        'name': 'Sanitation',
        'description': 'Waste management, street cleaning, drainage',
        'officer': 'Mr. Suresh Patel',
        'phone': '+91-9876543214',
        'hours': 'Mon-Fri 9AM-5PM',
        'icon': Icons.cleaning_services,
      },
      {
        'name': 'Traffic & Transport',
        'description': 'Traffic signals, parking, road safety',
        'officer': 'Mr. Amit Singh',
        'phone': '+91-9876543216',
        'hours': 'Mon-Fri 9AM-5PM',
        'icon': Icons.traffic,
      },
    ];
  }

  String _getDepartmentDescription(String department) {
    switch (department.toLowerCase()) {
      case 'public works':
        return 'Road repairs, construction, infrastructure issues';
      case 'water & electricity':
        return 'Water supply, power outages, utility issues';
      case 'sanitation':
        return 'Waste management, street cleaning, drainage';
      case 'traffic & transport':
        return 'Traffic signals, parking, road safety';
      case 'health':
        return 'Public health, medical facilities, health emergencies';
      case 'education':
        return 'Schools, educational facilities, student services';
      default:
        return 'General civic issues and public services';
    }
  }

  IconData _getDepartmentIcon(String department) {
    switch (department.toLowerCase()) {
      case 'public works':
        return Icons.construction;
      case 'water & electricity':
        return Icons.water_drop;
      case 'sanitation':
        return Icons.cleaning_services;
      case 'traffic & transport':
        return Icons.traffic;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.support_agent;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Create tel: URL for phone call
      final telUrl = 'tel:$phoneNumber';
      final Uri uri = Uri.parse(telUrl);
      
      // Check if phone call can be launched
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: Show dialog with phone number for manual dialing
        if (mounted) {
          _showPhoneCallDialog(phoneNumber);
        }
      }
    } catch (e) {
      if (mounted) {
        // Fallback: Show dialog with phone number
        _showPhoneCallDialog(phoneNumber);
      }
    }
  }

  void _showPhoneCallDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text('Call Officer'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.phone_in_talk,
                      size: 48,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Officer Contact Number:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        // Copy to clipboard as fallback
                        await Clipboard.setData(ClipboardData(text: phoneNumber));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number copied to clipboard'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          phoneNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap the number to copy it to clipboard if automatic calling doesn\'t work.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Try to launch phone call again
                final telUrl = 'tel:$phoneNumber';
                final Uri uri = Uri.parse(telUrl);
                try {
                  await launchUrl(uri);
                } catch (e) {
                  // If still fails, copy to clipboard
                  await Clipboard.setData(ClipboardData(text: phoneNumber));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number copied to clipboard. Please dial manually.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Call Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber, String departmentName) async {
    try {
      // Create pre-filled WhatsApp message
      final message = Uri.encodeComponent(
        'Hello! I want to report a civic issue in the $departmentName department. '
        'Please guide me on how to proceed with my complaint. Thank you!'
      );
      
      // Format phone number for WhatsApp (remove + and spaces)
      final formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Create WhatsApp URL
      final whatsappUrl = 'https://wa.me/$formattedNumber?text=$message';
      final Uri uri = Uri.parse(whatsappUrl);
      
      // Try to launch WhatsApp directly
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Show dialog with WhatsApp link
        if (mounted) {
          _showWhatsAppDialog(phoneNumber, whatsappUrl, message);
        }
      }
    } catch (e) {
      if (mounted) {
        // Create the fallback variables again in the catch block
        final message = Uri.encodeComponent(
          'Hello! I want to report a civic issue in the $departmentName department. '
          'Please guide me on how to proceed with my complaint. Thank you!'
        );
        final formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        final whatsappUrl = 'https://wa.me/$formattedNumber?text=$message';
        
        // Fallback: Show dialog with WhatsApp link
        _showWhatsAppDialog(phoneNumber, whatsappUrl, message);
      }
    }
  }

  void _showWhatsAppDialog(String phoneNumber, String whatsappUrl, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.chat, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text('WhatsApp Message'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      size: 48,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Send WhatsApp message to:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        // Copy WhatsApp URL to clipboard as fallback
                        await Clipboard.setData(ClipboardData(text: whatsappUrl));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('WhatsApp link copied to clipboard'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          phoneNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pre-filled message:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  Uri.decodeComponent(message),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Try to open WhatsApp again
                final Uri uri = Uri.parse(whatsappUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  // Copy WhatsApp link to clipboard
                  await Clipboard.setData(ClipboardData(text: whatsappUrl));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp link copied to clipboard. Please paste in browser.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open WhatsApp'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice & Chat Reporting'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.phone_in_talk,
                    size: 60,
                    color: Colors.purple[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Report Issues by Voice Call or WhatsApp',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the relevant department and choose to call directly or send a WhatsApp message to report your issue. Our officers will assist you.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Department List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _departments.length,
                      itemBuilder: (context, index) {
                        final department = _departments[index];
                        return _buildDepartmentCard(department);
                      },
                    ),
            ),
            
            // Footer Information
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How to Report Issues',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '📞 Call: Direct voice conversation with the officer\n'
                        '💬 WhatsApp: Send message with issue details and photos\n'
                        '� Always include your location and contact details\n'
                        '⏰ Officers available: Mon-Fri 9AM-5PM',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Department Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    department['icon'],
                    color: Colors.purple[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        department['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Officer Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Officer: ${department['officer']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Hours: ${department['hours']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Contact Options
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Officer:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Contact Row: Call and WhatsApp
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(department['phone']),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Call Officer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sendWhatsAppMessage(department['phone'], department['name']),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Phone Number Display
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    department['phone'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}