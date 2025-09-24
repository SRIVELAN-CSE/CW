import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D8F);
  static const Color primaryLight = Color(0xFF4A9BAE);
  static const Color primaryDark = Color(0xFF1B5A68);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF34A853);
  static const Color secondaryLight = Color(0xFF5CBB74);
  static const Color secondaryDark = Color(0xFF2D8A47);
  
  // Accent Colors
  static const Color accent = Color(0xFFFF9800);
  static const Color accentLight = Color(0xFFFFB74D);
  static const Color accentDark = Color(0xFFF57C00);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Issue Status Colors
  static const Color statusTodo = Color(0xFF9E9E9E);
  static const Color statusInProgress = Color(0xFF2196F3);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusRejected = Color(0xFFF44336);
  
  // Priority Colors
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityHigh = Color(0xFFFF5722);
  static const Color priorityCritical = Color(0xFFF44336);
  
  // Department Colors
  static const Color deptGarbage = Color(0xFF8BC34A);
  static const Color deptDrainage = Color(0xFF03A9F4);
  static const Color deptRoads = Color(0xFF607D8B);
  static const Color deptStreetLights = Color(0xFFFFEB3B);
  static const Color deptWater = Color(0xFF00BCD4);
  static const Color deptOthers = Color(0xFF9C27B0);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderDark = Color(0xFFBDBDBD);
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x33000000);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [primary, primaryLight];
  static const List<Color> secondaryGradient = [secondary, secondaryLight];
  static const List<Color> accentGradient = [accent, accentLight];
  
  // User Type Colors
  static const Color publicUser = Color(0xFF2196F3);
  static const Color officerUser = Color(0xFF4CAF50);
  static const Color adminUser = Color(0xFF9C27B0);
}