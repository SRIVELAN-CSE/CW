class AppConstants {
  // App Info
  static const String appName = 'CivicWelfare';
  static const String appVersion = '1.0.0';
  static const String teamName = 'CitiVoice';

  // User Types
  static const String userTypePublic = 'PUBLIC';
  static const String userTypeOfficer = 'OFFICER';
  static const String userTypeAdmin = 'ADMIN';

  // Issue Status
  static const String statusTodo = 'TODO';
  static const String statusInProgress = 'IN_PROGRESS';
  static const String statusCompleted = 'COMPLETED';
  static const String statusRejected = 'REJECTED';

  // Departments
  static const String deptGarbageCollection = 'GARBAGE_COLLECTION';
  static const String deptDrainage = 'DRAINAGE';
  static const String deptRoadMaintenance = 'ROAD_MAINTENANCE';
  static const String deptStreetLights = 'STREET_LIGHTS';
  static const String deptWaterSupply = 'WATER_SUPPLY';
  static const String deptOthers = 'OTHERS';

  // Locations
  static const String locationKulithalai = 'KULITHALAI';
  static const String locationKarur = 'KARUR';
  static const String locationOthers = 'OTHERS';

  // Priority Levels
  static const String priorityLow = 'LOW';
  static const String priorityMedium = 'MEDIUM';
  static const String priorityHigh = 'HIGH';
  static const String priorityCritical = 'CRITICAL';

  // API Endpoints (Mock - replace with actual backend)
  static const String baseUrl = 'https://api.civicwelfare.com';
  static const String authEndpoint = '/auth';
  static const String issuesEndpoint = '/issues';
  static const String usersEndpoint = '/users';
  static const String notificationsEndpoint = '/notifications';

  // Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyUserType = 'user_type';
  static const String keyUserId = 'user_id';
  static const String keyUserLocation = 'user_location';
  static const String keyIsFirstLaunch = 'is_first_launch';

  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedVideoTypes = ['mp4', 'avi', 'mov'];

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}