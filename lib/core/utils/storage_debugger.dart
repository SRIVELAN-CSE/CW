import 'package:flutter/foundation.dart';

// Conditional import for web-specific functionality
import 'storage_debugger_stub.dart'
    if (dart.library.html) 'storage_debugger_web.dart';

class StorageDebugger {
  static void testLocalStorage() {
    if (!kIsWeb) {
      print('Not running on web platform - storage debugging not available');
      return;
    }
    
    StorageDebuggerImpl.testLocalStorage();
  }
  
  static void clearTestData() {
    if (!kIsWeb) return;
    
    StorageDebuggerImpl.clearTestData();
  }
}