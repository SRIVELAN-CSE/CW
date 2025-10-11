import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/environment_service.dart';
import '../providers/environment_provider.dart';

class ServerSwitchWidget extends StatefulWidget {
  final Function(String)? onEnvironmentChanged;
  
  const ServerSwitchWidget({
    Key? key,
    this.onEnvironmentChanged,
  }) : super(key: key);

  @override
  State<ServerSwitchWidget> createState() => _ServerSwitchWidgetState();
}

class _ServerSwitchWidgetState extends State<ServerSwitchWidget> {
  String _currentEnvironment = 'local';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentEnvironment();
  }

  void _loadCurrentEnvironment() {
    setState(() {
      _currentEnvironment = EnvironmentService.instance.currentEnvironment;
    });
  }

  Future<void> _switchEnvironment(String newEnvironment) async {
    if (_isLoading || newEnvironment == _currentEnvironment) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await EnvironmentService.instance.switchEnvironment(newEnvironment);
      
      if (success) {
        setState(() {
          _currentEnvironment = newEnvironment;
        });
        
        // Notify parent widget about environment change
        widget.onEnvironmentChanged?.call(newEnvironment);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Switched to ${EnvironmentService.instance.currentConfig.name}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to switch environment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to switch server: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final configs = EnvironmentService.instance.getAllConfigurations();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dns,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Environment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Switch between local and cloud server',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Current Environment Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Text(
                  configs[_currentEnvironment]?.icon ?? '📡',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current: ${configs[_currentEnvironment]?.name ?? 'Unknown'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        configs[_currentEnvironment]?.description ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        configs[_currentEnvironment]?.baseURL ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEnvironmentColor(_currentEnvironment).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentEnvironment.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getEnvironmentColor(_currentEnvironment),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Environment Options
          ...configs.entries.map((entry) {
            final environment = entry.key;
            final config = entry.value;
            final isSelected = environment == _currentEnvironment;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: _isLoading ? null : () => _switchEnvironment(environment),
                leading: Text(
                  config.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  config.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(config.description),
                    Text(
                      config.baseURL,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                trailing: _isLoading && !isSelected
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : isSelected
                        ? Icon(Icons.check_circle, color: _getEnvironmentColor(environment))
                        : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
                selected: isSelected,
                selectedTileColor: _getEnvironmentColor(environment).withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected 
                        ? _getEnvironmentColor(environment).withOpacity(0.3)
                        : Colors.grey[200]!,
                  ),
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 12),
          
          // Warning for production
          if (_currentEnvironment == 'cloud')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are connected to the production server. Data will be synced across all devices.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
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

  Color _getEnvironmentColor(String environment) {
    switch (environment) {
      case 'local':
        return Colors.blue;
      case 'cloud':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Full-screen server settings page
class ServerSettingsScreen extends StatelessWidget {
  const ServerSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Server Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ServerSwitchWidget(
              onEnvironmentChanged: (environment) {
                // Handle environment change if needed
                // For example, refresh data, reconnect websockets, etc.
              },
            ),
            const SizedBox(height: 20),
            
            // Additional server information
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(Icons.developer_mode, 'Local Server', 'For development and testing'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.cloud, 'Cloud Server', 'Production server with real-time sync'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.sync, 'Data Sync', 'Cloud server syncs data across all devices'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.security, 'Security', 'All connections are secured with HTTPS/WSS'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}