import 'package:flutter/foundation.dart';

class EnvironmentSwitcher {
  // 🔧 CHANGE THIS VALUE TO SWITCH BETWEEN SERVERS
  // Set to 'development' for localhost or 'production' for Render.com
  static const String currentEnvironment = 'production'; // 👈 Change this!
  
  // Server configurations
  static const Map<String, ServerConfig> _configs = {
    'development': ServerConfig(
      name: 'Localhost Development',
      baseUrl: 'http://localhost:3000/api',
      socketUrl: 'http://localhost:3000',
      timeout: 10,
    ),
    'production': ServerConfig(
      name: 'Render.com Production',
      baseUrl: 'https://civic-welfare-backend.onrender.com/api',
      socketUrl: 'https://civic-welfare-backend.onrender.com',
      timeout: 15,
    ),
  };
  
  // Get current configuration
  static ServerConfig get config {
    return _configs[currentEnvironment] ?? _configs['development']!;
  }
  
  // Quick access methods
  static String get baseUrl => config.baseUrl;
  static String get socketUrl => config.socketUrl;
  static Duration get timeout => Duration(seconds: config.timeout);
  static bool get isProduction => currentEnvironment == 'production';
  static bool get isDevelopment => currentEnvironment == 'development';
  
  // Debug information
  static void printConfiguration() {
    if (kDebugMode) {
      print('🔧 ===== API CONFIGURATION =====');
      print('   Environment: $currentEnvironment');
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
  
  const ServerConfig({
    required this.name,
    required this.baseUrl,
    required this.socketUrl,
    required this.timeout,
  });
}