class Report {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReportStatus status;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final String? reporterPhone;
  final String? assignedOfficerId;
  final String? assignedOfficerName;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String priority;
  final String department;
  final String estimatedResolutionTime;
  final Map<String, String> departmentContact;
  final List<ReportUpdate> updates;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.reporterEmail,
    this.reporterPhone,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.priority = 'Medium',
    this.department = 'General Services',
    this.estimatedResolutionTime = 'Within 5 days',
    this.departmentContact = const {},
    this.updates = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.toString(),
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'reporterPhone': reporterPhone,
      'assignedOfficerId': assignedOfficerId,
      'assignedOfficerName': assignedOfficerName,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'priority': priority,
      'department': department,
      'estimatedResolutionTime': estimatedResolutionTime,
      'departmentContact': departmentContact,
      'updates': updates.map((u) => u.toJson()).toList(),
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      location: json['location'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: ReportStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
        orElse: () => ReportStatus.submitted,
      ),
      reporterId: json['reporterId'],
      reporterName: json['reporterName'],
      reporterEmail: json['reporterEmail'],
      reporterPhone: json['reporterPhone'],
      assignedOfficerId: json['assignedOfficerId'],
      assignedOfficerName: json['assignedOfficerName'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      priority: json['priority'] ?? 'Medium',
      department: json['department'] ?? 'General Services',
      estimatedResolutionTime:
          json['estimatedResolutionTime'] ?? 'Within 5 days',
      departmentContact: Map<String, String>.from(
        json['departmentContact'] ?? {},
      ),
      updates:
          (json['updates'] as List<dynamic>?)
              ?.map((u) => ReportUpdate.fromJson(u))
              .toList() ??
          [],
    );
  }

  Report copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
    ReportStatus? status,
    String? assignedOfficerId,
    String? assignedOfficerName,
    List<String>? imageUrls,
    String? priority,
    String? department,
    String? estimatedResolutionTime,
    Map<String, String>? departmentContact,
    List<ReportUpdate>? updates,
  }) {
    return Report(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterEmail: reporterEmail,
      reporterPhone: reporterPhone,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
      imageUrls: imageUrls ?? this.imageUrls,
      priority: priority ?? this.priority,
      department: department ?? this.department,
      estimatedResolutionTime:
          estimatedResolutionTime ?? this.estimatedResolutionTime,
      departmentContact: departmentContact ?? this.departmentContact,
      updates: updates ?? this.updates,
    );
  }
}

enum ReportStatus {
  submitted,
  notSeen,
  resolveSoon,
  inProgress,
  done,
  rejected,
  closed,
}

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.notSeen:
        return 'NOT SEEN';
      case ReportStatus.resolveSoon:
        return 'RESOLVE SOON';
      case ReportStatus.inProgress:
        return 'IN PROGRESS';
      case ReportStatus.done:
        return 'DONE';
      case ReportStatus.rejected:
        return 'Rejected';
      case ReportStatus.closed:
        return 'Closed';
    }
  }

  String get color {
    switch (this) {
      case ReportStatus.submitted:
        return 'blue';
      case ReportStatus.notSeen:
        return 'grey';
      case ReportStatus.resolveSoon:
        return 'orange';
      case ReportStatus.inProgress:
        return 'purple';
      case ReportStatus.done:
        return 'green';
      case ReportStatus.rejected:
        return 'red';
      case ReportStatus.closed:
        return 'grey';
    }
  }
}

class ReportUpdate {
  final String id;
  final String message;
  final DateTime timestamp;
  final String updatedBy;
  final String updatedByRole;
  final ReportStatus? statusChange;

  ReportUpdate({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.updatedBy,
    required this.updatedByRole,
    this.statusChange,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedByRole': updatedByRole,
      'statusChange': statusChange?.toString(),
    };
  }

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    return ReportUpdate(
      id: json['id'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      updatedBy: json['updatedBy'],
      updatedByRole: json['updatedByRole'],
      statusChange: json['statusChange'] != null
          ? ReportStatus.values.firstWhere(
              (s) => s.toString() == json['statusChange'],
            )
          : null,
    );
  }
}
