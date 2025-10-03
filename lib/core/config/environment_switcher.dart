import 'package:shared_preferences/shared_preferences.dart';

class EnvironmentSwitcher {
  // Development server configuration (Local)
  static const String _devBaseUrl = 'http://localhost:3000/api'; // Chrome/Web localhost
  static const String _devServerName = 'Local Development Server';

  // Production server configuration (Render.com)
  static const String _prodBaseUrl = 'https://civic-welfare-backend.onrender.com/api';
  static const String _prodServerName = 'Render Cloud Server';

  // Current environment flag (default to production for APK)
  static bool _useProduction = true;
  static bool _initialized = false;

  // Initialize environment from persistent storage
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _useProduction = prefs.getBool('use_production_environment') ?? true;
      _initialized = true;
      print('🔧 Environment initialized: ${currentEnvironment}');
      print('📡 Base URL: ${baseUrl}');
    } catch (e) {
      print('⚠️ Failed to load environment preference: $e');
      _useProduction = true; // Default to production
      _initialized = true;
    }
  }

  // Save environment preference
  static Future<void> _saveEnvironmentPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_production_environment', _useProduction);
      print('💾 Environment preference saved: ${_useProduction ? 'Production' : 'Development'}');
    } catch (e) {
      print('⚠️ Failed to save environment preference: $e');
    }
  }

  /// Get current environment name
  static String get currentEnvironment => _useProduction ? _prodServerName : _devServerName;

  /// Get current base URL based on environment
  static String get baseUrl => _useProduction ? _prodBaseUrl : _devBaseUrl;

  /// Get development base URL
  static String get developmentBaseUrl => _devBaseUrl;

  /// Get production base URL
  static String get productionBaseUrl => _prodBaseUrl;

  /// Switch to development environment (Local Server)
  static Future<void> switchToDevelopment() async {
    await initialize();
    _useProduction = false;
    await _saveEnvironmentPreference();
    print('🔄 Switched to Development: $_devBaseUrl');
  }

  /// Switch to production environment (Render Cloud Server)
  static Future<void> switchToProduction() async {
    await initialize();
    _useProduction = true;
    await _saveEnvironmentPreference();
    print('🔄 Switched to Production: $_prodBaseUrl');
  }

  /// Toggle between environments
  static Future<void> toggleEnvironment() async {
    await initialize();
    _useProduction = !_useProduction;
    await _saveEnvironmentPreference();
    print('🔄 Environment switched to: ${currentEnvironment}');
    print('📡 Base URL: ${baseUrl}');
  }

  /// Check if using production environment
  static bool get isProduction => _useProduction;

  /// Check if using development environment
  static bool get isDevelopment => !_useProduction;

  /// Get environment status for debugging
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': currentEnvironment,
      'baseUrl': baseUrl,
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Set environment programmatically
  static void setEnvironment(bool useProduction) {
    _useProduction = useProduction;
    print('🔧 Environment set to: ${currentEnvironment}');
    print('📡 Base URL: ${baseUrl}');
  }
}
