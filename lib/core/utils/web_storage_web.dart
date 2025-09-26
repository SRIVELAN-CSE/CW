// Web-specific implementation
import 'dart:html' as html;

class WebStorageImpl {
  static bool setString(String key, String value) {
    try {
      html.window.localStorage[key] = value;
      return true;
    } catch (e) {
      print('Error saving to localStorage: $e');
      return false;
    }
  }

  static String? getString(String key) {
    try {
      return html.window.localStorage[key];
    } catch (e) {
      print('Error reading from localStorage: $e');
      return null;
    }
  }

  static bool remove(String key) {
    try {
      html.window.localStorage.remove(key);
      return true;
    } catch (e) {
      print('Error removing from localStorage: $e');
      return false;
    }
  }

  static bool clear(String keyPrefix) {
    try {
      // Get all keys and remove only our app's keys
      final keys = html.window.localStorage.keys.toList();
      for (final key in keys) {
        if (key.startsWith(keyPrefix)) {
          html.window.localStorage.remove(key);
        }
      }
      return true;
    } catch (e) {
      print('Error clearing localStorage: $e');
      return false;
    }
  }

  static bool isAvailable() {
    try {
      const testKey = 'test_storage';
      html.window.localStorage[testKey] = 'test';
      html.window.localStorage.remove(testKey);
      return true;
    } catch (e) {
      print('localStorage is not available: $e');
      return false;
    }
  }

  static Map<String, dynamic> getStorageInfo(String keyPrefix) {
    try {
      final keys = html.window.localStorage.keys.where((key) => key.startsWith(keyPrefix)).toList();
      int totalSize = 0;
      
      for (final key in keys) {
        final value = html.window.localStorage[key] ?? '';
        totalSize += key.length + value.length;
      }
      
      return {
        'totalKeys': keys.length,
        'totalSize': totalSize,
        'available': true,
        'keys': keys.map((key) => key.replaceFirst(keyPrefix, '')).toList(),
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }
}