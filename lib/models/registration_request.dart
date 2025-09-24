enum RegistrationStatus {
  registered, // Auto-approved and active
  notified,   // Admin has been notified
  archived,   // Old notification, archived
}

extension RegistrationStatusExtension on RegistrationStatus {
  String get displayName {
    switch (this) {
      case RegistrationStatus.registered:
        return 'Registered & Active';
      case RegistrationStatus.notified:
        return 'Admin Notified';
      case RegistrationStatus.archived:
        return 'Archived';
    }
  }

  String get color {
    switch (this) {
      case RegistrationStatus.registered:
        return 'green';
      case RegistrationStatus.notified:
        return 'blue';
      case RegistrationStatus.archived:
        return 'grey';
    }
  }
}

class RegistrationRequest {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String idNumber; // National ID or similar
  final String reason; // Why they want to register
  final String password; // User's chosen password
  final DateTime requestDate;
  final RegistrationStatus status;
  final String? adminResponse; // Admin's approval/rejection reason
  final DateTime? responseDate;
  final String? respondedBy; // Admin who processed the request
  final String userType; // 'citizen' or 'officer'
  final String? department; // For officer registrations
  final String? designation; // For officer registrations

  const RegistrationRequest({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.idNumber,
    required this.reason,
    required this.password,
    required this.requestDate,
    required this.status,
    this.adminResponse,
    this.responseDate,
    this.respondedBy,
    this.userType = 'citizen',
    this.department,
    this.designation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'idNumber': idNumber,
      'reason': reason,
      'password': password,
      'requestDate': requestDate.toIso8601String(),
      'status': status.toString(),
      'adminResponse': adminResponse,
      'responseDate': responseDate?.toIso8601String(),
      'respondedBy': respondedBy,
      'userType': userType,
      'department': department,
      'designation': designation,
    };
  }

  factory RegistrationRequest.fromJson(Map<String, dynamic> json) {
    return RegistrationRequest(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      idNumber: json['idNumber'],
      reason: json['reason'],
      password: json['password'] ?? '', // Default to empty string for existing data
      requestDate: DateTime.parse(json['requestDate']),
      status: RegistrationStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
        orElse: () => RegistrationStatus.registered,
      ),
      adminResponse: json['adminResponse'],
      responseDate: json['responseDate'] != null 
          ? DateTime.parse(json['responseDate']) 
          : null,
      respondedBy: json['respondedBy'],
      userType: json['userType'] ?? 'citizen',
      department: json['department'],
      designation: json['designation'],
    );
  }

  RegistrationRequest copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? idNumber,
    String? reason,
    String? password,
    DateTime? requestDate,
    RegistrationStatus? status,
    String? adminResponse,
    DateTime? responseDate,
    String? respondedBy,
    String? userType,
    String? department,
    String? designation,
  }) {
    return RegistrationRequest(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      idNumber: idNumber ?? this.idNumber,
      reason: reason ?? this.reason,
      password: password ?? this.password,
      requestDate: requestDate ?? this.requestDate,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      responseDate: responseDate ?? this.responseDate,
      respondedBy: respondedBy ?? this.respondedBy,
      userType: userType ?? this.userType,
      department: department ?? this.department,
      designation: designation ?? this.designation,
    );
  }

  // Helper methods
  bool get isRegistered => status == RegistrationStatus.registered;
  bool get isNotified => status == RegistrationStatus.notified;
  bool get isArchived => status == RegistrationStatus.archived;
  
  String get statusDisplay => status.displayName;
  
  Duration get registeredDuration {
    final now = DateTime.now();
    return now.difference(requestDate);
  }
  
  String get registeredTime {
    final duration = registeredDuration;
    if (duration.inDays > 0) {
      return '${duration.inDays} days ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours ago';
    } else {
      return '${duration.inMinutes} minutes ago';
    }
  }
}