import 'package:flutter/material.dart';
import 'screens/auth/user_type_selection_screen.dart';
import 'services/database_service.dart';
import 'screens/public/public_dashboard_screen.dart';
import 'screens/officer/officer_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'core/utils/storage_debugger.dart';
import 'core/config/environment_switcher.dart';
import 'core/config/startup_environment_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting CivicWelfare App...');
  
  // Initialize environment switcher first
  await EnvironmentSwitcher.initialize();
  
  // Print current configuration
  print('🔧 Environment: ${EnvironmentSwitcher.currentEnvironment}');
  print('🌐 API Base URL: ${EnvironmentSwitcher.baseUrl}');
  print('🔗 Socket URL: ${EnvironmentSwitcher.socketUrl}');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicWelfare',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _environmentSelected = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for environment to be initialized
    await EnvironmentSwitcher.initialize();
    
    // Show environment selector first if not selected
    setState(() {
      _environmentSelected = true;
    });
    
    // Continue with app initialization after a delay
    await Future.delayed(const Duration(milliseconds: 500));
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      // Debug localStorage functionality
      print('🔍 Testing localStorage functionality...');
      StorageDebugger.testLocalStorage();
      
      // NEW: Initialize backend synchronization
      print('🔍 Initializing backend database connection...');
      await DatabaseService.instance.initializeBackendSync();
      
      final session = await DatabaseService.instance.getCurrentUserSession();
      print('🔍 Current user session: $session');
      
      if (session != null && session.isNotEmpty) {
        // User has an active session, navigate to appropriate dashboard
        final userType = session['userRole'] ?? session['userType']; // Check both keys for compatibility
        print('🔍 User type from session: $userType');
        
        if (mounted) {
          switch (userType) {
            case 'citizen':
            case 'public':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PublicDashboardScreen()),
              );
              break;
            case 'officer':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const OfficerDashboardScreen()),
              );
              break;
            case 'admin':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              );
              break;
            default:
              // Unknown user type, go to selection screen
              print('🔍 Unknown user type: $userType, redirecting to selection');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              );
          }
        }
      } else {
        // No active session, show welcome screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage()),
          );
        }
      }
    } catch (e) {
      print('Error checking user session: $e');
      // On error, default to welcome screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show environment selector if not selected
    if (!_environmentSelected) {
      return StartupEnvironmentSelector(
        onEnvironmentSelected: (env) {
          setState(() {
            _environmentSelected = true;
          });
          _checkUserSession();
        },
      );
    }
    
    // Show splash screen after environment is selected
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city,
              size: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'CivicWelfare',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Empowering Communities',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('CivicWelfare - Empowering Communities'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.location_city,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to CivicWelfare',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Report civic issues, track progress, and build better communities together.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserTypeSelectionScreen(),
                  ),
                );
              },
              child: const Text('Get Started'),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                // TODO: Show app information
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('About CivicWelfare'),
                      content: const Text(
                        'CivicWelfare is a crowdsourced civic issue reporting and resolution system. '
                        'It enables citizens to report issues, officers to manage them, and administrators to oversee the entire process.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('About'),
            ),
          ],
        ),
      ),
    );
  }
}
