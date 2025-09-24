class Certificate {
  final String id;
  final String reportId;
  final String reportTitle;
  final String reportCategory;
  final String reportDepartment;
  final String citizenId;
  final String citizenName;
  final String citizenEmail;
  final DateTime issuedDate;
  final String certificateType;
  final String governmentSeal;
  final String description;
  final int pointsAwarded;
  final String status; // active, revoked

  Certificate({
    required this.id,
    required this.reportId,
    required this.reportTitle,
    required this.reportCategory,
    required this.reportDepartment,
    required this.citizenId,
    required this.citizenName,
    required this.citizenEmail,
    required this.issuedDate,
    this.certificateType = 'Civic Engagement Certificate',
    this.governmentSeal = 'Government of [City Name]',
    this.description = 'Awarded for actively contributing to community improvement',
    this.pointsAwarded = 10,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'reportTitle': reportTitle,
      'reportCategory': reportCategory,
      'reportDepartment': reportDepartment,
      'citizenId': citizenId,
      'citizenName': citizenName,
      'citizenEmail': citizenEmail,
      'issuedDate': issuedDate.toIso8601String(),
      'certificateType': certificateType,
      'governmentSeal': governmentSeal,
      'description': description,
      'pointsAwarded': pointsAwarded,
      'status': status,
    };
  }

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? '',
      reportId: json['reportId'] ?? '',
      reportTitle: json['reportTitle'] ?? '',
      reportCategory: json['reportCategory'] ?? '',
      reportDepartment: json['reportDepartment'] ?? '',
      citizenId: json['citizenId'] ?? '',
      citizenName: json['citizenName'] ?? '',
      citizenEmail: json['citizenEmail'] ?? '',
      issuedDate: DateTime.tryParse(json['issuedDate'] ?? '') ?? DateTime.now(),
      certificateType: json['certificateType'] ?? 'Civic Engagement Certificate',
      governmentSeal: json['governmentSeal'] ?? 'Government of [City Name]',
      description: json['description'] ?? 'Awarded for actively contributing to community improvement',
      pointsAwarded: json['pointsAwarded'] ?? 10,
      status: json['status'] ?? 'active',
    );
  }

  Certificate copyWith({
    String? id,
    String? reportId,
    String? reportTitle,
    String? reportCategory,
    String? reportDepartment,
    String? citizenId,
    String? citizenName,
    String? citizenEmail,
    DateTime? issuedDate,
    String? certificateType,
    String? governmentSeal,
    String? description,
    int? pointsAwarded,
    String? status,
  }) {
    return Certificate(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      reportTitle: reportTitle ?? this.reportTitle,
      reportCategory: reportCategory ?? this.reportCategory,
      reportDepartment: reportDepartment ?? this.reportDepartment,
      citizenId: citizenId ?? this.citizenId,
      citizenName: citizenName ?? this.citizenName,
      citizenEmail: citizenEmail ?? this.citizenEmail,
      issuedDate: issuedDate ?? this.issuedDate,
      certificateType: certificateType ?? this.certificateType,
      governmentSeal: governmentSeal ?? this.governmentSeal,
      description: description ?? this.description,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      status: status ?? this.status,
    );
  }

  // Helper methods for certificate display
  String get formattedIssueDate {
    return '${issuedDate.day}/${issuedDate.month}/${issuedDate.year}';
  }

  String get certificateNumber {
    return 'CERT-${id.toUpperCase()}';
  }

  String get shortDescription {
    return description.length > 50 
        ? '${description.substring(0, 50)}...'
        : description;
  }

  bool get isActive => status == 'active';
  bool get isRevoked => status == 'revoked';

  // Static methods for certificate types
  static Certificate createCivicEngagementCertificate({
    required String reportId,
    required String reportTitle,
    required String reportCategory,
    required String reportDepartment,
    required String citizenId,
    required String citizenName,
    required String citizenEmail,
  }) {
    return Certificate(
      id: 'CERT_${DateTime.now().millisecondsSinceEpoch}',
      reportId: reportId,
      reportTitle: reportTitle,
      reportCategory: reportCategory,
      reportDepartment: reportDepartment,
      citizenId: citizenId,
      citizenName: citizenName,
      citizenEmail: citizenEmail,
      issuedDate: DateTime.now(),
      certificateType: 'Civic Engagement Certificate',
      description: 'Awarded for successfully reporting and helping resolve "$reportTitle" in the $reportCategory category',
      pointsAwarded: calculatePoints(reportCategory),
    );
  }

  static int calculatePoints(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
      case 'emergency':
        return 20;
      case 'utilities':
      case 'environment':
        return 15;
      case 'public safety':
      case 'transportation':
        return 12;
      default:
        return 10;
    }
  }
}

// Model for tracking citizen gamification stats
class CitizenGamificationStats {
  final String citizenId;
  final String citizenName;
  final int totalCertificates;
  final int totalPoints;
  final int totalReportsResolved;
  final List<String> categories;
  final String currentLevel;
  final DateTime lastActivity;

  CitizenGamificationStats({
    required this.citizenId,
    required this.citizenName,
    this.totalCertificates = 0,
    this.totalPoints = 0,
    this.totalReportsResolved = 0,
    this.categories = const [],
    this.currentLevel = 'Bronze Citizen',
    DateTime? lastActivity,
  }) : lastActivity = lastActivity ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'citizenId': citizenId,
      'citizenName': citizenName,
      'totalCertificates': totalCertificates,
      'totalPoints': totalPoints,
      'totalReportsResolved': totalReportsResolved,
      'categories': categories,
      'currentLevel': currentLevel,
      'lastActivity': lastActivity.toIso8601String(),
    };
  }

  factory CitizenGamificationStats.fromJson(Map<String, dynamic> json) {
    return CitizenGamificationStats(
      citizenId: json['citizenId'] ?? '',
      citizenName: json['citizenName'] ?? '',
      totalCertificates: json['totalCertificates'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      totalReportsResolved: json['totalReportsResolved'] ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
      currentLevel: json['currentLevel'] ?? 'Bronze Citizen',
      lastActivity: DateTime.tryParse(json['lastActivity'] ?? '') ?? DateTime.now(),
    );
  }

  // Calculate current level based on points
  String calculateLevel() {
    if (totalPoints >= 200) return '🏆 Platinum Citizen';
    if (totalPoints >= 100) return '🥇 Gold Citizen';
    if (totalPoints >= 50) return '🥈 Silver Citizen';
    return '🥉 Bronze Citizen';
  }

  // Get progress to next level
  Map<String, dynamic> getLevelProgress() {
    int currentPoints = totalPoints;
    String nextLevel;
    int pointsNeeded;

    if (currentPoints < 50) {
      nextLevel = '🥈 Silver Citizen';
      pointsNeeded = 50 - currentPoints;
    } else if (currentPoints < 100) {
      nextLevel = '🥇 Gold Citizen';
      pointsNeeded = 100 - currentPoints;
    } else if (currentPoints < 200) {
      nextLevel = '🏆 Platinum Citizen';
      pointsNeeded = 200 - currentPoints;
    } else {
      nextLevel = 'Max Level Reached';
      pointsNeeded = 0;
    }

    return {
      'nextLevel': nextLevel,
      'pointsNeeded': pointsNeeded,
      'progressPercentage': pointsNeeded > 0 ? (currentPoints % 50) / 50.0 : 1.0,
    };
  }
}