class Feedback {
  final String id;
  final String reportId;
  final String userId;
  final String userName;
  final int rating; // 1-5 stars
  final String description;
  final DateTime createdAt;
  final String reportTitle;
  final String reportDepartment;

  Feedback({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.description,
    required this.createdAt,
    required this.reportTitle,
    required this.reportDepartment,
  });

  // Create a copy with modified values
  Feedback copyWith({
    String? id,
    String? reportId,
    String? userId,
    String? userName,
    int? rating,
    String? description,
    DateTime? createdAt,
    String? reportTitle,
    String? reportDepartment,
  }) {
    return Feedback(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      reportTitle: reportTitle ?? this.reportTitle,
      reportDepartment: reportDepartment ?? this.reportDepartment,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'reportTitle': reportTitle,
      'reportDepartment': reportDepartment,
    };
  }

  // Create from JSON
  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] ?? '',
      reportId: json['reportId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      rating: json['rating'] ?? 0,
      description: json['description'] ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : json['createdAt'] ?? DateTime.now(),
      reportTitle: json['reportTitle'] ?? '',
      reportDepartment: json['reportDepartment'] ?? '',
    );
  }

  // Convert to string
  @override
  String toString() {
    return 'Feedback{id: $id, reportId: $reportId, userId: $userId, userName: $userName, rating: $rating, description: $description, createdAt: $createdAt, reportTitle: $reportTitle, reportDepartment: $reportDepartment}';
  }

  // Check equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Feedback && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper method to get rating as stars
  String get ratingStars {
    String stars = '';
    for (int i = 1; i <= 5; i++) {
      stars += i <= rating ? '⭐' : '☆';
    }
    return stars;
  }

  // Helper method to get rating color
  String get ratingCategory {
    switch (rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Poor';
      case 1:
        return 'Very Poor';
      default:
        return 'No Rating';
    }
  }

  // Check if feedback is positive (4-5 stars)
  bool get isPositive => rating >= 4;

  // Check if feedback is negative (1-2 stars)
  bool get isNegative => rating <= 2;

  // Check if feedback is neutral (3 stars)
  bool get isNeutral => rating == 3;
}
