import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';
import '../../core/services/media_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/smart_categorization_service.dart';
import '../../models/report.dart';
import 'need_request_screen.dart';
import 'public_profile_screen.dart';
import 'certificates_screen.dart';
import '../../widgets/feedback_dialog.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

// Custom class to handle images across platforms
class AppImage {
  final File? file;
  final Uint8List? bytes;
  final String? name;

  AppImage({this.file, this.bytes, this.name});

  bool get isValid => (file != null && !kIsWeb) || (bytes != null && kIsWeb);
}

class PublicDashboardScreen extends StatefulWidget {
  const PublicDashboardScreen({super.key});

  @override
  State<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends State<PublicDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardHome(
        onNavigateToReport: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      const ReportIssueScreen(),
      const MyReportsScreen(),
      const CommunityScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicWelfare - Citizen'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          FutureBuilder<Map<String, String>?>(
            future: DatabaseService.instance.getCurrentUserSession(),
            builder: (context, snapshot) {
              final userId = snapshot.data?['userId'] ?? 'anonymous';
              return NotificationWidget(userRole: 'citizen', userId: userId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              _showProfileMenu(context);
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Report',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PublicProfileScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.amber),
                title: const Text('My Certificates'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CertificatesScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings - Coming Soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help - Coming Soon!')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close the drawer first

                  try {
                    // Clear user session from localStorage/SharedPreferences
                    await DatabaseService.instance.clearUserSession();

                    // Navigate to home screen and clear navigation stack
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);

                    // Show logout confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully logged out'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
              ),
            ],
          ),
        );
      },
    );
  }
}

// Dashboard Home Screen
class DashboardHome extends StatelessWidget {
  final VoidCallback onNavigateToReport;

  const DashboardHome({super.key, required this.onNavigateToReport});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help make your community better by reporting civic issues.',
                  ),
                ],
              ),
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
                  icon: Icons.report_problem,
                  title: 'Report Issue',
                  color: Colors.red,
                  onTap: onNavigateToReport,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_location_alt,
                  title: 'Request Facility',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NeedRequestScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feedback Notifications
          _FeedbackNotificationSection(),
          const SizedBox(height: 16),

          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildRecentActivity(),
          const SizedBox(height: 16),

          // Community Stats
          Text(
            'Community Impact',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildCommunityStats(),
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
              title: 'Street Light Fixed',
              subtitle: 'Main Street - Completed',
              color: Colors.green,
            ),
            const Divider(),
            _ActivityItem(
              icon: Icons.access_time,
              title: 'Pothole Repair',
              subtitle: 'Park Avenue - In Progress',
              color: Colors.orange,
            ),
            const Divider(),
            _ActivityItem(
              icon: Icons.report,
              title: 'Garbage Collection',
              subtitle: 'Sector 5 - Reported Today',
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Issues Resolved',
            value: '1,234',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Active Reports',
            value: '87',
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Citizens',
            value: '5.2K',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

// Report Issue Screen
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;

  // Auto-detected values (will be shown to user for confirmation)
  String _detectedPriority = 'Medium';
  String _detectedDepartment = 'General Services';
  String _estimatedResolution = 'Within 5 days';
  Map<String, String> _departmentContact = {};

  // Location and Media services
  final LocationService _locationService = LocationService();
  final MediaService _mediaService = MediaService();
  final List<AppImage> _attachedImages = [];
  final List<String> _attachedVideos = []; // Store video file paths or base64
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Test storage first
    _testStorage();
    // Load any saved draft when the screen loads
    _loadDraftReport();
    // Automatically detect current location when the screen loads
    _autoDetectLocation();
  }

  // Auto-detect current location when the screen loads
  Future<void> _autoDetectLocation() async {
    // Wait a bit for the screen to fully load
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Only auto-detect if location field is empty
    if (_locationController.text.isEmpty) {
      print('🌍 Auto-detecting location...');
      await _getCurrentLocation();
    }
  }

  // Test storage functionality
  void _testStorage() async {
    try {
      print('🧪 Testing storage...');

      // Test simple storage
      await DatabaseService.instance.saveDraftReport({
        'test': 'storage_test',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Load any existing draft report
      final draftData = await DatabaseService.instance.getDraftReport();
      if (draftData != null) {
        print('📝 Found draft report data');
        // Load draft data into form if needed
      }
    } catch (e) {
      print('❌ Storage test failed: $e');
    }
  }

  // Auto-detect priority and department when title, description, or category changes
  void _updateAutoDetection() {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty) {
      final categorization = SmartCategorizationService.instance;

      // Auto-detect category if not already set
      String category =
          _selectedCategory ??
          categorization.autoDetectCategory(
            _titleController.text,
            _descriptionController.text,
          );

      setState(() {
        // Auto-set the category
        _selectedCategory = category;

        _detectedPriority = categorization.determinePriority(
          _titleController.text,
          _descriptionController.text,
          category,
        );

        _detectedDepartment = categorization.determineDepartment(
          _titleController.text,
          _descriptionController.text,
          category,
        );

        _estimatedResolution = categorization.getEstimatedResolutionTime(
          _detectedPriority,
          _detectedDepartment,
        );

        _departmentContact = categorization.getDepartmentContact(
          _detectedDepartment,
        );
      });

      // Auto-save draft after detection
      _autoSaveDraft();
    }
  }

  // Auto-save draft report to local storage
  void _autoSaveDraft() {
    // Only save if there's substantial content
    if (_titleController.text.length > 2 ||
        _descriptionController.text.length > 5) {
      print('🔄 Auto-saving draft...');
      final draftData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'selectedCategory': _selectedCategory,
        'detectedPriority': _detectedPriority,
        'detectedDepartment': _detectedDepartment,
        'estimatedResolution': _estimatedResolution,
        'attachedImagesCount': _attachedImages.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print(
        '📝 Draft data: ${draftData['title']} - ${draftData['description'].toString().substring(0, draftData['description'].toString().length > 20 ? 20 : draftData['description'].toString().length)}...',
      );

      // Save draft asynchronously
      DatabaseService.instance
          .saveDraftReport(draftData)
          .then((_) {
            print('✅ Draft saved successfully');
          })
          .catchError((error) {
            print('❌ Error saving draft: $error');
          });
    } else {
      print('⏭️ Skipping auto-save - insufficient content');
    }
  }

  // Load saved draft report
  Future<void> _loadDraftReport() async {
    try {
      print('🔍 Loading draft report...');
      final draft = await DatabaseService.instance.getDraftReport();
      print('📂 Draft found: ${draft != null}');

      if (draft != null && mounted) {
        print('📄 Restoring draft: ${draft['title']} - ${draft['timestamp']}');
        setState(() {
          _titleController.text = draft['title'] ?? '';
          _descriptionController.text = draft['description'] ?? '';
          _locationController.text = draft['location'] ?? '';
          _selectedCategory = draft['selectedCategory'];
          _detectedPriority = draft['detectedPriority'] ?? '';
          _detectedDepartment = draft['detectedDepartment'] ?? '';
          _estimatedResolution = draft['estimatedResolution'] ?? '';
        });

        // Show notification about loaded draft
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.restore, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('📄 Draft report restored!')),
                  TextButton(
                    onPressed: () {
                      DatabaseService.instance.clearDraftReport();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('📭 No draft found or widget not mounted');
      }
    } catch (e) {
      print('❌ Error loading draft: $e');
    }
  }

  // Get current GPS location with enhanced error handling
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled first
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationServiceDialog();
        }
        return;
      }

      // Check and request permissions
      final permission = await _locationService.checkLocationPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }

      // Get location with enhanced feedback
      final locationData = await _locationService
          .getCurrentLocationWithAddress();
      
      if (locationData != null) {
        setState(() {
          _locationController.text = locationData.address;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('📍 Location detected: ${locationData.address}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Edit',
                textColor: Colors.white,
                onPressed: () {
                  // Focus on location field for editing
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          _showLocationFailedDialog();
        }
      }
    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        String errorMessage = 'Error getting location';
        
        // Provide specific error messages
        if (e.toString().contains('permission')) {
          errorMessage = 'Location permission denied';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Location request timed out';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error while getting address';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _getCurrentLocation(),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      if (kIsWeb) {
        // For web, get the image picker directly
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.camera,
        );
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          final appImage = AppImage(bytes: bytes, name: pickedFile.name);
          setState(() {
            _attachedImages.add(appImage);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // For mobile, use the existing MediaService
        final File? image = await _mediaService.pickImageFromCamera();
        if (image != null) {
          final appImage = AppImage(file: image);
          setState(() {
            _attachedImages.add(appImage);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      if (kIsWeb) {
        // For web, get the image picker directly
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          final appImage = AppImage(bytes: bytes, name: pickedFile.name);
          setState(() {
            _attachedImages.add(appImage);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // For mobile, use the existing MediaService
        final File? image = await _mediaService.pickImageFromGallery();
        if (image != null) {
          final appImage = AppImage(file: image);
          setState(() {
            _attachedImages.add(appImage);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove image from attachments
  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Record video with camera
  Future<void> _recordVideo() async {
    try {
      if (kIsWeb) {
        final ImagePicker picker = ImagePicker();
        final XFile? videoFile = await picker.pickVideo(
          source: ImageSource.camera,
        );
        if (videoFile != null) {
          final bytes = await videoFile.readAsBytes();
          final base64Video = base64Encode(bytes);
          setState(() {
            _attachedVideos.add('data:video/mp4;base64,$base64Video');
          });
        }
      } else {
        // For mobile platforms
        final ImagePicker picker = ImagePicker();
        final XFile? videoFile = await picker.pickVideo(
          source: ImageSource.camera,
        );
        if (videoFile != null) {
          setState(() {
            _attachedVideos.add(videoFile.path);
          });
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Video Recording Error'),
            content: Text('Error recording video: $e'),
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
  }

  // Pick video from gallery
  Future<void> _pickVideoFromGallery() async {
    try {
      if (kIsWeb) {
        final ImagePicker picker = ImagePicker();
        final XFile? videoFile = await picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (videoFile != null) {
          final bytes = await videoFile.readAsBytes();
          final base64Video = base64Encode(bytes);
          setState(() {
            _attachedVideos.add('data:video/mp4;base64,$base64Video');
          });
        }
      } else {
        // For mobile platforms
        final ImagePicker picker = ImagePicker();
        final XFile? videoFile = await picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (videoFile != null) {
          setState(() {
            _attachedVideos.add(videoFile.path);
          });
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Video Selection Error'),
            content: Text('Error selecting video: $e'),
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
  }

  // Remove video from attachments
  void _removeVideo(int index) {
    setState(() {
      _attachedVideos.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Build image widget with error handling
  Widget _buildImageWidget(AppImage appImage) {
    if (!appImage.isValid) {
      return _buildErrorImageContainer();
    }

    if (kIsWeb && appImage.bytes != null) {
      // For web platform, use Image.memory directly with bytes
      return Image.memory(
        appImage.bytes!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return _buildErrorImageContainer();
        },
      );
    } else if (!kIsWeb && appImage.file != null) {
      // For mobile platforms, use Image.file
      return Image.file(
        appImage.file!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return _buildErrorImageContainer();
        },
      );
    } else {
      return _buildErrorImageContainer();
    }
  }

  Widget _buildErrorImageContainer() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red),
          Text('Error', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report a Civic Issue',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              '🤖 AI-powered automatic classification - just describe your issue!',
            ),
            const SizedBox(height: 24),

            // Issue Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Issue Title *',
                border: OutlineInputBorder(),
                helperText: 'Brief description of the issue',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an issue title';
                }
                return null;
              },
              onChanged: (value) => _updateAutoDetection(),
            ),
            const SizedBox(height: 16),

            // Auto-detected Category Display (replaces manual selection)
            if (_titleController.text.isNotEmpty &&
                _descriptionController.text.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🤖 AI Auto-Detected Category',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCategory ??
                                'Analyzing your description...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AUTO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '💡 Start typing to see AI auto-detect the category and department!',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Auto-detected Priority and Department Information
            if (_titleController.text.isNotEmpty &&
                _descriptionController.text.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Smart Analysis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.priority_high,
                        label: 'Priority',
                        value: _detectedPriority,
                        color: _getPriorityColor(_detectedPriority),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.domain,
                        label: 'Department',
                        value: _detectedDepartment,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Est. Resolution',
                        value: _estimatedResolution,
                        color: Colors.green,
                      ),
                      if (_departmentContact.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.phone,
                          label: 'Contact',
                          value: _departmentContact['phone'] ?? 'N/A',
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                suffixIcon: _isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.blue),
                        onPressed: _getCurrentLocation,
                        tooltip: 'Get current location',
                      ),
                helperText: '📍 Tap GPS icon for automatic address detection',
                helperStyle: TextStyle(color: Colors.blue.shade600),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Detailed Description *',
                border: OutlineInputBorder(),
                helperText:
                    '🤖 AI will auto-classify department based on your description',
              ),
              maxLines: 4,
              onChanged: (value) => _updateAutoDetection(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide a detailed description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Photo Upload
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Photos/Videos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Visual evidence helps resolve issues faster'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('From Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _recordVideo,
                            icon: const Icon(Icons.videocam),
                            label: const Text('Record Video'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickVideoFromGallery,
                            icon: const Icon(Icons.video_library),
                            label: const Text('Video Gallery'),
                          ),
                        ),
                      ],
                    ),
                    if (_attachedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Attached Images (${_attachedImages.length})',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildImageWidget(
                                      _attachedImages[index],
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_attachedVideos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Attached Videos (${_attachedVideos.length})',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedVideos.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.play_circle_fill,
                                        size: 40,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeVideo(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Ensure auto-detection has completed
                    if (_selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🤖 Please wait for AI classification to complete!',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    await _submitReport();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to convert AppImage to base64 string for web storage
  Future<String> _convertAppImageToBase64(AppImage appImage) async {
    try {
      if (kIsWeb && appImage.bytes != null) {
        // For web, use the bytes data
        final base64String = base64Encode(appImage.bytes!);
        return 'data:image/jpeg;base64,$base64String';
      } else if (!kIsWeb && appImage.file != null) {
        // For mobile, read file and convert to base64
        final bytes = await appImage.file!.readAsBytes();
        final base64String = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64String';
      } else {
        // Fallback - return placeholder
        return 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/wA==';
      }
    } catch (e) {
      print('Error converting image to base64: $e');
      return 'error_loading_image';
    }
  }

  Future<void> _submitReport() async {
    final now = DateTime.now();

    // Get actual user session data
    final userSession = await DatabaseService.instance.getCurrentUserSession();
    final userRegistration = await DatabaseService.instance
        .getCurrentUserRegistrationData();

    final currentUserId =
        userSession?['userId'] ??
        userRegistration?.id ??
        'anonymous_${now.millisecondsSinceEpoch}';
    final currentUserName =
        userSession?['userName'] ??
        userRegistration?.fullName ??
        'Anonymous User';
    final currentUserEmail =
        userSession?['userEmail'] ??
        userRegistration?.email ??
        'anonymous@example.com';

    // Convert images to base64 strings for web storage
    final imageUrls = <String>[];
    for (final appImage in _attachedImages) {
      final base64Image = await _convertAppImageToBase64(appImage);
      imageUrls.add(base64Image);
    }

    // Create a new report using the new Report model
    final newReport = Report(
      id: 'RPT${now.millisecondsSinceEpoch}',
      title: _titleController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      category: _selectedCategory!,
      createdAt: now,
      updatedAt: now,
      status: ReportStatus.submitted,
      reporterId: currentUserId,
      reporterName: currentUserName,
      reporterEmail: currentUserEmail,
      priority: _detectedPriority,
      department: _detectedDepartment,
      estimatedResolutionTime: _estimatedResolution,
      departmentContact: _departmentContact,
      imageUrls: imageUrls,
      videoUrls: _attachedVideos,
    );

    try {
      // Save to database
      await DatabaseService.instance.saveReport(newReport);

      // Show success message with attachment info
      final attachmentParts = <String>[];
      if (_attachedImages.isNotEmpty) {
        attachmentParts.add('${_attachedImages.length} image(s)');
      }
      if (_attachedVideos.isNotEmpty) {
        attachmentParts.add('${_attachedVideos.length} video(s)');
      }
      final attachmentText = attachmentParts.isNotEmpty
          ? ' with ${attachmentParts.join(' and ')} attached'
          : '';

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Report Submitted'),
              content: Text(
                'Thank you for reporting this issue! Your report ID is ${newReport.id}$attachmentText. It has been submitted and will be reviewed by the relevant department.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Clear form
                    _titleController.clear();
                    _descriptionController.clear();
                    _locationController.clear();
                    setState(() {
                      _selectedCategory = null;
                      _detectedPriority = 'Medium';
                      _detectedDepartment = 'General';
                      _estimatedResolution = '7-10 days';
                      _departmentContact = {};
                      _attachedImages.clear();
                      _attachedVideos.clear();
                    });
                    // Clear saved draft since report was submitted successfully
                    DatabaseService.instance.clearDraftReport();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
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
        return Colors.yellow.shade700;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Show location service disabled dialog
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.location_disabled, color: Colors.orange, size: 48),
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are turned off. Please enable location services in your device settings to auto-detect your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Manual Entry'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Show location permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.location_off, color: Colors.red, size: 48),
        title: const Text('Location Permission Required'),
        content: const Text(
          'CivicReporter needs location access to automatically detect your location for issue reporting. Please grant location permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Manual Entry'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  // Show location detection failed dialog
  void _showLocationFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.location_searching, color: Colors.orange, size: 48),
        title: const Text('Location Detection Failed'),
        content: const Text(
          'Unable to detect your current location. This could be due to poor GPS signal or network issues. You can enter your location manually or try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Manual Entry'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _getCurrentLocation(); // Retry
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

// My Reports Screen
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Report> userReports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserReports();
  }

  Future<void> _loadUserReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user session
      final userSession = await DatabaseService.instance
          .getCurrentUserSession();
      if (userSession != null) {
        final reports = await DatabaseService.instance.getReportsByUserId(
          userSession['userId']!,
        );
        if (mounted) {
          setState(() {
            userReports = reports;
            isLoading = false;
          });
        }
      } else {
        // No user session, show empty list
        if (mounted) {
          setState(() {
            userReports = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userReports = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Reports',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUserReports,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: userReports.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.report_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No reports submitted yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the Report tab to submit your first issue',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: userReports.length,
                    itemBuilder: (context, index) {
                      final report = userReports[index];
                      return _ReportCard(
                        report: report,
                        title: report.title,
                        location: report.location,
                        status: report.status.displayName,
                        statusColor: _getStatusColor(report.status),
                        date: _formatDate(report.createdAt),
                        reportId: report.id,
                      );
                    },
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

// Community Screen
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Community Reports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Text(
                'Community features coming soon!\n\n• View nearby issues\n• Community discussions\n• Local updates\n• Volunteer opportunities',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
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
              Text(title, textAlign: TextAlign.center),
            ],
          ),
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

class _ReportCard extends StatefulWidget {
  final Report report;
  final String title;
  final String location;
  final String status;
  final Color statusColor;
  final String date;
  final String reportId;

  const _ReportCard({
    required this.report,
    required this.title,
    required this.location,
    required this.status,
    required this.statusColor,
    required this.date,
    required this.reportId,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _hasFeedback = false;
  bool _isCheckingFeedback = false;

  @override
  void initState() {
    super.initState();
    _checkIfFeedbackExists();
  }

  Future<void> _checkIfFeedbackExists() async {
    print('🔍 [FEEDBACK] Checking feedback for report: ${widget.report.id}, status: ${widget.report.status}');
    
    if (widget.report.status != ReportStatus.done) {
      print('🔍 [FEEDBACK] Report status is not done (${widget.report.status}), skipping feedback check');
      return;
    }

    setState(() {
      _isCheckingFeedback = true;
    });

    try {
      final userSession = await DatabaseService.instance
          .getCurrentUserSession();
      if (userSession != null) {
        print('🔍 [FEEDBACK] User session found: ${userSession['userId']}');
        final hasFeedback = await DatabaseService.instance
            .hasUserProvidedFeedback(widget.report.id, userSession['userId']!);
        print('🔍 [FEEDBACK] Has feedback: $hasFeedback');
        if (mounted) {
          setState(() {
            _hasFeedback = hasFeedback;
            _isCheckingFeedback = false;
          });
        }
      } else {
        print('🔍 [FEEDBACK] No user session found');
      }
    } catch (e) {
      print('❌ [FEEDBACK] Error checking feedback: $e');
      if (mounted) {
        setState(() {
          _isCheckingFeedback = false;
        });
      }
    }
  }

  Future<void> _showFeedbackDialog() async {
    final userSession = await DatabaseService.instance.getCurrentUserSession();
    if (userSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to provide feedback'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FeedbackDialog(
        report: widget.report,
        userId: userSession['userId']!,
        userName: userSession['userName'] ?? 'Anonymous',
      ),
    );

    if (result == true && mounted) {
      // Feedback was submitted successfully
      setState(() {
        _hasFeedback = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = widget.report.status == ReportStatus.done;
    print('🔍 [FEEDBACK] Building report card - isResolved: $isResolved, isChecking: $_isCheckingFeedback');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.location),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.status,
                        style: TextStyle(
                          color: widget.statusColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_hasFeedback)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.feedback,
                              size: 12,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Feedback Given',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Text(widget.date, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            trailing: Text(
              widget.reportId,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),

          // Feedback Section for Resolved Reports
          if (isResolved && !_isCheckingFeedback)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: _hasFeedback
                  ? Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thank you for your feedback!',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          color: Colors.green[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your issue has been resolved! Share your experience:',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _showFeedbackDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Give Feedback',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

// Feedback Notification Section Widget
class _FeedbackNotificationSection extends StatefulWidget {
  @override
  _FeedbackNotificationSectionState createState() => _FeedbackNotificationSectionState();
}

class _FeedbackNotificationSectionState extends State<_FeedbackNotificationSection> {
  List<Report> _pendingFeedbackReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingFeedbackReports();
  }

  Future<void> _loadPendingFeedbackReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userSession = await DatabaseService.instance.getCurrentUserSession();
      
      if (userSession != null) {
        final allReports = await DatabaseService.instance.getReportsByUserId(
          userSession['userId']!,
        );
        
        // Filter for completed reports without feedback
        final pendingReports = <Report>[];
        for (final report in allReports) {
          if (report.status == ReportStatus.done) {
            final hasFeedback = await DatabaseService.instance
                .hasUserProvidedFeedback(report.id, userSession['userId']!);
            if (!hasFeedback) {
              pendingReports.add(report);
            }
          }
        }

        setState(() {
          _pendingFeedbackReports = pendingReports;
          _isLoading = false;
        });
      } else {
        setState(() {
          _pendingFeedbackReports = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading pending feedback reports: $e');
      setState(() {
        _pendingFeedbackReports = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _showFeedbackDialog(Report report) async {
    final userSession = await DatabaseService.instance.getCurrentUserSession();
    if (userSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to provide feedback'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FeedbackDialog(
        report: report,
        userId: userSession['userId']!,
        userName: userSession['userName'] ?? 'Anonymous',
      ),
    );

    if (result == true && mounted) {
      // Feedback was submitted successfully, reload the list
      _loadPendingFeedbackReports();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View All',
            onPressed: () {
              // This could navigate to the My Reports tab
            },
          ),
        ),
      );
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
              Text(
                'Checking for feedback opportunities...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingFeedbackReports.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no pending feedback
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.feedback_outlined,
              color: Colors.green[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Feedback Needed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green[700],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_pendingFeedbackReports.length}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_pendingFeedbackReports.length} of your ${_pendingFeedbackReports.length == 1 ? 'issue has' : 'issues have'} been resolved!',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Help us improve our services by sharing your experience.',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pendingFeedbackReports.take(3).map((report) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: InkWell(
                        onTap: () => _showFeedbackDialog(report),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                report.title.length > 20 
                                    ? '${report.title.substring(0, 20)}...'
                                    : report.title,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star_border,
                                size: 14,
                                color: Colors.green[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_pendingFeedbackReports.length > 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    'and ${_pendingFeedbackReports.length - 3} more...',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_pendingFeedbackReports.isNotEmpty) {
                            _showFeedbackDialog(_pendingFeedbackReports.first);
                          }
                        },
                        icon: const Icon(Icons.feedback, size: 16),
                        label: const Text('Give Feedback'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // This could navigate to My Reports tab
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Photo Option Tile Widget
