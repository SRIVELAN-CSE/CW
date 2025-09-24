import 'dart:convert';
import 'package:flutter/foundation.dart';

// Conditional import for web-specific functionality
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart';

class WebStorage {
  static const String _keyPrefix = 'civic_welfare_';

  // Save data to localStorage
  static bool setString(String key, String value) {
    if (!kIsWeb) return false;
    
    return WebStorageImpl.setString('$_keyPrefix$key', value);
  }

  // Get data from localStorage
  static String? getString(String key) {
    if (!kIsWeb) return null;
    
    return WebStorageImpl.getString('$_keyPrefix$key');
  }

  // Save JSON data
  static bool setJson(String key, Map<String, dynamic> data) {
    try {
      final jsonString = jsonEncode(data);
      return setString(key, jsonString);
    } catch (e) {
      print('Error encoding JSON for localStorage: $e');
      return false;
    }
  }

  // Get JSON data
  static Map<String, dynamic>? getJson(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JSON from localStorage: $e');
      return null;
    }
  }

  // Save list data
  static bool setList(String key, List<dynamic> data) {
    try {
      final jsonString = jsonEncode(data);
      return setString(key, jsonString);
    } catch (e) {
      print('Error encoding list for localStorage: $e');
      return false;
    }
  }

  // Get list data
  static List<dynamic>? getList(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('Error decoding list from localStorage: $e');
      return null;
    }
  }

  // Remove data
  static bool remove(String key) {
    if (!kIsWeb) return false;
    
    return WebStorageImpl.remove('$_keyPrefix$key');
  }

  // Clear all app data
  static bool clear() {
    if (!kIsWeb) return false;
    
    return WebStorageImpl.clear(_keyPrefix);
  }

  // Check if localStorage is available
  static bool isAvailable() {
    if (!kIsWeb) return false;
    
    return WebStorageImpl.isAvailable();
  }

  // Get storage info
  static Map<String, dynamic> getStorageInfo() {
    if (!kIsWeb) return {};
    
    return WebStorageImpl.getStorageInfo(_keyPrefix);
  }
}