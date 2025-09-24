class ApiConfig {
  // Environment modes
  static const String development = 'development';
  static const String production = 'production';
  
  // Current environment - Change this to switch between servers
  static const String currentEnvironment = development;
  
  // Server configurations
  static const Map<String, String> _baseUrls = {
    development: 'http://localhost:3000/api',
    production: 'https://civic-welfare-backend.onrender.com/api',
  };
  
  static const Map<String, String> _socketUrls = {
    development: 'http://localhost:3000',
    production: 'https://civic-welfare-backend.onrender.com',
  };
  
  // Get current base URL
  static String get baseUrl {
    return _baseUrls[currentEnvironment] ?? _baseUrls[development]!;
  }
  
  // Get current socket URL
  static String get socketUrl {
    return _socketUrls[currentEnvironment] ?? _socketUrls[development]!;
  }
  
  // Get current environment info
  static String get environmentName {
    return currentEnvironment;
  }
  
  // Check if running in production
  static bool get isProduction {
    return currentEnvironment == production;
  }
  
  // Check if running in development
  static bool get isDevelopment {
    return currentEnvironment == development;
  }
  
  // API timeout settings
  static Duration get apiTimeout {
    return isProduction 
        ? const Duration(seconds: 15)  // Longer timeout for cloud server
        : const Duration(seconds: 10); // Shorter timeout for localhost
  }
  
  // Debug info
  static void printConfig() {
    print('🔧 API Configuration:');
    print('   Environment: $environmentName');
    print('   Base URL: $baseUrl');
    print('   Socket URL: $socketUrl');
    print('   Timeout: ${apiTimeout.inSeconds}s');
    print('   Production: $isProduction');
  }
}