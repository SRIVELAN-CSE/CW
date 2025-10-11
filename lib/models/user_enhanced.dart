class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserType userType;
  final UserLocation? location;
  final String? department;
  final String? employeeId;
  final String? designation;
  final String? profilePicture;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isActive;
  final bool isVerified;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime? lastLogin;
  final int loginCount;
  final UserPreferences? preferences;
  final DateTime registrationDate;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final ReportStats? reportStats;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.location,
    this.department,
    this.employeeId,
    this.designation,
    this.profilePicture,
    this.dateOfBirth,
    this.gender,
    required this.isActive,
    required this.isVerified,
    required this.emailVerified,
    required this.phoneVerified,
    this.lastLogin,
    required this.loginCount,
    this.preferences,
    required this.registrationDate,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.reportStats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: _parseUserType(json['userType']),
      location: json['location'] != null ? UserLocation.fromJson(json['location']) : null,
      department: json['department'],
      employeeId: json['employeeId'],
      designation: json['designation'],
      profilePicture: json['profilePicture'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      gender: json['gender'],
      isActive: json['isActive'] ?? false,
      isVerified: json['isVerified'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      loginCount: json['loginCount'] ?? 0,
      preferences: json['preferences'] != null ? UserPreferences.fromJson(json['preferences']) : null,
      registrationDate: json['registrationDate'] != null ? DateTime.parse(json['registrationDate']) : DateTime.now(),
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      rejectionReason: json['rejectionReason'],
      reportStats: json['reportStats'] != null ? ReportStats.fromJson(json['reportStats']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType.toString().split('.').last,
      'location': location?.toJson(),
      'department': department,
      'employeeId': employeeId,
      'designation': designation,
      'profilePicture': profilePicture,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'isActive': isActive,
      'isVerified': isVerified,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'lastLogin': lastLogin?.toIso8601String(),
      'loginCount': loginCount,
      'preferences': preferences?.toJson(),
      'registrationDate': registrationDate.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'reportStats': reportStats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static UserType _parseUserType(String? type) {
    switch (type) {
      case 'citizen':
      case 'public':
        return UserType.citizen;
      case 'officer':
        return UserType.officer;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.citizen;
    }
  }

  String get displayName {
    if (userType == UserType.officer && designation != null) {
      return '$name ($designation)';
    }
    return name;
  }

  String get fullAddress {
    if (location == null) return '';
    final parts = [
      location?.address,
      location?.city,
      location?.state,
      location?.pincode,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  User copyWith({
    String? name,
    String? phone,
    UserLocation? location,
    String? profilePicture,
    DateTime? dateOfBirth,
    String? gender,
    UserPreferences? preferences,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      userType: userType,
      location: location ?? this.location,
      department: department,
      employeeId: employeeId,
      designation: designation,
      profilePicture: profilePicture ?? this.profilePicture,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      isActive: isActive,
      isVerified: isVerified,
      emailVerified: emailVerified,
      phoneVerified: phoneVerified,
      lastLogin: lastLogin,
      loginCount: loginCount,
      preferences: preferences ?? this.preferences,
      registrationDate: registrationDate,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      rejectionReason: rejectionReason,
      reportStats: reportStats,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class UserLocation {
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final Coordinates? coordinates;

  UserLocation({
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.coordinates,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      coordinates: json['coordinates'] != null ? Coordinates.fromJson(json['coordinates']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'coordinates': coordinates?.toJson(),
    };
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class UserPreferences {
  final NotificationPreferences notifications;
  final String language;
  final String theme;

  UserPreferences({
    required this.notifications,
    required this.language,
    required this.theme,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notifications: NotificationPreferences.fromJson(json['notifications'] ?? {}),
      language: json['language'] ?? 'en',
      theme: json['theme'] ?? 'light',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.toJson(),
      'language': language,
      'theme': theme,
    };
  }
}

class NotificationPreferences {
  final bool email;
  final bool sms;
  final bool push;

  NotificationPreferences({
    required this.email,
    required this.sms,
    required this.push,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      email: json['email'] ?? true,
      sms: json['sms'] ?? false,
      push: json['push'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'sms': sms,
      'push': push,
    };
  }
}

class ReportStats {
  final int totalReports;
  final int resolvedReports;
  final int pendingReports;

  ReportStats({
    required this.totalReports,
    required this.resolvedReports,
    required this.pendingReports,
  });

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      totalReports: json['totalReports'] ?? 0,
      resolvedReports: json['resolvedReports'] ?? 0,
      pendingReports: json['pendingReports'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReports': totalReports,
      'resolvedReports': resolvedReports,
      'pendingReports': pendingReports,
    };
  }
}

enum UserType {
  citizen,
  officer,
  admin;

  String get displayName {
    switch (this) {
      case UserType.citizen:
        return 'Citizen';
      case UserType.officer:
        return 'Officer';
      case UserType.admin:
        return 'Administrator';
    }
  }
}