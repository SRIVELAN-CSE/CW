enum PasswordResetStatus {
  pending,    // Waiting for admin approval
  approved,   // Admin approved, user can reset password
  rejected,   // Admin rejected the request
  completed,  // Password has been reset
}

extension PasswordResetStatusExtension on PasswordResetStatus {
  String get displayName {
    switch (this) {
      case PasswordResetStatus.pending:
        return 'Pending Review';
      case PasswordResetStatus.approved:
        return 'Approved';
      case PasswordResetStatus.rejected:
        return 'Rejected';
      case PasswordResetStatus.completed:
        return 'Completed';
    }
  }

  String get color {
    switch (this) {
      case PasswordResetStatus.pending:
        return 'orange';
      case PasswordResetStatus.approved:
        return 'green';
      case PasswordResetStatus.rejected:
        return 'red';
      case PasswordResetStatus.completed:
        return 'blue';
    }
  }
}

class PasswordResetRequest {
  final String id;
  final String email;
  final String fullName; // For admin reference
  final String reason; // Why they need password reset
  final DateTime requestDate;
  final PasswordResetStatus status;
  final String? adminResponse; // Admin's approval/rejection reason
  final DateTime? responseDate;
  final String? respondedBy; // Admin who processed the request
  final DateTime? completedDate; // When password was actually reset

  const PasswordResetRequest({
    required this.id,
    required this.email,
    required this.fullName,
    required this.reason,
    required this.requestDate,
    required this.status,
    this.adminResponse,
    this.responseDate,
    this.respondedBy,
    this.completedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'reason': reason,
      'requestDate': requestDate.toIso8601String(),
      'status': status.toString(),
      'adminResponse': adminResponse,
      'responseDate': responseDate?.toIso8601String(),
      'respondedBy': respondedBy,
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequest(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      reason: json['reason'],
      requestDate: DateTime.parse(json['requestDate']),
      status: PasswordResetStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
        orElse: () => PasswordResetStatus.pending,
      ),
      adminResponse: json['adminResponse'],
      responseDate: json['responseDate'] != null 
          ? DateTime.parse(json['responseDate']) 
          : null,
      respondedBy: json['respondedBy'],
      completedDate: json['completedDate'] != null 
          ? DateTime.parse(json['completedDate']) 
          : null,
    );
  }

  PasswordResetRequest copyWith({
    String? id,
    String? email,
    String? fullName,
    String? reason,
    DateTime? requestDate,
    PasswordResetStatus? status,
    String? adminResponse,
    DateTime? responseDate,
    String? respondedBy,
    DateTime? completedDate,
  }) {
    return PasswordResetRequest(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      reason: reason ?? this.reason,
      requestDate: requestDate ?? this.requestDate,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      responseDate: responseDate ?? this.responseDate,
      respondedBy: respondedBy ?? this.respondedBy,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  // Helper methods
  bool get isPending => status == PasswordResetStatus.pending;
  bool get isApproved => status == PasswordResetStatus.approved;
  bool get isRejected => status == PasswordResetStatus.rejected;
  bool get isCompleted => status == PasswordResetStatus.completed;
  
  String get statusDisplay => status.displayName;
  
  Duration get pendingDuration {
    final now = DateTime.now();
    return now.difference(requestDate);
  }
  
  String get pendingTime {
    final duration = pendingDuration;
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}