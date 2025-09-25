// Web-specific implementation
import 'dart:html' as html;
import 'dart:convert';

class WebStorageImpl {
  static const int maxStorageSize = 4 * 1024 * 1024; // 4MB safe limit
  
  static bool setString(String key, String value) {
    try {
      // Check if storage is available and has space
      if (!_checkStorageSpace(value.length)) {
        print('⚠️ Storage quota check failed, attempting cleanup...');
        _cleanupOldData();
      }
      
      html.window.localStorage[key] = value;
      return true;
    } catch (e) {
      print('Error saving to localStorage: $e');
      
      // Handle quota exceeded error specifically
      if (e.toString().contains('QuotaExceededError') || 
          e.toString().contains('exceeded the quota')) {
        print('🚨 localStorage quota exceeded! Attempting emergency cleanup...');
        
        // Emergency cleanup - keep only essential data
        _emergencyCleanup(key, value);
        
        // Try saving again
        try {
          html.window.localStorage[key] = value;
          return true;
        } catch (secondError) {
          print('❌ Failed to save even after cleanup: $secondError');
          return false;
        }
      }
      
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
      
      // Calculate estimated quota usage
      final quotaUsage = (totalSize / maxStorageSize * 100).round();
      
      return {
        'totalKeys': keys.length,
        'totalSize': totalSize,
        'quotaUsage': quotaUsage,
        'available': true,
        'keys': keys.map((key) => key.replaceFirst(keyPrefix, '')).toList(),
        'warning': quotaUsage > 80 ? 'Storage usage high ($quotaUsage%)' : null,
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }

  // Private helper methods
  static bool _checkStorageSpace(int dataSize) {
    try {
      final currentSize = _getCurrentStorageSize();
      final wouldExceed = (currentSize + dataSize) > maxStorageSize;
      
      if (wouldExceed) {
        print('⚠️ Storage would exceed limit: ${currentSize + dataSize} bytes');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking storage space: $e');
      return false; // Be safe and assume no space
    }
  }

  static int _getCurrentStorageSize() {
    try {
      int totalSize = 0;
      final keys = html.window.localStorage.keys.toList();
      
      for (final key in keys) {
        final value = html.window.localStorage[key] ?? '';
        totalSize += key.length + value.length;
      }
      
      return totalSize;
    } catch (e) {
      print('Error calculating storage size: $e');
      return maxStorageSize; // Assume full to be safe
    }
  }

  static void _cleanupOldData() {
    try {
      print('🧹 Performing storage cleanup...');
      
      final keys = html.window.localStorage.keys.toList();
      final appKeys = keys.where((key) => key.startsWith('civic_welfare_')).toList();
      
      // Remove non-essential data first
      final nonEssentialKeys = appKeys.where((key) => 
        !key.contains('user') && 
        !key.contains('session') && 
        !key.contains('settings')
      ).toList();
      
      for (final key in nonEssentialKeys) {
        html.window.localStorage.remove(key);
      }
      
      print('🧹 Cleaned up ${nonEssentialKeys.length} non-essential items');
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  static void _emergencyCleanup(String keyToSave, String valueToSave) {
    try {
      print('🚨 Emergency cleanup initiated...');
      
      final keys = html.window.localStorage.keys.toList();
      final appKeys = keys.where((key) => key.startsWith('civic_welfare_')).toList();
      
      // Keep only the most essential data
      final essentialKeys = appKeys.where((key) => 
        key.contains('user') || 
        key.contains('session') ||
        key == keyToSave
      ).toList();
      
      // Remove everything except essential keys
      for (final key in appKeys) {
        if (!essentialKeys.contains(key)) {
          html.window.localStorage.remove(key);
        }
      }
      
      // If still not enough space, compress the data to save
      if (_getCurrentStorageSize() + valueToSave.length > maxStorageSize) {
        // Try to compress by limiting array size
        _compressDataForStorage(keyToSave, valueToSave);
      }
      
      print('🚨 Emergency cleanup completed');
    } catch (e) {
      print('Error during emergency cleanup: $e');
    }
  }

  static void _compressDataForStorage(String key, String value) {
    try {
      // If it's JSON array data (like reports), keep only recent items
      if (key.contains('reports') && value.startsWith('[')) {
        final List<dynamic> data = jsonDecode(value);
        
        // Keep only the most recent 10 items
        final compressedData = data.take(10).toList();
        final compressedJson = jsonEncode(compressedData);
        
        html.window.localStorage[key] = compressedJson;
        print('📦 Compressed ${data.length} items to ${compressedData.length} items');
      }
    } catch (e) {
      print('Error compressing data: $e');
    }
  }
}