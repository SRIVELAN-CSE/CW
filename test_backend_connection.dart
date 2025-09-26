/// Backend Connection Test
/// Test the complete backend-frontend synchronization system
import 'package:flutter/foundation.dart';
import 'lib/core/config/environment_switcher.dart';
import 'lib/services/backend_api_service.dart';
import 'lib/services/database_service.dart';
import 'lib/models/report.dart';

void main() async {
  print('🧪 TESTING COMPLETE BACKEND-FRONTEND SYNCHRONIZATION SYSTEM');
  print('=' * 70);
  
  await testEnvironmentSwitcher();
  await testBackendConnection();
  await testAuthenticatedApis();
  await testReportSynchronization();
  
  print('=' * 70);
  print('🎉 TESTING COMPLETE!');
}

Future<void> testEnvironmentSwitcher() async {
  print('\n📱 1. TESTING ENVIRONMENT SWITCHER');
  print('-' * 40);
  
  print('🔄 Testing environment switching...');
  print('Current environment: ${EnvironmentSwitcher.currentEnvironment}');
  print('Current base URL: ${EnvironmentSwitcher.baseUrl}');
  
  // Test switching to development
  EnvironmentSwitcher.switchToDevelopment();
  print('✅ Switched to Development');
  print('   Environment: ${EnvironmentSwitcher.currentEnvironment}');
  print('   Base URL: ${EnvironmentSwitcher.baseUrl}');
  
  // Test switching to production
  EnvironmentSwitcher.switchToProduction();
  print('✅ Switched to Production');
  print('   Environment: ${EnvironmentSwitcher.currentEnvironment}');
  print('   Base URL: ${EnvironmentSwitcher.baseUrl}');
  
  // Test toggle functionality
  EnvironmentSwitcher.toggleEnvironment();
  print('✅ Toggled environment');
  print('   Environment: ${EnvironmentSwitcher.currentEnvironment}');
  print('   Base URL: ${EnvironmentSwitcher.baseUrl}');
}

Future<void> testBackendConnection() async {
  print('\n🌐 2. TESTING BACKEND CONNECTION');
  print('-' * 40);
  
  // Test both environments
  List<String> environments = ['Development', 'Production'];
  
  for (String env in environments) {
    print('\n🔍 Testing $env environment...');
    
    if (env == 'Development') {
      EnvironmentSwitcher.switchToDevelopment();
    } else {
      EnvironmentSwitcher.switchToProduction();
    }
    
    try {
      print('   URL: ${EnvironmentSwitcher.baseUrl}');
      bool isConnected = await BackendApiService.testConnection();
      if (isConnected) {
        print('   ✅ Connection successful!');
      } else {
        print('   ❌ Connection failed');
      }
    } catch (e) {
      print('   ❌ Connection error: $e');
    }
  }
}

Future<void> testAuthenticatedApis() async {
  print('\n🔐 3. TESTING AUTHENTICATED API METHODS');
  print('-' * 40);
  
  try {
    // Test user profile API
    print('🔍 Testing getUserProfile...');
    final profile = await BackendApiService.getUserProfile();
    if (profile != null) {
      print('   ✅ getUserProfile working');
      print('   📄 Profile data: ${profile.toString()}');
    } else {
      print('   ⚠️ getUserProfile returned null (expected without authentication)');
    }
  } catch (e) {
    print('   ⚠️ getUserProfile error (expected): $e');
  }
  
  try {
    // Test create feedback API
    print('🔍 Testing createFeedback...');
    final feedbackResult = await BackendApiService.createFeedback(
      reportId: 'test-report-id',
      feedback: 'Test feedback from automated test',
      officerId: 'test-officer-id',
    );
    if (feedbackResult != null) {
      print('   ✅ createFeedback working');
      print('   📄 Result: ${feedbackResult.toString()}');
    } else {
      print('   ⚠️ createFeedback returned null (expected without authentication)');
    }
  } catch (e) {
    print('   ⚠️ createFeedback error (expected): $e');
  }
}

Future<void> testReportSynchronization() async {
  print('\n📝 4. TESTING REPORT SYNCHRONIZATION');
  print('-' * 40);
  
  // Create a test report
  final testReport = Report(
    id: 'test-${DateTime.now().millisecondsSinceEpoch}',
    title: 'Automated Test Report',
    description: 'This is a test report created by the automated testing system',
    category: 'test',
    location: 'Test Location',
    reporterName: 'Test User',
    reporterContact: 'test@example.com',
    urgency: 'medium',
    photoUrl: null,
    status: 'pending',
    submittedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  print('🔍 Testing report synchronization...');
  print('   Report ID: ${testReport.id}');
  print('   Report Title: ${testReport.title}');
  
  try {
    // Test the enhanced saveReport method
    await DatabaseService.instance.saveReport(testReport);
    print('   ✅ Report saved with synchronization system');
    
    // Test getting all reports
    final reports = await DatabaseService.instance.getAllReports();
    print('   📊 Total reports in system: ${reports.length}');
    
    // Find our test report
    final savedReport = reports.where((r) => r.id == testReport.id).toList();
    if (savedReport.isNotEmpty) {
      print('   ✅ Test report found in local storage');
    } else {
      print('   ⚠️ Test report not found in local storage');
    }
    
  } catch (e) {
    print('   ❌ Report synchronization error: $e');
  }
}
