import 'package:flutter/material.dart';
import '../config/environment_switcher.dart';

class EnvironmentSwitcherWidget extends StatefulWidget {
  final Function(String)? onEnvironmentChanged;
  
  const EnvironmentSwitcherWidget({
    Key? key,
    this.onEnvironmentChanged,
  }) : super(key: key);

  @override
  State<EnvironmentSwitcherWidget> createState() => _EnvironmentSwitcherWidgetState();
}

class _EnvironmentSwitcherWidgetState extends State<EnvironmentSwitcherWidget> {
  String _currentEnvironment = EnvironmentSwitcher.currentEnvironment;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Server Configuration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current server info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        EnvironmentSwitcher.config.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current: ${EnvironmentSwitcher.config.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: EnvironmentSwitcher.isProduction
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          EnvironmentSwitcher.isProduction ? 'LIVE' : 'DEV',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    EnvironmentSwitcher.config.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    EnvironmentSwitcher.config.baseUrl,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Environment selector
            Text(
              'Select Server Environment:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            ...EnvironmentSwitcher.availableEnvironments.map((env) {
              final config = EnvironmentSwitcher.getConfig(env)!;
              final isSelected = env == _currentEnvironment;
              
              return Card(
                elevation: isSelected ? 3 : 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
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
                        config.baseUrl,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: env == 'production' ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${config.timeout}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Radio<String>(
                        value: env,
                        groupValue: _currentEnvironment,
                        onChanged: _isLoading ? null : (String? value) {
                          if (value != null) {
                            _switchEnvironment(value);
                          }
                        },
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onTap: _isLoading ? null : () => _switchEnvironment(env),
                ),
              );
            }).toList(),
            
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Switching server...'),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _switchEnvironment('development'),
                    icon: const Text('💻'),
                    label: const Text('Use Local'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentEnvironment == 'development' 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300],
                      foregroundColor: _currentEnvironment == 'development' 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _switchEnvironment('production'),
                    icon: const Text('☁️'),
                    label: const Text('Use Cloud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentEnvironment == 'production' 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300],
                      foregroundColor: _currentEnvironment == 'production' 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Info text
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'App will restart after switching servers. Make sure the selected server is running.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber[700],
                      ),
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

  void _switchEnvironment(String environment) async {
    if (environment == _currentEnvironment) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await EnvironmentSwitcher.switchTo(environment);
      
      setState(() {
        _currentEnvironment = environment;
        _isLoading = false;
      });
      
      // Notify parent widget
      widget.onEnvironmentChanged?.call(environment);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(EnvironmentSwitcher.config.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Switched to ${EnvironmentSwitcher.config.name}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}