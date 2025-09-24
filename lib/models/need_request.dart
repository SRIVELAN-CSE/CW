class NeedType {
  static const String healthcare = 'healthcare';
  static const String education = 'education';
  static const String infrastructure = 'infrastructure';
  static const String transportation = 'transportation';
  static const String safety = 'safety';
  static const String environment = 'environment';
  static const String utilities = 'utilities';
  static const String social = 'social';
  static const String other = 'other';

  static List<String> get all => [
    healthcare,
    education,
    infrastructure,
    transportation,
    safety,
    environment,
    utilities,
    social,
    other,
  ];

  static Map<String, String> get displayNames => {
    healthcare: 'Healthcare Facility',
    education: 'Educational Facility',
    infrastructure: 'Infrastructure Development',
    transportation: 'Transportation Service',
    safety: 'Safety & Security',
    environment: 'Environmental Service',
    utilities: 'Utilities (Water/Power)',
    social: 'Social Service',
    other: 'Other',
  };

  static Map<String, String> get descriptions => {
    healthcare: 'Hospitals, clinics, medical centers',
    education: 'Schools, colleges, libraries',
    infrastructure: 'Roads, bridges, buildings',
    transportation: 'Bus stops, metro stations, parking',
    safety: 'Police stations, fire stations',
    environment: 'Parks, waste management, pollution control',
    utilities: 'Water supply, electricity, internet',
    social: 'Community centers, welfare services',
    other: 'Other facility requirements',
  };
}

enum NeedPriority { low, medium, high, urgent }

enum NeedStatus { submitted, underReview, approved, inProgress, completed, rejected }

class NeedRequest {
  final String id;
  final String title;
  final String description;
  final String needType;
  final NeedPriority priority;
  final NeedStatus status;
  final String location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String requesterName;
  final String requesterEmail;
  final String? requesterPhone;
  final int estimatedBeneficiaries;
  final String? justification;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedDepartment;
  final String? adminNotes;
  final String? rejectionReason;
  final int? estimatedImplementationDays;
  final DateTime? expectedCompletionDate;
  final String? implementationTimeline;

  const NeedRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.needType,
    required this.priority,
    required this.status,
    required this.location,
    this.address,
    this.latitude,
    this.longitude,
    required this.requesterName,
    required this.requesterEmail,
    this.requesterPhone,
    required this.estimatedBeneficiaries,
    this.justification,
    this.attachments,
    required this.createdAt,
    this.updatedAt,
    this.assignedDepartment,
    this.adminNotes,
    this.rejectionReason,
    this.estimatedImplementationDays,
    this.expectedCompletionDate,
    this.implementationTimeline,
  });

  factory NeedRequest.fromJson(Map<String, dynamic> json) {
    return NeedRequest(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      needType: json['needType'] ?? NeedType.other,
      priority: NeedPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => NeedPriority.medium,
      ),
      status: NeedStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NeedStatus.submitted,
      ),
      location: json['location'] ?? '',
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      requesterName: json['requesterName'] ?? '',
      requesterEmail: json['requesterEmail'] ?? '',
      requesterPhone: json['requesterPhone'],
      estimatedBeneficiaries: json['estimatedBeneficiaries'] ?? 0,
      justification: json['justification'],
      attachments: json['attachments']?.cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      assignedDepartment: json['assignedDepartment'],
      adminNotes: json['adminNotes'],
      rejectionReason: json['rejectionReason'],
      estimatedImplementationDays: json['estimatedImplementationDays'],
      expectedCompletionDate: json['expectedCompletionDate'] != null ? DateTime.parse(json['expectedCompletionDate']) : null,
      implementationTimeline: json['implementationTimeline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'needType': needType,
      'priority': priority.name,
      'status': status.name,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'requesterPhone': requesterPhone,
      'estimatedBeneficiaries': estimatedBeneficiaries,
      'justification': justification,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'assignedDepartment': assignedDepartment,
      'adminNotes': adminNotes,
      'rejectionReason': rejectionReason,
      'estimatedImplementationDays': estimatedImplementationDays,
      'expectedCompletionDate': expectedCompletionDate?.toIso8601String(),
      'implementationTimeline': implementationTimeline,
    };
  }

  NeedRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? needType,
    NeedPriority? priority,
    NeedStatus? status,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    String? requesterName,
    String? requesterEmail,
    String? requesterPhone,
    int? estimatedBeneficiaries,
    String? justification,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedDepartment,
    String? adminNotes,
    String? rejectionReason,
    int? estimatedImplementationDays,
    DateTime? expectedCompletionDate,
    String? implementationTimeline,
  }) {
    return NeedRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      needType: needType ?? this.needType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      estimatedBeneficiaries: estimatedBeneficiaries ?? this.estimatedBeneficiaries,
      justification: justification ?? this.justification,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      estimatedImplementationDays: estimatedImplementationDays ?? this.estimatedImplementationDays,
      expectedCompletionDate: expectedCompletionDate ?? this.expectedCompletionDate,
      implementationTimeline: implementationTimeline ?? this.implementationTimeline,
    );
  }
}