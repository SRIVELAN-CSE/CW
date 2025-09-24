class SmartCategorizationService {
  static SmartCategorizationService? _instance;
  static SmartCategorizationService get instance =>
      _instance ??= SmartCategorizationService._();
  SmartCategorizationService._();

  // Priority determination based on keywords and category
  String determinePriority(String title, String description, String category) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    // Critical priority keywords
    final criticalKeywords = [
      'emergency',
      'urgent',
      'dangerous',
      'hazardous',
      'life threatening',
      'fire',
      'gas leak',
      'water main burst',
      'electrical hazard',
      'accident',
      'injury',
      'blocked ambulance',
      'major flooding',
      'bridge collapse',
      'building collapse',
      'explosion',
      'chemical spill',
    ];

    // High priority keywords
    final highKeywords = [
      'serious',
      'major',
      'significant',
      'important',
      'broken main',
      'power outage',
      'sewage overflow',
      'traffic light broken',
      'road blocked',
      'sinkhole',
      'falling debris',
      'unsafe conditions',
      'broken water main',
      'severe pothole',
      'damaged bridge',
    ];

    // Medium priority keywords
    final mediumKeywords = [
      'moderate',
      'noticeable',
      'concerning',
      'needs attention',
      'street light out',
      'small pothole',
      'trash overflow',
      'graffiti',
      'noise complaint',
      'minor leak',
      'cracked pavement',
    ];

    // Check for critical indicators
    if (_containsAny(text, criticalKeywords) || _isCriticalCategory(category)) {
      return 'Critical';
    }

    // Check for high priority indicators
    if (_containsAny(text, highKeywords) || _isHighPriorityCategory(category)) {
      return 'High';
    }

    // Check for medium priority indicators
    if (_containsAny(text, mediumKeywords)) {
      return 'Medium';
    }

    // Default priority based on category
    return _getDefaultPriorityForCategory(category);
  }

  // Enhanced department assignment based on intelligent keyword analysis
  String determineDepartment(
    String title,
    String description,
    String category,
  ) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    // Emergency services - highest priority overrides
    if (_containsAny(text, [
      'fire',
      'smoke',
      'burning',
      'explosion',
      'flames',
      'gas leak',
    ])) {
      return 'Fire Department';
    }

    if (_containsAny(text, [
      'crime',
      'theft',
      'robbery',
      'vandalism',
      'suspicious',
      'violence',
      'break-in',
      'assault',
      'harassment',
      'drug',
      'illegal',
    ])) {
      return 'Police Department';
    }

    if (_containsAny(text, [
      'medical emergency',
      'injury',
      'accident',
      'ambulance',
      'hurt',
      'bleeding',
      'unconscious',
      'heart attack',
      'emergency medical',
    ])) {
      return 'Emergency Medical Services';
    }

    // Water-related issues with specific department routing
    if (_containsAny(text, [
      'water',
      'pipe',
      'leak',
      'burst',
      'flooding',
      'drainage',
      'sewer',
      'overflow',
      'blockage',
      'tap',
      'valve',
      'water supply',
      'no water',
    ])) {
      return 'Water & Sewerage';
    }

    // Electrical issues
    if (_containsAny(text, [
      'electricity',
      'power',
      'electric',
      'voltage',
      'wire',
      'cable',
      'outage',
      'blackout',
      'transformer',
      'pole',
      'meter',
    ])) {
      return 'Electricity';
    }

    // Road and transportation
    if (_containsAny(text, [
      'road',
      'street',
      'highway',
      'traffic',
      'pothole',
      'pavement',
      'crossing',
      'bridge',
      'tunnel',
      'signal',
      'sign',
    ])) {
      if (_containsAny(text, [
        'traffic light',
        'signal',
        'stop sign',
        'crossing light',
      ])) {
        return 'Traffic Police';
      }
      return 'Transportation';
    }

    // Waste management and sanitation
    if (_containsAny(text, [
      'garbage',
      'trash',
      'waste',
      'rubbish',
      'bin',
      'collection',
      'dump',
      'litter',
      'cleaning',
      'sanitation',
    ])) {
      return 'Public Works';
    }

    // Parks and environment
    if (_containsAny(text, [
      'park',
      'garden',
      'tree',
      'grass',
      'playground',
      'bench',
      'landscaping',
      'plants',
      'flowers',
      'recreation',
    ])) {
      return 'Public Works';
    }

    // Health and environment
    if (_containsAny(text, [
      'health',
      'disease',
      'epidemic',
      'vaccination',
      'clinic',
      'hospital',
      'medical facility',
      'public health',
    ])) {
      return 'Health Services';
    }

    if (_containsAny(text, [
      'pollution',
      'environment',
      'air quality',
      'noise',
      'dust',
      'industrial waste',
      'smoke emission',
    ])) {
      return 'Environmental Services';
    }

    // Building and construction
    if (_containsAny(text, [
      'building',
      'construction',
      'structure',
      'illegal construction',
      'permit',
      'violation',
      'unauthorized',
    ])) {
      return 'Municipal Corporation';
    }

    // Animal control
    if (_containsAny(text, [
      'animal',
      'dog',
      'cat',
      'stray',
      'pet',
      'wildlife',
      'bird',
      'pest',
    ])) {
      return 'Social Services';
    }

    // Food safety and markets
    if (_containsAny(text, [
      'food',
      'restaurant',
      'market',
      'vendor',
      'food safety',
      'hygiene',
      'expired food',
    ])) {
      return 'Health Services';
    }

    // Education related
    if (_containsAny(text, [
      'school',
      'education',
      'teacher',
      'student',
      'classroom',
      'college',
    ])) {
      return 'Education';
    }

    // Transport and vehicles
    if (_containsAny(text, [
      'bus',
      'auto',
      'taxi',
      'vehicle',
      'transport',
      'metro',
      'railway',
    ])) {
      return 'Transportation';
    }

    // Category-based fallback assignment
    switch (category.toLowerCase()) {
      case 'road & transportation':
        return 'Transportation';
      case 'water & sewerage':
        return 'Water & Sewerage';
      case 'electricity':
        return 'Electricity';
      case 'garbage & sanitation':
        return 'Public Works';
      case 'street lighting':
        return 'Electricity';
      case 'parks & recreation':
        return 'Public Works';
      case 'public safety':
        return 'Traffic Police';
      case 'noise pollution':
        return 'Environmental Services';
      case 'health':
        return 'Health Services';
      case 'education':
        return 'Education';
      case 'other':
        return _determineOtherDepartment(text);
      default:
        return 'Municipal Corporation';
    }
  }

  // Get estimated resolution time based on priority and department
  String getEstimatedResolutionTime(String priority, String department) {
    final baseDays = _getBaseDaysForDepartment(department);

    switch (priority) {
      case 'Critical':
        return 'Within 24 hours';
      case 'High':
        return baseDays <= 2 ? 'Within $baseDays days' : 'Within 2-3 days';
      case 'Medium':
        return 'Within $baseDays days';
      case 'Low':
        return 'Within ${baseDays + 2}-${baseDays + 7} days';
      default:
        return 'Within $baseDays days';
    }
  }

  // Get department contact information
  Map<String, String> getDepartmentContact(String department) {
    final contacts = {
      'Fire Department': {
        'phone': '911',
        'email': 'fire.emergency@city.gov',
        'hours': '24/7',
      },
      'Police Department': {
        'phone': '911',
        'email': 'police@city.gov',
        'hours': '24/7',
      },
      'Emergency Medical Services': {
        'phone': '911',
        'email': 'emergency@city.gov',
        'hours': '24/7',
      },
      'Public Works - Roads': {
        'phone': '(555) 123-4567',
        'email': 'roads@city.gov',
        'hours': 'Mon-Fri 8AM-5PM',
      },
      'Water Department': {
        'phone': '(555) 123-4568',
        'email': 'water@city.gov',
        'hours': 'Mon-Fri 8AM-5PM, Emergency 24/7',
      },
      'Electric Utility': {
        'phone': '(555) 123-4569',
        'email': 'electric@city.gov',
        'hours': 'Mon-Fri 8AM-5PM, Emergency 24/7',
      },
      'Sanitation Department': {
        'phone': '(555) 123-4570',
        'email': 'sanitation@city.gov',
        'hours': 'Mon-Fri 6AM-4PM',
      },
    };

    return contacts[department] ??
        {
          'phone': '(555) 123-4500',
          'email': 'general@city.gov',
          'hours': 'Mon-Fri 8AM-5PM',
        };
  }

  // Comprehensive classification for real-world scenarios
  Map<String, String> classifyIssue(
    String title,
    String description,
    String category,
  ) {
    final priority = determinePriority(title, description, category);
    final department = determineDepartment(title, description, category);
    final estimatedTime = getEstimatedResolutionTime(priority, department);
    final contact = getDepartmentContact(department);

    return {
      'priority': priority,
      'department': department,
      'estimatedTime': estimatedTime,
      'contactPhone': contact['phone'] ?? '',
      'contactEmail': contact['email'] ?? '',
      'workingHours': contact['hours'] ?? '',
      'urgencyLevel': _getUrgencyLevel(priority),
      'actionRequired': _getActionRequired(priority, department),
    };
  }

  // Auto-classify issue based on description (main feature)
  Map<String, dynamic> classifyIssueStatement(
    String title,
    String description,
  ) {
    // Auto-detect category based on content
    String category = autoDetectCategory(title, description);

    // Classify department based on content
    String department = determineDepartment(title, description, category);

    // Get priority
    String priority = determinePriority(title, description, category);

    // Get estimated time
    String estimatedTime = getEstimatedResolutionTime(priority, department);

    // Get contact info
    Map<String, String> contactInfo = getDepartmentContact(department);

    return {
      'originalTitle': title,
      'originalDescription': description,
      'detectedCategory': category,
      'assignedDepartment': department,
      'priority': priority,
      'estimatedResolution': estimatedTime,
      'urgencyLevel': _getUrgencyLevel(priority),
      'actionRequired': _getActionRequired(priority, department),
      'contactPhone': contactInfo['phone'],
      'contactEmail': contactInfo['email'],
      'workingHours': contactInfo['hours'],
    };
  }

  // Private helper methods
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword.toLowerCase()));
  }

  bool _isCriticalCategory(String category) {
    final criticalCategories = ['public safety'];
    return criticalCategories.contains(category.toLowerCase());
  }

  bool _isHighPriorityCategory(String category) {
    final highPriorityCategories = ['water & sewerage', 'electricity'];
    return highPriorityCategories.contains(category.toLowerCase());
  }

  String _getDefaultPriorityForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'public safety':
      case 'water & sewerage':
      case 'electricity':
        return 'High';
      case 'road & transportation':
      case 'garbage & sanitation':
        return 'Medium';
      case 'street lighting':
      case 'parks & recreation':
      case 'noise pollution':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  String _getUrgencyLevel(String priority) {
    switch (priority) {
      case 'Critical':
        return 'IMMEDIATE ACTION REQUIRED';
      case 'High':
        return 'Urgent - High Priority';
      case 'Medium':
        return 'Standard Priority';
      case 'Low':
        return 'Low Priority - Routine';
      default:
        return 'Standard Priority';
    }
  }

  String _getActionRequired(String priority, String department) {
    if (priority == 'Critical') {
      if (department.contains('Fire') ||
          department.contains('Police') ||
          department.contains('Emergency')) {
        return 'Emergency response team dispatched immediately';
      }
      return 'Priority dispatch within 2-4 hours';
    } else if (priority == 'High') {
      return 'Same day response expected';
    } else if (priority == 'Medium') {
      return 'Response within 2-3 business days';
    } else {
      return 'Response within 5-7 business days';
    }
  }

  String _determineOtherDepartment(String text) {
    // Advanced keyword analysis for uncategorized issues
    if (_containsAny(text, [
      'animal',
      'pet',
      'dog',
      'cat',
      'wildlife',
      'stray',
      'rabid',
      'bite',
    ])) {
      return 'Social Services';
    }

    if (_containsAny(text, [
      'building',
      'construction',
      'permit',
      'code violation',
      'illegal structure',
      'unauthorized building',
      'unsafe building',
      'demolition',
    ])) {
      return 'Municipal Corporation';
    }

    if (_containsAny(text, [
      'business',
      'license',
      'permit',
      'zoning',
      'commercial',
      'shop',
      'vendor',
      'market',
      'hawker',
    ])) {
      return 'Municipal Corporation';
    }

    if (_containsAny(text, [
      'health',
      'food safety',
      'restaurant',
      'contamination',
      'hygiene',
      'disease',
      'epidemic',
      'vaccination',
    ])) {
      return 'Health Services';
    }

    if (_containsAny(text, [
      'cemetery',
      'burial',
      'grave',
      'funeral',
      'cremation',
    ])) {
      return 'Social Services';
    }

    if (_containsAny(text, [
      'library',
      'book',
      'reading',
      'study hall',
      'community center',
    ])) {
      return 'Education';
    }

    if (_containsAny(text, [
      'social',
      'welfare',
      'pension',
      'disability',
      'elderly',
      'senior citizen',
    ])) {
      return 'Social Services';
    }

    if (_containsAny(text, [
      'tax',
      'property tax',
      'assessment',
      'revenue',
      'collection',
    ])) {
      return 'Municipal Corporation';
    }

    if (_containsAny(text, [
      'document',
      'certificate',
      'birth certificate',
      'death certificate',
      'marriage certificate',
      'records',
    ])) {
      return 'Municipal Corporation';
    }

    if (_containsAny(text, [
      'employment',
      'job',
      'unemployment',
      'skill development',
      'training',
    ])) {
      return 'Social Services';
    }

    if (_containsAny(text, [
      'fire safety',
      'fire clearance',
      'fire NOC',
      'fire certificate',
    ])) {
      return 'Public Works';
    }

    if (_containsAny(text, [
      'legal',
      'court',
      'lawyer',
      'advocate',
      'legal aid',
      'litigation',
    ])) {
      return 'Municipal Corporation';
    }

    if (_containsAny(text, [
      'women',
      'child',
      'domestic violence',
      'harassment',
      'protection',
    ])) {
      return 'Social Services';
    }

    if (_containsAny(text, [
      'tourism',
      'tourist',
      'heritage',
      'monument',
      'cultural',
    ])) {
      return 'Social Services';
    }

    return 'Municipal Corporation';
  }

  int _getBaseDaysForDepartment(String department) {
    switch (department) {
      case 'Fire Department':
      case 'Police Department':
      case 'Emergency Medical Services':
        return 1;
      case 'Public Works - Roads':
      case 'Water Department':
      case 'Electric Utility':
        return 3;
      case 'Sanitation Department':
      case 'Street Lighting Department':
        return 5;
      case 'Parks & Recreation':
      case 'Environmental Department':
        return 7;
      default:
        return 5;
    }
  }

  String autoDetectCategory(String title, String description) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    if (_containsAny(text, [
      'water',
      'pipe',
      'leak',
      'sewer',
      'drainage',
      'flooding',
    ])) {
      return 'Water & Sewerage';
    }
    if (_containsAny(text, [
      'road',
      'street',
      'pothole',
      'traffic',
      'bridge',
      'highway',
    ])) {
      return 'Road & Transportation';
    }
    if (_containsAny(text, [
      'electricity',
      'power',
      'outage',
      'electric',
      'voltage',
    ])) {
      return 'Electricity';
    }
    if (_containsAny(text, [
      'garbage',
      'trash',
      'waste',
      'sanitation',
      'cleaning',
    ])) {
      return 'Garbage & Sanitation';
    }
    if (_containsAny(text, ['street light', 'lamp', 'lighting', 'bulb'])) {
      return 'Street Lighting';
    }
    if (_containsAny(text, [
      'park',
      'garden',
      'playground',
      'recreation',
      'tree',
    ])) {
      return 'Parks & Recreation';
    }
    if (_containsAny(text, [
      'crime',
      'safety',
      'police',
      'suspicious',
      'theft',
    ])) {
      return 'Public Safety';
    }
    if (_containsAny(text, ['noise', 'pollution', 'loud', 'sound'])) {
      return 'Noise Pollution';
    }
    if (_containsAny(text, ['health', 'medical', 'disease', 'food safety'])) {
      return 'Health';
    }
    if (_containsAny(text, ['education', 'school', 'teacher', 'student'])) {
      return 'Education';
    }

    return 'Other';
  }
}
