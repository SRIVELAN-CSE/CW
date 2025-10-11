import 'package:shared_preferences/shared_preferences.dart';

/// Quick script to switch server environment back to local
void main() async {
  print('🔄 Switching server environment to local...');
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_server_environment', 'local');
  
  print('✅ Environment switched to LOCAL server');
  print('🏠 Server URL: http://localhost:8000/api');
  print('🔄 Restart your Flutter app to apply changes');
}