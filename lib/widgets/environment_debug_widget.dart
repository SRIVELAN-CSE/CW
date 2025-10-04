import 'package:flutter/material.dart';
import '../core/config/environment_switcher.dart';
import '../services/backend_api_service.dart';

class EnvironmentDebugWidget extends StatefulWidget {
  const EnvironmentDebugWidget({Key? key}) : super(key: key);

  @override
  State<EnvironmentDebugWidget> createState() => _EnvironmentDebugWidgetState();
}

class _EnvironmentDebugWidgetState extends State<EnvironmentDebugWidget> {
  bool _isLoading = false;
  String _connectionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkEnvironment();
  }

  Future<void> _checkEnvironment() async {
    setState(() => _isLoading = true);
    
    await EnvironmentSwitcher.initialize();
    
    // Test backend connection
    final isConnected = await BackendApiService.testConnection();
    setState(() {
      _connectionStatus = isConnected ? '✅ Connected' : '❌ Disconnected';
      _isLoading = false;
    });
  }

  Future<void> _switchToProduction() async {
    setState(() => _isLoading = true);
    await EnvironmentSwitcher.switchToProduction();
    await _checkEnvironment();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚀 Switched to Production Mode - All data will save to MongoDB Atlas!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _switchToDevelopment() async {
    setState(() => _isLoading = true);
    await EnvironmentSwitcher.switchToDevelopment();
    await _checkEnvironment();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔧 Switched to Development Mode'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Environment Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              _buildInfoRow('Current Environment', EnvironmentSwitcher.currentEnvironment),
              _buildInfoRow('Backend URL', EnvironmentSwitcher.baseUrl),
              _buildInfoRow('Connection Status', _connectionStatus),
              _buildInfoRow('Production Mode', EnvironmentSwitcher.isProduction ? '✅ ON' : '❌ OFF'),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: EnvironmentSwitcher.isProduction ? null : _switchToProduction,
                    icon: const Icon(Icons.cloud),
                    label: const Text('Production'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EnvironmentSwitcher.isProduction ? Colors.green : null,
                      foregroundColor: EnvironmentSwitcher.isProduction ? Colors.white : null,
                    ),
                  ),
                  
                  ElevatedButton.icon(
                    onPressed: EnvironmentSwitcher.isDevelopment ? null : _switchToDevelopment,
                    icon: const Icon(Icons.computer),
                    label: const Text('Development'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EnvironmentSwitcher.isDevelopment ? Colors.orange : null,
                      foregroundColor: EnvironmentSwitcher.isDevelopment ? Colors.white : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              ElevatedButton.icon(
                onPressed: _checkEnvironment,
                icon: const Icon(Icons.refresh),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EnvironmentSwitcher.isProduction ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: EnvironmentSwitcher.isProduction ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    EnvironmentSwitcher.isProduction 
                        ? '🚀 PRODUCTION MODE ACTIVE'
                        : '🔧 DEVELOPMENT MODE ACTIVE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: EnvironmentSwitcher.isProduction ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    EnvironmentSwitcher.isProduction
                        ? 'All data is saved to MongoDB Atlas via Render server'
                        : 'Data may be saved locally depending on connection',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}