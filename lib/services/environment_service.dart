import 'package:shared_preferences/shared_preferences.dart';
import '../config/server_config.dart';

class EnvironmentService {
  static const String _environmentKey = 'current_server_environment';
  static const String _defaultEnvironment = 'cloud'; // Default to cloud server since it's deployed
  
  static EnvironmentService? _instance;
  static EnvironmentService get instance => _instance ??= EnvironmentService._();
  
  EnvironmentService._();
  
  SharedPreferences? _prefs;
  String _currentEnvironment = _defaultEnvironment;
  
  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentEnvironment = _prefs?.getString(_environmentKey) ?? _defaultEnvironment;
    
    print('🌐 Environment Service initialized: $_currentEnvironment');
    print('� Current API URL: ${currentConfig.apiURL}');
  }
  
  // Get current environment
  String get currentEnvironment => _currentEnvironment;
  
  // Get current server configuration
  ServerConfigModel get currentConfig => ServerConfig.getConfig(_currentEnvironment);
  
  // Switch to a different environment
  Future<bool> switchEnvironment(String environment) async {
    if (!ServerConfig.isValidEnvironment(environment)) {
      return false;
    }
    
    _currentEnvironment = environment;
    await _prefs?.setString(_environmentKey, environment);
    return true;
  }
  
  // Get all available environments
  List<String> getAvailableEnvironments() {
    return ServerConfig.getAvailableEnvironments();
  }
  
  // Get all configurations
  Map<String, ServerConfigModel> getAllConfigurations() {
    return ServerConfig.getAllConfigs();
  }
  
  // Check if current environment is local
  bool get isLocal => _currentEnvironment == 'local';
  
  // Check if current environment is cloud
  bool get isCloud => _currentEnvironment == 'cloud';
  
  // Reset to default environment
  Future<void> resetToDefault() async {
    await switchEnvironment(_defaultEnvironment);
  }
  
  // Get environment display info
  Map<String, dynamic> getEnvironmentInfo() {
    final config = currentConfig;
    return {
      'environment': _currentEnvironment,
      'name': config.name,
      'baseURL': config.baseURL,
      'description': config.description,
      'icon': config.icon,
      'color': config.color,
    };
  }
}