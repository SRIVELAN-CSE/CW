class Report {
  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final String? subCategory;
  final ReportStatus status;
  final Priority priority;
  final ReportLocation location;
  final List<MediaFile> images;
  final String userId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final List<StatusUpdate> statusHistory;
  final bool isAnonymous;
  final bool isUrgent;
  final int upvotes;
  final List<String> upvotedBy;
  final List<Comment> comments;
  final String? duplicateOf;
  final bool isDuplicate;
  final SmartCategorization? smartCategorization;
  final ReportMetadata? metadata;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.subCategory,
    required this.status,
    required this.priority,
    required this.location,
    required this.images,
    required this.userId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolutionNotes,
    required this.statusHistory,
    required this.isAnonymous,
    required this.isUrgent,
    required this.upvotes,
    required this.upvotedBy,
    required this.comments,
    this.duplicateOf,
    required this.isDuplicate,
    this.smartCategorization,
    this.metadata,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: _parseCategory(json['category']),
      subCategory: json['subCategory'],
      status: _parseStatus(json['status']),
      priority: _parsePriority(json['priority']),
      location: ReportLocation.fromJson(json['location'] ?? {}),
      images: (json['images'] as List<dynamic>?)?.map((img) => MediaFile.fromJson(img)).toList() ?? [],
      userId: json['userId'] ?? json['reportedBy'] ?? '',
      assignedTo: json['assignedTo'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolutionNotes: json['resolutionNotes'],
      statusHistory: (json['statusHistory'] as List<dynamic>?)?.map((status) => StatusUpdate.fromJson(status)).toList() ?? [],
      isAnonymous: json['isAnonymous'] ?? false,
      isUrgent: json['isUrgent'] ?? false,
      upvotes: json['upvotes'] ?? 0,
      upvotedBy: List<String>.from(json['upvotedBy'] ?? []),
      comments: (json['comments'] as List<dynamic>?)?.map((comment) => Comment.fromJson(comment)).toList() ?? [],
      duplicateOf: json['duplicateOf'],
      isDuplicate: json['isDuplicate'] ?? false,
      smartCategorization: json['smartCategorization'] != null ? SmartCategorization.fromJson(json['smartCategorization']) : null,
      metadata: json['metadata'] != null ? ReportMetadata.fromJson(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'subCategory': subCategory,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'location': location.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'userId': userId,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'statusHistory': statusHistory.map((status) => status.toJson()).toList(),
      'isAnonymous': isAnonymous,
      'isUrgent': isUrgent,
      'upvotes': upvotes,
      'upvotedBy': upvotedBy,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'duplicateOf': duplicateOf,
      'isDuplicate': isDuplicate,
      'smartCategorization': smartCategorization?.toJson(),
      'metadata': metadata?.toJson(),
    };
  }

  static ReportCategory _parseCategory(String? category) {
    switch (category) {
      case 'roads':
        return ReportCategory.roads;
      case 'sanitation':
        return ReportCategory.sanitation;
      case 'water':
        return ReportCategory.water;
      case 'electricity':
        return ReportCategory.electricity;
      case 'public_safety':
        return ReportCategory.publicSafety;
      case 'environment':
        return ReportCategory.environment;
      case 'others':
        return ReportCategory.others;
      default:
        return ReportCategory.others;
    }
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return ReportStatus.pending;
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }

  static Priority _parsePriority(String? priority) {
    switch (priority) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      case 'critical':
        return Priority.critical;
      default:
        return Priority.medium;
    }
  }

  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Report copyWith({
    ReportStatus? status,
    String? assignedTo,
    Priority? priority,
    String? resolutionNotes,
    DateTime? resolvedAt,
    List<StatusUpdate>? statusHistory,
    int? upvotes,
    List<String>? upvotedBy,
    List<Comment>? comments,
  }) {
    return Report(
      id: id,
      title: title,
      description: description,
      category: category,
      subCategory: subCategory,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      location: location,
      images: images,
      userId: userId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      statusHistory: statusHistory ?? this.statusHistory,
      isAnonymous: isAnonymous,
      isUrgent: isUrgent,
      upvotes: upvotes ?? this.upvotes,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      comments: comments ?? this.comments,
      duplicateOf: duplicateOf,
      isDuplicate: isDuplicate,
      smartCategorization: smartCategorization,
      metadata: metadata,
    );
  }
}

class ReportLocation {
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? landmark;

  ReportLocation({
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.landmark,
  });

  factory ReportLocation.fromJson(Map<String, dynamic> json) {
    return ReportLocation(
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'landmark': landmark,
    };
  }

  String get fullAddress {
    final parts = [address, landmark, city, state, pincode]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

class MediaFile {
  final String id;
  final String url;
  final String? publicId;
  final String filename;
  final int? size;
  final String? mimeType;
  final DateTime uploadedAt;

  MediaFile({
    required this.id,
    required this.url,
    this.publicId,
    required this.filename,
    this.size,
    this.mimeType,
    required this.uploadedAt,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'] ?? json['_id'] ?? '',
      url: json['url'] ?? '',
      publicId: json['publicId'],
      filename: json['filename'] ?? '',
      size: json['size'],
      mimeType: json['mimeType'],
      uploadedAt: json['uploadedAt'] != null ? DateTime.parse(json['uploadedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'publicId': publicId,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class StatusUpdate {
  final String id;
  final ReportStatus status;
  final String? notes;
  final String? updatedBy;
  final DateTime timestamp;

  StatusUpdate({
    required this.id,
    required this.status,
    this.notes,
    this.updatedBy,
    required this.timestamp,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      id: json['id'] ?? json['_id'] ?? '',
      status: Report._parseStatus(json['status']),
      notes: json['notes'],
      updatedBy: json['updatedBy'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.toString().split('.').last,
      'notes': notes,
      'updatedBy': updatedBy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Comment {
  final String id;
  final String text;
  final String userId;
  final String? userName;
  final DateTime createdAt;
  final bool isOfficerComment;

  Comment({
    required this.id,
    required this.text,
    required this.userId,
    this.userName,
    required this.createdAt,
    required this.isOfficerComment,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? json['_id'] ?? '',
      text: json['text'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isOfficerComment: json['isOfficerComment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'isOfficerComment': isOfficerComment,
    };
  }
}

class SmartCategorization {
  final double confidence;
  final List<String> keywords;
  final String? suggestedCategory;
  final String? suggestedSubCategory;
  final DateTime processedAt;

  SmartCategorization({
    required this.confidence,
    required this.keywords,
    this.suggestedCategory,
    this.suggestedSubCategory,
    required this.processedAt,
  });

  factory SmartCategorization.fromJson(Map<String, dynamic> json) {
    return SmartCategorization(
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      keywords: List<String>.from(json['keywords'] ?? []),
      suggestedCategory: json['suggestedCategory'],
      suggestedSubCategory: json['suggestedSubCategory'],
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'confidence': confidence,
      'keywords': keywords,
      'suggestedCategory': suggestedCategory,
      'suggestedSubCategory': suggestedSubCategory,
      'processedAt': processedAt.toIso8601String(),
    };
  }
}

class ReportMetadata {
  final String? deviceInfo;
  final String? appVersion;
  final String? userAgent;
  final Map<String, dynamic>? additionalData;

  ReportMetadata({
    this.deviceInfo,
    this.appVersion,
    this.userAgent,
    this.additionalData,
  });

  factory ReportMetadata.fromJson(Map<String, dynamic> json) {
    return ReportMetadata(
      deviceInfo: json['deviceInfo'],
      appVersion: json['appVersion'],
      userAgent: json['userAgent'],
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'userAgent': userAgent,
      'additionalData': additionalData,
    };
  }
}

enum ReportCategory {
  roads,
  sanitation,
  water,
  electricity,
  publicSafety,
  environment,
  others;

  String get displayName {
    switch (this) {
      case ReportCategory.roads:
        return 'Roads & Infrastructure';
      case ReportCategory.sanitation:
        return 'Sanitation & Waste';
      case ReportCategory.water:
        return 'Water Supply';
      case ReportCategory.electricity:
        return 'Electricity & Street Lights';
      case ReportCategory.publicSafety:
        return 'Public Safety';
      case ReportCategory.environment:
        return 'Environment';
      case ReportCategory.others:
        return 'Others';
    }
  }

  String get icon {
    switch (this) {
      case ReportCategory.roads:
        return '🛣️';
      case ReportCategory.sanitation:
        return '🗑️';
      case ReportCategory.water:
        return '💧';
      case ReportCategory.electricity:
        return '💡';
      case ReportCategory.publicSafety:
        return '🚨';
      case ReportCategory.environment:
        return '🌱';
      case ReportCategory.others:
        return '📝';
    }
  }
}

enum ReportStatus {
  pending,
  inProgress,
  resolved,
  rejected;

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  String get icon {
    switch (this) {
      case ReportStatus.pending:
        return '⏳';
      case ReportStatus.inProgress:
        return '🔄';
      case ReportStatus.resolved:
        return '✅';
      case ReportStatus.rejected:
        return '❌';
    }
  }
}

enum Priority {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical';
    }
  }

  String get icon {
    switch (this) {
      case Priority.low:
        return '🟢';
      case Priority.medium:
        return '🟡';
      case Priority.high:
        return '🟠';
      case Priority.critical:
        return '🔴';
    }
  }
}