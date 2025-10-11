import 'package:flutter/material.dart';
import 'officer_dashboard_screen.dart';
import 'officer_forgot_password_screen.dart';
import '../../services/database_service.dart';
import '../auth/officer_registration_screen.dart';

class OfficerLoginScreen extends StatefulWidget {
  const OfficerLoginScreen({super.key});

  @override
  State<OfficerLoginScreen> createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _officerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _officerIdController.text.trim();
        final password = _passwordController.text.trim();

        // Authenticate officer with backend (live data)
        final authResult = await DatabaseService.instance.authenticateUser(
          email,
          password,
        );

        if (authResult == null || !authResult['success']) {
          // Try fallback to local validation for offline mode
          final user = await DatabaseService.instance.validateUserLogin(
            email,
            password,
          );

          if (user == null) {
            // Check if user exists but password is wrong
            final hasExistingRegistration = await DatabaseService.instance
                .hasExistingRegistration(email);

            if (hasExistingRegistration) {
              _showStatusDialog(
                'Login Failed',
                'Invalid email or password. Please check your credentials and try again.',
                'invalid_credentials',
              );
            } else {
              _showStatusDialog(
                'Account Not Found',
                'No officer account found for this email address. Please contact admin for account creation.',
                'not_found',
              );
            }
            return;
          }

          // Check if user is actually an officer
          if (user.userType != 'officer') {
            _showStatusDialog(
              'Access Denied',
              'This account is not registered as an officer. Please use the appropriate login portal.',
              'wrong_type',
            );
            return;
          }

          // Save user session (fallback mode)
          await DatabaseService.instance.saveUserSession(
            userId: user.id,
            userName: user.fullName,
            userEmail: user.email,
            userRole: user.userType,
            department: user.department,
          );
        } else {
          // Backend authentication successful
          final userInfo = authResult['user'];

          // Check if user is actually an officer
          if (userInfo['user_type'] != 'officer') {
            _showStatusDialog(
              'Access Denied',
              'This account is not registered as an officer. Please use the appropriate login portal.',
              'wrong_type',
            );
            return;
          }

          // User session already saved in authenticateUser method
          print('✅ Officer login successful with live backend data');
        }

        // Navigate to officer dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OfficerDashboardScreen(),
          ),
        );
      } catch (e) {
        _showStatusDialog(
          'Login Error',
          'An error occurred during login: $e',
          'error',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Login'),
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
              Icon(Icons.badge, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Officer Portal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Access your department dashboard',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Officer Email Field
              TextFormField(
                controller: _officerIdController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Officer Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Login to Department Portal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Forgot Password Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OfficerForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Registration Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Need an officer account? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const OfficerRegistrationScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Register Here',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Help Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'For Official Use Only',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact your department administrator for login credentials. Unauthorized access is prohibited.',
                      style: TextStyle(fontSize: 12, color: Colors.green[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusDialog(String title, String message, String type) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'invalid_credentials':
        icon = Icons.error_outline;
        iconColor = Colors.red;
        break;
      case 'not_found':
        icon = Icons.person_off;
        iconColor = Colors.orange;
        break;
      case 'wrong_type':
        icon = Icons.block;
        iconColor = Colors.red;
        break;
      case 'error':
        icon = Icons.error;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
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
            if (type == 'not_found') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Need an Officer Account?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Officer accounts are created by system administrators. Please contact your admin to create an account.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                      textAlign: TextAlign.center,
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
}
