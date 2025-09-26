class EnvironmentSwitcher {
  // Development server configuration (Local)
  static const String _devBaseUrl = 'http://127.0.0.1:3000/api';
  static const String _devServerName = 'Local Development Server';

  // Production server configuration (Render.com)
  static const String _prodBaseUrl = 'https://civic-welfare-backend.onrender.com/api';
  static const String _prodServerName = 'Render Cloud Server';

  // Current environment flag (default to production for APK)
  static bool _useProduction = true;

  /// Get current environment name
  static String get currentEnvironment => _useProduction ? _prodServerName : _devServerName;

  /// Get current base URL based on environment
  static String get baseUrl => _useProduction ? _prodBaseUrl : _devBaseUrl;

  /// Get development base URL
  static String get developmentBaseUrl => _devBaseUrl;

  /// Get production base URL
  static String get productionBaseUrl => _prodBaseUrl;

  /// Switch to development environment (Local Server)
  static void switchToDevelopment() {
    _useProduction = false;
    print('🔄 Switched to Development: $_devBaseUrl');
  }

  /// Switch to production environment (Render Cloud Server)
  static void switchToProduction() {
    _useProduction = true;
    print('🔄 Switched to Production: $_prodBaseUrl');
  }

  /// Toggle between environments
  static void toggleEnvironment() {
    _useProduction = !_useProduction;
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
