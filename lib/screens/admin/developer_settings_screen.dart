import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() => _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  String _selectedEnvironment = ApiConfig.currentEnvironment;
  bool _showDebugInfo = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showDebugInfo = prefs.getBool('show_debug_info') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_debug_info', _showDebugInfo);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Restart the app to apply server changes'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Developer Settings'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server Environment Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Server Environment',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Development Option
                    RadioListTile<String>(
                      title: const Text('🏠 Localhost Development'),
                      subtitle: const Text('http://localhost:3000/api'),
                      value: 'development',
                      groupValue: _selectedEnvironment,
                      onChanged: (value) {
                        setState(() {
                          _selectedEnvironment = value!;
                        });
                      },
                    ),
                    
                    // Production Option
                    RadioListTile<String>(
                      title: const Text('☁️ Render.com Production'),
                      subtitle: const Text('https://civic-welfare-backend.onrender.com/api'),
                      value: 'production',
                      groupValue: _selectedEnvironment,
                      onChanged: (value) {
                        setState(() {
                          _selectedEnvironment = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status Indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedEnvironment == 'development' 
                            ? Colors.green.shade50 
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedEnvironment == 'development' 
                              ? Colors.green 
                              : Colors.blue,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedEnvironment == 'development' 
                                ? Icons.computer 
                                : Icons.cloud_done,
                            color: _selectedEnvironment == 'development' 
                                ? Colors.green 
                                : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Currently using: ${_selectedEnvironment == 'development' ? 'Local Server' : 'Cloud Server'}',
                            style: TextStyle(
                              color: _selectedEnvironment == 'development' 
                                  ? Colors.green.shade800 
                                  : Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
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
            
            // Debug Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Debug Settings',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Show Debug Information'),
                      subtitle: const Text('Display API calls and responses in console'),
                      value: _showDebugInfo,
                      onChanged: (value) {
                        setState(() {
                          _showDebugInfo = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current Configuration Display
            if (_showDebugInfo) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Current Configuration',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoRow('Environment:', ApiConfig.environmentName),
                      _buildInfoRow('Base URL:', ApiConfig.baseUrl),
                      _buildInfoRow('Socket URL:', ApiConfig.socketUrl),
                      _buildInfoRow('Timeout:', '${ApiConfig.apiTimeout.inSeconds}s'),
                      _buildInfoRow('Production Mode:', ApiConfig.isProduction.toString()),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '💾 Apply Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Warning Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Server environment changes require editing lib/core/config/api_config.dart and restarting the app.',
                      style: TextStyle(color: Colors.orange),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}