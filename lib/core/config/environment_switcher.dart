import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvironmentSwitcher {
  static const String _environmentKey = 'selected_environment';
  
  // Server configurations
  static const Map<String, ServerConfig> _configs = {
    'development': ServerConfig(
      name: 'Localhost Development',
      baseUrl: 'http://localhost:3000/api',
      socketUrl: 'http://localhost:3000',
      timeout: 10,
      description: 'Local development server',
      icon: '💻',
    ),
    'production': ServerConfig(
      name: 'Render.com Production', 
      baseUrl: 'https://civic-welfare-backend.onrender.com/api',
      socketUrl: 'https://civic-welfare-backend.onrender.com',
      timeout: 15,
      description: 'Live cloud server',
      icon: '☁️',
    ),
  };
  
  // Current environment (defaults to production for mobile deployment)
  static String _currentEnvironment = 'production';
  
  // Initialize environment from storage
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentEnvironment = prefs.getString(_environmentKey) ?? 'production';
    printConfiguration();
  }
  
  // Switch environment
  static Future<void> switchTo(String environment) async {
    if (_configs.containsKey(environment)) {
      _currentEnvironment = environment;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_environmentKey, environment);
      printConfiguration();
    }
  }
  
  // Get all available environments
  static List<String> get availableEnvironments => _configs.keys.toList();
  
  // Get current environment name
  static String get currentEnvironment => _currentEnvironment;
  
  // Get current configuration
  static ServerConfig get config {
    return _configs[_currentEnvironment] ?? _configs['production']!;
  }
  
  // Get specific config
  static ServerConfig? getConfig(String environment) {
    return _configs[environment];
  }
  
  // Quick access methods
  static String get baseUrl => config.baseUrl;
  static String get socketUrl => config.socketUrl;
  static Duration get timeout => Duration(seconds: config.timeout);
  static bool get isProduction => _currentEnvironment == 'production';
  static bool get isDevelopment => _currentEnvironment == 'development';
  
  // Debug information
  static void printConfiguration() {
    if (kDebugMode) {
      print('🔧 ===== API CONFIGURATION =====');
      print('   Environment: $_currentEnvironment');
      print('   Server Name: ${config.name}');
      print('   Base URL: ${config.baseUrl}');
      print('   Socket URL: ${config.socketUrl}');
      print('   Timeout: ${config.timeout}s');
      print('   Production Mode: $isProduction');
      print('🔧 =============================');
    }
  }
}

class ServerConfig {
  final String name;
  final String baseUrl;
  final String socketUrl;
  final int timeout;
  final String description;
  final String icon;
  
  const ServerConfig({
    required this.name,
    required this.baseUrl,
    required this.socketUrl,
    required this.timeout,
    required this.description,
    required this.icon,
  });
}