import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/environment_service.dart';
import '../providers/environment_provider.dart';
import '../config/server_config.dart';

class QuickServerSwitchDialog extends StatefulWidget {
  const QuickServerSwitchDialog({Key? key}) : super(key: key);

  @override
  State<QuickServerSwitchDialog> createState() => _QuickServerSwitchDialogState();
}

class _QuickServerSwitchDialogState extends State<QuickServerSwitchDialog> {
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

  Future<void> _switchServer(String environment) async {
    if (_isLoading || environment == _currentEnvironment) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await EnvironmentService.instance.switchEnvironment(environment);
      
      if (success && mounted) {
        setState(() {
          _currentEnvironment = environment;
        });
        
        // Update provider
        if (mounted) {
          final provider = Provider.of<EnvironmentProvider>(context, listen: false);
          await provider.switchEnvironment(environment);
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Switched to ${ServerConfig.getConfig(environment).name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Close dialog after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to switch server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = ServerConfig.getConfig(_currentEnvironment);
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_sync, color: Colors.blue),
          SizedBox(width: 8),
          Text('Switch Server'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Server:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Row(
              children: [
                Text(
                  currentConfig.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentConfig.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        currentConfig.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currentConfig.baseURL,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Switch to:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...ServerConfig.getAllConfigs().entries
              .where((entry) => entry.key != _currentEnvironment)
              .map((entry) => _buildServerOption(entry.key, entry.value))
              .toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildServerOption(String environment, ServerConfigModel config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isLoading ? null : () => _switchServer(environment),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                config.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      config.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      config.baseURL,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}