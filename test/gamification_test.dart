import 'package:flutter_test/flutter_test.dart';
import 'package:civic_welfare/services/database_service.dart';
import 'package:civic_welfare/models/report.dart';
import 'package:civic_welfare/models/certificate.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Gamification System Tests', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService.instance;
    });

    test('Certificate generation when report is resolved', () async {
      // Create a test report
      final testReport = Report(
        id: 'test_report_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test Infrastructure Issue',
        category: 'Infrastructure',
        department: 'Public Works',
        description: 'Test description for certificate generation',
        location: 'Test Location',
        reporterId: 'test_citizen_123',
        reporterName: 'Test Citizen',
        reporterEmail: 'test@example.com',
        status: ReportStatus.submitted,
        priority: 'High',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: [],
      );

      // Save the report
      await databaseService.saveReport(testReport);

      // Update report to resolved status (this should trigger certificate generation)
      final resolvedReport = testReport.copyWith(
        status: ReportStatus.done,
      );

      await databaseService.updateReport(resolvedReport);

      // Check if certificate was generated
      final certificates = await databaseService.getAllCertificates();
      
      expect(certificates, isNotEmpty);
      
      final certificateForReport = certificates.firstWhere(
        (cert) => cert.reportId == testReport.id,
        orElse: () => throw Exception('Certificate not found for resolved report'),
      );

      expect(certificateForReport.reportId, equals(testReport.id));
      expect(certificateForReport.reportTitle, equals(testReport.title));
      expect(certificateForReport.reportCategory, equals(testReport.category));
      expect(certificateForReport.citizenEmail, equals(testReport.reporterEmail));
      expect(certificateForReport.pointsAwarded, equals(20)); // Infrastructure gives 20 points
    });

    test('Citizen gamification stats calculation', () async {
      // Get current stats
      final stats = await databaseService.getCitizenGamificationStats();
      
      expect(stats.citizenId, isNotEmpty);
      expect(stats.citizenName, isNotEmpty);
      expect(stats.totalCertificates, greaterThanOrEqualTo(0));
      expect(stats.totalPoints, greaterThanOrEqualTo(0));
      expect(stats.currentLevel, isNotEmpty);
    });

    test('Certificate analytics for admin', () async {
      final analytics = await databaseService.getCertificateAnalytics();
      
      expect(analytics, isA<Map<String, dynamic>>());
      expect(analytics.containsKey('totalCertificates'), isTrue);
      expect(analytics.containsKey('totalPoints'), isTrue);
      expect(analytics.containsKey('uniqueCitizens'), isTrue);
      expect(analytics.containsKey('categoryBreakdown'), isTrue);
      expect(analytics.containsKey('levelDistribution'), isTrue);
      expect(analytics.containsKey('recentCertificates'), isTrue);
    });

    test('Point calculation by category', () {
      // Test point calculation for different categories
      expect(Certificate.calculatePoints('Infrastructure'), equals(20));
      expect(Certificate.calculatePoints('Emergency'), equals(20));
      expect(Certificate.calculatePoints('Utilities'), equals(15));
      expect(Certificate.calculatePoints('Environment'), equals(15));
      expect(Certificate.calculatePoints('Public Safety'), equals(12));
      expect(Certificate.calculatePoints('Transportation'), equals(12));
      expect(Certificate.calculatePoints('Other'), equals(10));
    });

    test('Citizen level progression', () {
      // Test level calculation based on points
      final stats1 = CitizenGamificationStats(
        citizenId: 'test1',
        citizenName: 'Test User 1', 
        totalPoints: 25,
      );
      expect(stats1.calculateLevel(), equals('🥉 Bronze Citizen'));

      final stats2 = CitizenGamificationStats(
        citizenId: 'test2',
        citizenName: 'Test User 2',
        totalPoints: 75,
      );
      expect(stats2.calculateLevel(), equals('🥈 Silver Citizen'));

      final stats3 = CitizenGamificationStats(
        citizenId: 'test3',
        citizenName: 'Test User 3',
        totalPoints: 150,
      );
      expect(stats3.calculateLevel(), equals('🥇 Gold Citizen'));

      final stats4 = CitizenGamificationStats(
        citizenId: 'test4',
        citizenName: 'Test User 4',
        totalPoints: 250,
      );
      expect(stats4.calculateLevel(), equals('🏆 Platinum Citizen'));
    });

    test('Certificate model serialization', () {
      final certificate = Certificate(
        id: 'test_cert_123',
        reportId: 'test_report_456',
        reportTitle: 'Test Report',
        reportCategory: 'Infrastructure',
        reportDepartment: 'Public Works',
        citizenId: 'citizen_789',
        citizenName: 'Test Citizen',
        citizenEmail: 'test@example.com',
        issuedDate: DateTime.now(),
        pointsAwarded: 20,
      );

      // Test JSON serialization
      final json = certificate.toJson();
      expect(json['id'], equals('test_cert_123'));
      expect(json['reportId'], equals('test_report_456'));
      expect(json['pointsAwarded'], equals(20));

      // Test JSON deserialization
      final deserializedCert = Certificate.fromJson(json);
      expect(deserializedCert.id, equals(certificate.id));
      expect(deserializedCert.reportId, equals(certificate.reportId));
      expect(deserializedCert.pointsAwarded, equals(certificate.pointsAwarded));
    });
  });
}