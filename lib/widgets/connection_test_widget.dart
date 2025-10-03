import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Connection Test Widget - Add this to your Flutter app to test backend connection
class ConnectionTestWidget extends StatefulWidget {
  const ConnectionTestWidget({Key? key}) : super(key: key);

  @override
  _ConnectionTestWidgetState createState() => _ConnectionTestWidgetState();
}

class _ConnectionTestWidgetState extends State<ConnectionTestWidget> {
  String _connectionStatus = 'Testing...';
  Color _statusColor = Colors.orange;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionStatus = 'Testing backend connection...';
      _statusColor = Colors.orange;
      _isLoading = true;
    });

    try {
      // Test 1: Health Check
      final response = await http.get(
        Uri.parse('https://civic-welfare-backend.onrender.com/api/health'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _connectionStatus = 'Backend Connected!\nStatus: ${data['status']}\nDatabase: ${data['database']}';
          _statusColor = Colors.green;
          _isLoading = false;
        });

        // Test 2: Admin Login Test
        await _testAdminLogin();
      } else {
        setState(() {
          _connectionStatus = 'Connection Failed!\nStatus: ${response.statusCode}';
          _statusColor = Colors.red;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection Error!\n$e';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _testAdminLogin() async {
    try {
      final response = await http.post(
        Uri.parse('https://civic-welfare-backend.onrender.com/api/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': 'admin@civicwelfare.com',
          'password': 'admin123456'
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _connectionStatus += '\n\n✅ Admin Login: SUCCESS\nUser: ${data['data']['user']['name']}';
        });
      } else {
        setState(() {
          _connectionStatus += '\n\n❌ Admin Login: FAILED';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus += '\n\n❌ Admin Login: ERROR\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLoading ? Icons.refresh : 
                  (_statusColor == Colors.green ? Icons.check_circle : Icons.error),
                  color: _statusColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Backend Connection Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const LinearProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  border: Border.all(color: _statusColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _connectionStatus,
                  style: TextStyle(
                    color: _statusColor == Colors.orange ? Colors.black : _statusColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _testConnection,
                  child: const Text('Retest Connection'),
                ),
                const SizedBox(width: 12),
                if (_statusColor == Colors.green)
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to main app or close test
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connection successful! You can now use the app.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Continue to App'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '🔗 Backend: https://civic-welfare-backend.onrender.com\n'
              '🔐 Admin: admin@civicwelfare.com / admin123456',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Usage: Add this widget to your main screen to test connection
class ConnectionTestScreen extends StatelessWidget {
  const ConnectionTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicWelfare - Connection Test'),
        backgroundColor: Colors.blue,
      ),
      body: const SingleChildScrollView(
        child: ConnectionTestWidget(),
      ),
    );
  }
}