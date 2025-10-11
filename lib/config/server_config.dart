enum ServerEnvironment {
  local,
  cloud;

  String get value {
    switch (this) {
      case ServerEnvironment.local:
        return 'local';
      case ServerEnvironment.cloud:
        return 'cloud';
    }
  }
}

class ServerConfigModel {
  final String name;
  final String baseURL;
  final String apiURL;
  final String websocketURL;
  final String description;
  final String icon;
  final String color;

  const ServerConfigModel({
    required this.name,
    required this.baseURL,
    required this.apiURL,
    required this.websocketURL,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class ServerConfig {
  static const Map<String, ServerConfigModel> _configs = {
    'local': ServerConfigModel(
      name: 'Local Development Server',
      baseURL: 'http://localhost:8000',
      apiURL: 'http://localhost:8000/api',
      websocketURL: 'ws://localhost:8000',
      description: 'Local development server for testing',
      icon: '🏠',
      color: '#2196F3',
    ),
    'cloud': ServerConfigModel(
      name: 'Cloud Production Server',
      baseURL: 'https://civic-welfare-sih.onrender.com', // Update with your actual Render URL
      apiURL: 'https://civic-welfare-sih.onrender.com/api',
      websocketURL: 'wss://civic-welfare-sih.onrender.com',
      description: 'Production server on Render cloud',
      icon: '☁️',
      color: '#4CAF50',
    ),
  };

  static ServerConfigModel getConfig([String environment = 'local']) {
    return _configs[environment] ?? _configs['local']!;
  }

  static bool isValidEnvironment(String environment) {
    return _configs.containsKey(environment);
  }

  static Map<String, ServerConfigModel> getAllConfigs() {
    return Map.unmodifiable(_configs);
  }

  static List<String> getAvailableEnvironments() {
    return _configs.keys.toList();
  }
}