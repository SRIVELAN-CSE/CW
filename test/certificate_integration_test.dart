import 'package:flutter_test/flutter_test.dart';
import 'package:civic_welfare/services/database_service.dart';
import 'package:civic_welfare/models/report.dart';
import 'package:civic_welfare/models/certificate.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Certificate Generation Integration Tests', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService.instance;
    });

    test('Certificate generation when report status changes to done', () async {
      // Create a test report
      final testReport = Report(
        id: 'test_report_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test Infrastructure Issue - Road Pothole',
        category: 'Infrastructure',
        department: 'Public Works',
        description: 'Large pothole causing vehicle damage on Main Street',
        location: 'Main Street near City Hall',
        reporterId: 'test_citizen_123',
        reporterName: 'John Doe',
        reporterEmail: 'john.doe@example.com',
        status: ReportStatus.submitted,
        priority: 'High',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: [],
      );

      print('📝 Creating test report: ${testReport.title}');
      
      // Save the original report
      await databaseService.saveReport(testReport);
      print('✅ Test report saved with status: ${testReport.status}');

      // Get certificates before resolution
      final certificatesBefore = await databaseService.getAllCertificates();
      final countBefore = certificatesBefore.length;
      print('📊 Certificates before resolution: $countBefore');

      // Update report to resolved status (this should trigger certificate generation)
      final resolvedReport = testReport.copyWith(
        status: ReportStatus.done,
        updatedAt: DateTime.now(),
      );

      print('🔄 Updating report status to: ${resolvedReport.status}');
      await databaseService.updateReport(resolvedReport);

      // Give some time for certificate generation to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Get certificates after resolution
      final certificatesAfter = await databaseService.getAllCertificates();
      final countAfter = certificatesAfter.length;
      print('📊 Certificates after resolution: $countAfter');

      // Verify certificate was generated
      expect(countAfter, equals(countBefore + 1), 
        reason: 'A new certificate should have been generated');

      if (certificatesAfter.isNotEmpty) {
        final newCertificate = certificatesAfter.last;
        print('🏆 Generated certificate details:');
        print('   - ID: ${newCertificate.id}');
        print('   - Report ID: ${newCertificate.reportId}');
        print('   - Title: ${newCertificate.reportTitle}');
        print('   - Category: ${newCertificate.reportCategory}');
        print('   - Points: ${newCertificate.pointsAwarded}');
        print('   - Citizen: ${newCertificate.citizenName}');
        
        // Verify certificate details
        expect(newCertificate.reportId, equals(testReport.id));
        expect(newCertificate.reportTitle, equals(testReport.title));
        expect(newCertificate.reportCategory, equals(testReport.category));
        expect(newCertificate.pointsAwarded, equals(20)); // Infrastructure = 20 points
        expect(newCertificate.status, equals('active'));
      }

      print('✅ Certificate generation test completed successfully!');
    });

    test('Verify certificate points calculation', () async {
      // Test different categories
      final categories = {
        'Infrastructure': 20,
        'Emergency': 20,
        'Utilities': 15,
        'Environment': 15,
        'Public Safety': 12,
        'Transportation': 12,
        'Other': 10,
      };

      for (final entry in categories.entries) {
        final points = Certificate.calculatePoints(entry.key);
        expect(points, equals(entry.value), 
          reason: '${entry.key} should award ${entry.value} points');
        print('✅ ${entry.key}: ${points} points');
      }
    });

    test('Verify certificate display functionality', () async {
      // This test checks if certificates can be retrieved and displayed
      final certificates = await databaseService.getAllCertificates();
      print('📊 Total certificates found: ${certificates.length}');
      
      for (final cert in certificates) {
        print('🏆 Certificate: ${cert.reportTitle} - ${cert.pointsAwarded} points');
      }

      // Test citizen gamification stats
      try {
        final stats = await databaseService.getCitizenGamificationStats();
        print('📈 Citizen Stats:');
        print('   - Name: ${stats.citizenName}');
        print('   - Total Points: ${stats.totalPoints}');
        print('   - Total Certificates: ${stats.totalCertificates}');
        print('   - Current Level: ${stats.calculateLevel()}');
      } catch (e) {
        print('⚠️ Could not retrieve citizen stats: $e');
      }
    });
  });
}