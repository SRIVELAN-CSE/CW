import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserType userType;
  final String? location;
  final String? department; // For officers
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;

  User({
    String? id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.location,
    this.department,
    this.isActive = true,
    DateTime? createdAt,
    this.lastLoginAt,
    this.profileImageUrl,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      userType: UserType.values.firstWhere(
        (type) => type.name == json['userType'],
      ),
      location: json['location'],
      department: json['department'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType.name,
      'location': location,
      'department': department,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? phone,
    UserType? userType,
    String? location,
    String? department,
    bool? isActive,
    DateTime? lastLoginAt,
    String? profileImageUrl,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      location: location ?? this.location,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, userType: $userType)';
  }
}

enum UserType {
  public,
  officer,
  admin;

  String get displayName {
    switch (this) {
      case UserType.public:
        return 'Citizen';
      case UserType.officer:
        return 'Officer';
      case UserType.admin:
        return 'Administrator';
    }
  }
}

enum Department {
  garbageCollection,
  drainage,
  roadMaintenance,
  streetLights,
  waterSupply,
  others;

  String get displayName {
    switch (this) {
      case Department.garbageCollection:
        return 'Garbage Collection';
      case Department.drainage:
        return 'Drainage';
      case Department.roadMaintenance:
        return 'Road Maintenance';
      case Department.streetLights:
        return 'Street Lights';
      case Department.waterSupply:
        return 'Water Supply';
      case Department.others:
        return 'Others';
    }
  }

  String get code {
    switch (this) {
      case Department.garbageCollection:
        return 'GC';
      case Department.drainage:
        return 'DR';
      case Department.roadMaintenance:
        return 'RM';
      case Department.streetLights:
        return 'SL';
      case Department.waterSupply:
        return 'WS';
      case Department.others:
        return 'OT';
    }
  }
}