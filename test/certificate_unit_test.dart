import 'package:flutter_test/flutter_test.dart';
import 'package:civic_welfare/models/certificate.dart';

void main() {
  group('Certificate Model Tests', () {
    test('Point calculation by category', () {
      // Test high-priority categories (20 points)
      expect(Certificate.calculatePoints('Infrastructure'), equals(20));
      expect(Certificate.calculatePoints('Emergency'), equals(20));
      expect(Certificate.calculatePoints('infrastructure'), equals(20)); // case insensitive
      expect(Certificate.calculatePoints('EMERGENCY'), equals(20));

      // Test medium-priority categories (15 points)
      expect(Certificate.calculatePoints('Utilities'), equals(15));
      expect(Certificate.calculatePoints('Environment'), equals(15));
      expect(Certificate.calculatePoints('utilities'), equals(15));
      expect(Certificate.calculatePoints('ENVIRONMENT'), equals(15));

      // Test lower-priority categories (12 points)
      expect(Certificate.calculatePoints('Public Safety'), equals(12));
      expect(Certificate.calculatePoints('Transportation'), equals(12));
      expect(Certificate.calculatePoints('public safety'), equals(12));
      expect(Certificate.calculatePoints('TRANSPORTATION'), equals(12));

      // Test default category (10 points)
      expect(Certificate.calculatePoints('Other'), equals(10));
      expect(Certificate.calculatePoints('Unknown Category'), equals(10));
      expect(Certificate.calculatePoints(''), equals(10));
    });

    test('Certificate creation with proper points calculation', () {
      final infrastructureCert = Certificate.createCivicEngagementCertificate(
        reportId: 'report_123',
        reportTitle: 'Fix Road Pothole',
        reportCategory: 'Infrastructure',
        reportDepartment: 'Public Works',
        citizenId: 'citizen_456',
        citizenName: 'John Doe',
        citizenEmail: 'john@example.com',
      );

      expect(infrastructureCert.reportId, equals('report_123'));
      expect(infrastructureCert.reportTitle, equals('Fix Road Pothole'));
      expect(infrastructureCert.reportCategory, equals('Infrastructure'));
      expect(infrastructureCert.pointsAwarded, equals(20)); // Infrastructure = 20 points
      expect(infrastructureCert.citizenName, equals('John Doe'));
      expect(infrastructureCert.status, equals('active'));
      expect(infrastructureCert.certificateType, equals('Civic Engagement Certificate'));
      expect(infrastructureCert.description.contains('Fix Road Pothole'), isTrue);
      expect(infrastructureCert.description.contains('Infrastructure'), isTrue);
    });

    test('CitizenGamificationStats level calculation', () {
      // Test Bronze level (0-49 points)
      var stats = CitizenGamificationStats(
        citizenId: 'test_citizen',
        citizenName: 'Test User',
        totalPoints: 25,
        totalCertificates: 2,
      );
      expect(stats.calculateLevel(), equals('🥉 Bronze Citizen'));

      // Test Silver level (50-99 points)
      stats = CitizenGamificationStats(
        citizenId: 'test_citizen',
        citizenName: 'Test User',
        totalPoints: 75,
        totalCertificates: 3,
      );
      expect(stats.calculateLevel(), equals('🥈 Silver Citizen'));

      // Test Gold level (100-199 points)
      stats = CitizenGamificationStats(
        citizenId: 'test_citizen',
        citizenName: 'Test User',
        totalPoints: 150,
        totalCertificates: 5,
      );
      expect(stats.calculateLevel(), equals('🥇 Gold Citizen'));

      // Test Platinum level (200+ points)
      stats = CitizenGamificationStats(
        citizenId: 'test_citizen',
        citizenName: 'Test User',
        totalPoints: 250,
        totalCertificates: 8,
      );
      expect(stats.calculateLevel(), equals('🏆 Platinum Citizen'));
    });

    test('CitizenGamificationStats level progress calculation', () {
      // Test Bronze level progress
      var stats = CitizenGamificationStats(
        citizenId: 'test_citizen',
        citizenName: 'Test User',
        totalPoints: 25,
        totalCertificates: 2,
      );
      var progress = stats.getLevelProgress();
      expect(progress['nextLevel'], equals('🥈 Silver Citizen'));
      expect(progress['pointsNeeded'], equals(25)); // 50 - 25 = 25

      // Test Silver level progress
      stats = CitizenGamificationStats(
        citizenId: 'test_citizen',
        citizenName: 'Test User',
        totalPoints: 75,
        totalCertificates: 3,
      );
      progress = stats.getLevelProgress();
      expect(progress['nextLevel'], equals('🥇 Gold Citizen'));
      expect(progress['pointsNeeded'], equals(25)); // 100 - 75 = 25

      // Test Gold level progress
      stats = CitizenGamificationStats(
        citizenId: 'test_citizen',
        citizenName: 'Test User',
        totalPoints: 150,
        totalCertificates: 5,
      );
      progress = stats.getLevelProgress();
      expect(progress['nextLevel'], equals('🏆 Platinum Citizen'));
      expect(progress['pointsNeeded'], equals(50)); // 200 - 150 = 50

      // Test Platinum level (max level)
      stats = CitizenGamificationStats(
        citizenId: 'test_citizen',
        citizenName: 'Test User',
        totalPoints: 250,
        totalCertificates: 8,
      );
      progress = stats.getLevelProgress();
      expect(progress['nextLevel'], equals('Max Level Reached'));
      expect(progress['pointsNeeded'], equals(0));
    });

    test('Certificate JSON serialization and deserialization', () {
      final originalCert = Certificate.createCivicEngagementCertificate(
        reportId: 'report_456',
        reportTitle: 'Water Leak Issue',
        reportCategory: 'Utilities',
        reportDepartment: 'Water Department',
        citizenId: 'citizen_789',
        citizenName: 'Jane Smith',
        citizenEmail: 'jane@example.com',
      );

      // Convert to JSON
      final json = originalCert.toJson();
      expect(json['reportId'], equals('report_456'));
      expect(json['pointsAwarded'], equals(15)); // Utilities = 15 points

      // Convert from JSON
      final deserializedCert = Certificate.fromJson(json);
      expect(deserializedCert.reportId, equals(originalCert.reportId));
      expect(deserializedCert.reportTitle, equals(originalCert.reportTitle));
      expect(deserializedCert.pointsAwarded, equals(originalCert.pointsAwarded));
      expect(deserializedCert.citizenName, equals(originalCert.citizenName));
      expect(deserializedCert.status, equals(originalCert.status));
    });

    test('CitizenGamificationStats JSON serialization and deserialization', () {
      final originalStats = CitizenGamificationStats(
        citizenId: 'citizen_123',
        citizenName: 'Test Citizen',
        totalPoints: 125,
        totalCertificates: 5,
        categories: ['Infrastructure', 'Utilities', 'Environment'],
      );

      // Convert to JSON
      final json = originalStats.toJson();
      expect(json['citizenId'], equals('citizen_123'));
      expect(json['totalPoints'], equals(125));
      expect(json['totalCertificates'], equals(5));
      expect(json['categories'], equals(['Infrastructure', 'Utilities', 'Environment']));

      // Convert from JSON
      final deserializedStats = CitizenGamificationStats.fromJson(json);
      expect(deserializedStats.citizenId, equals(originalStats.citizenId));
      expect(deserializedStats.totalPoints, equals(originalStats.totalPoints));
      expect(deserializedStats.calculateLevel(), equals('🥇 Gold Citizen')); // 125 points = Gold
      expect(deserializedStats.categories, equals(['Infrastructure', 'Utilities', 'Environment']));
    });
  });
}