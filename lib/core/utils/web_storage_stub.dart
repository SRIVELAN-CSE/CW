// Stub implementation for non-web platforms
class WebStorageImpl {
  static bool setString(String key, String value) {
    // No-op for non-web platforms
    return false;
  }

  static String? getString(String key) {
    // No-op for non-web platforms
    return null;
  }

  static bool remove(String key) {
    // No-op for non-web platforms
    return false;
  }

  static bool clear(String keyPrefix) {
    // No-op for non-web platforms
    return false;
  }

  static bool isAvailable() {
    // Not available on non-web platforms
    return false;
  }

  static Map<String, dynamic> getStorageInfo(String keyPrefix) {
    // Not available on non-web platforms
    return {
      'available': false,
      'platform': 'non-web',
    };
  }
}