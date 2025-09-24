// Web-specific implementation
import 'dart:convert';
import 'dart:html' as html;

class StorageDebuggerImpl {
  static void testLocalStorage() {
    try {
      // Test basic localStorage
      const testKey = 'civic_welfare_test';
      const testValue = 'Hello localStorage!';
      
      // Save test data
      html.window.localStorage[testKey] = testValue;
      print('✓ Successfully saved test data to localStorage');
      
      // Read test data
      final retrievedValue = html.window.localStorage[testKey];
      print('✓ Retrieved value: $retrievedValue');
      
      // Test JSON storage
      final testJson = {'message': 'Test JSON', 'timestamp': DateTime.now().toIso8601String()};
      html.window.localStorage['civic_welfare_json_test'] = jsonEncode(testJson);
      print('✓ Successfully saved JSON to localStorage');
      
      // Read JSON data
      final retrievedJson = html.window.localStorage['civic_welfare_json_test'];
      if (retrievedJson != null) {
        final decodedJson = jsonDecode(retrievedJson);
        print('✓ Retrieved JSON: $decodedJson');
      }
      
      // List all localStorage keys
      print('📋 All localStorage keys:');
      for (int i = 0; i < html.window.localStorage.length; i++) {
        final key = html.window.localStorage.keys.elementAt(i);
        print('  - $key');
      }
      
    } catch (e) {
      print('❌ Error testing localStorage: $e');
    }
  }
  
  static void clearTestData() {
    try {
      html.window.localStorage.remove('civic_welfare_test');
      html.window.localStorage.remove('civic_welfare_json_test');
      print('✓ Cleared test data');
    } catch (e) {
      print('❌ Error clearing test data: $e');
    }
  }
}