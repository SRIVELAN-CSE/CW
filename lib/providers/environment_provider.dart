import 'package:flutter/foundation.dart';
import '../services/environment_service.dart';
import '../config/server_config.dart';

class EnvironmentProvider with ChangeNotifier {
  String _currentEnvironment = 'local';
  bool _isLoading = false;
  String? _error;

  String get currentEnvironment => _currentEnvironment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  ServerConfigModel get currentConfig => EnvironmentService.instance.currentConfig;
  bool get isLocal => _currentEnvironment == 'local';
  bool get isCloud => _currentEnvironment == 'cloud';

  // Initialize environment provider
  Future<void> initialize() async {
    _currentEnvironment = EnvironmentService.instance.currentEnvironment;
    notifyListeners();
  }

  // Switch environment
  Future<bool> switchEnvironment(String newEnvironment) async {
    if (_isLoading || newEnvironment == _currentEnvironment) return false;

    _setLoading(true);
    _setError(null);

    try {
      final success = await EnvironmentService.instance.switchEnvironment(newEnvironment);
      
      if (success) {
        _currentEnvironment = newEnvironment;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to switch environment');
        return false;
      }
    } catch (e) {
      _setError('Error switching environment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get environment info
  Map<String, dynamic> getEnvironmentInfo() {
    return EnvironmentService.instance.getEnvironmentInfo();
  }

  // Get all available environments
  List<String> getAvailableEnvironments() {
    return EnvironmentService.instance.getAvailableEnvironments();
  }

  // Get all configurations
  Map<String, ServerConfigModel> getAllConfigurations() {
    return EnvironmentService.instance.getAllConfigurations();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}