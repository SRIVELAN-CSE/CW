const mongoose = require('mongoose');

// Sub-schema for report updates/status changes
const reportUpdateSchema = new mongoose.Schema({
  message: {
    type: String,
    required: [true, 'Update message is required'],
    trim: true,
    maxlength: [1000, 'Update message cannot exceed 1000 characters']
  },
  status: {
    type: String,
    enum: {
      values: ['submitted', 'acknowledged', 'in_progress', 'resolved', 'rejected', 'closed'],
      message: 'Invalid status'
    },
    required: true
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  updatedByName: {
    type: String,
    required: true
  },
  attachments: [{
    filename: String,
    url: String,
    fileType: String,
    uploadedAt: {
      type: Date,
      default: Date.now
    }
  }],
  isInternal: {
    type: Boolean,
    default: false // Internal updates not visible to citizens
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Sub-schema for report feedback
const feedbackSchema = new mongoose.Schema({
  rating: {
    type: Number,
    min: [1, 'Rating must be at least 1'],
    max: [5, 'Rating cannot exceed 5']
  },
  comment: {
    type: String,
    trim: true,
    maxlength: [500, 'Feedback comment cannot exceed 500 characters']
  },
  submittedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  submittedAt: {
    type: Date,
    default: Date.now
  }
});

// Main report schema
const reportSchema = new mongoose.Schema({
  // Basic Information
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    minlength: [5, 'Title must be at least 5 characters'],
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    trim: true,
    minlength: [10, 'Description must be at least 10 characters'],
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  
  // Categorization
  category: {
    type: String,
    required: [true, 'Category is required'],
    enum: {
      values: [
        'garbage_collection',
        'road_maintenance',
        'street_lights',
        'water_supply',
        'drainage',
        'public_safety',
        'health_services',
        'education',
        'transportation',
        'noise_pollution',
        'air_pollution',
        'illegal_construction',
        'traffic_management',
        'public_facilities',
        'others'
      ],
      message: 'Invalid category selected'
    }
  },
  subcategory: {
    type: String,
    trim: true
  },
  
  // Location Information
  location: {
    address: {
      type: String,
      required: [true, 'Address is required'],
      trim: true
    },
    landmark: {
      type: String,
      trim: true
    },
    city: {
      type: String,
      required: [true, 'City is required'],
      trim: true
    },
    state: {
      type: String,
      required: [true, 'State is required'],
      trim: true
    },
    pincode: {
      type: String,
      required: [true, 'Pincode is required'],
      match: [/^\d{6}$/, 'Please enter a valid 6-digit pincode']
    },
    coordinates: {
      latitude: {
        type: Number,
        required: [true, 'Latitude is required'],
        min: [-90, 'Latitude must be between -90 and 90'],
        max: [90, 'Latitude must be between -90 and 90']
      },
      longitude: {
        type: Number,
        required: [true, 'Longitude is required'],
        min: [-180, 'Longitude must be between -180 and 180'],
        max: [180, 'Longitude must be between -180 and 180']
      }
    }
  },

  // Status and Priority
  status: {
    type: String,
    enum: {
      values: ['submitted', 'acknowledged', 'in_progress', 'resolved', 'rejected', 'closed'],
      message: 'Invalid status'
    },
    default: 'submitted'
  },
  priority: {
    type: String,
    enum: {
      values: ['low', 'medium', 'high', 'critical'],
      message: 'Invalid priority level'
    },
    default: 'medium'
  },
  
  // Auto-categorized information
  estimatedResolutionTime: {
    type: Number, // in hours
    default: 72
  },
  aiCategorized: {
    type: Boolean,
    default: false
  },
  aiConfidenceScore: {
    type: Number,
    min: 0,
    max: 1,
    default: 0
  },
  keywords: [{
    type: String,
    trim: true
  }],

  // Assignment
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  assignedDepartment: {
    type: String,
    enum: [
      'garbage_collection',
      'drainage',
      'road_maintenance', 
      'street_lights',
      'water_supply',
      'public_safety',
      'health_services',
      'education',
      'transportation',
      'general_administration'
    ]
  },
  assignedAt: {
    type: Date
  },
  
  // Submission Details
  submittedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  submittedByName: {
    type: String,
    required: true
  },
  submittedByPhone: {
    type: String,
    required: true
  },
  submittedByEmail: {
    type: String,
    required: true
  },
  isAnonymous: {
    type: Boolean,
    default: false
  },
  
  // Media Attachments
  images: [{
    url: {
      type: String,
      required: true
    },
    publicId: String, // For Cloudinary
    filename: String,
    uploadedAt: {
      type: Date,
      default: Date.now
    },
    description: String
  }],
  videos: [{
    url: {
      type: String,
      required: true
    },
    publicId: String, // For Cloudinary
    filename: String,
    uploadedAt: {
      type: Date,
      default: Date.now
    },
    description: String
  }],
  documents: [{
    url: {
      type: String,
      required: true
    },
    filename: String,
    fileType: String,
    uploadedAt: {
      type: Date,
      default: Date.now
    },
    description: String
  }],

  // Progress Tracking
  updates: [reportUpdateSchema],
  
  // Resolution Details
  resolutionDetails: {
    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    resolvedAt: {
      type: Date
    },
    resolutionNote: {
      type: String,
      trim: true,
      maxlength: [1000, 'Resolution note cannot exceed 1000 characters']
    },
    resolutionImages: [{
      url: String,
      publicId: String,
      filename: String,
      uploadedAt: {
        type: Date,
        default: Date.now
      }
    }]
  },
  
  // Feedback and Rating
  feedback: feedbackSchema,
  
  // Urgency and Impact
  urgency: {
    type: String,
    enum: ['low', 'medium', 'high', 'emergency'],
    default: 'medium'
  },
  impact: {
    type: String,
    enum: ['individual', 'community', 'city_wide', 'regional'],
    default: 'community'
  },
  affectedPeople: {
    type: Number,
    min: [1, 'At least 1 person must be affected'],
    default: 1
  },

  // Verification and Quality
  isVerified: {
    type: Boolean,
    default: false
  },
  verifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  verifiedAt: {
    type: Date
  },
  qualityScore: {
    type: Number,
    min: 0,
    max: 10,
    default: 5
  },

  // Metrics and Analytics
  viewCount: {
    type: Number,
    default: 0
  },
  upvotes: {
    type: Number,
    default: 0
  },
  downvotes: {
    type: Number,
    default: 0
  },
  reportedBy: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    reason: String,
    reportedAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Duplicate Detection
  isDuplicate: {
    type: Boolean,
    default: false
  },
  parentReport: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Report'
  },
  duplicateReports: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Report'
  }],

  // Communication
  allowCommunication: {
    type: Boolean,
    default: true
  },
  publiclyVisible: {
    type: Boolean,
    default: true
  },
  
  // Dates
  expectedResolutionDate: {
    type: Date
  },
  actualResolutionDate: {
    type: Date
  },
  followUpRequired: {
    type: Boolean,
    default: false
  },
  followUpDate: {
    type: Date
  },
  
  // Additional Metadata
  source: {
    type: String,
    enum: ['mobile_app', 'web_app', 'phone_call', 'email', 'walk_in', 'social_media'],
    default: 'mobile_app'
  },
  deviceInfo: {
    platform: String,
    version: String,
    userAgent: String
  },
  ipAddress: {
    type: String,
    select: false // Don't include in queries by default
  }

}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better performance
reportSchema.index({ status: 1 });
reportSchema.index({ category: 1 });
reportSchema.index({ priority: 1 });
reportSchema.index({ submittedBy: 1 });
reportSchema.index({ assignedTo: 1 });
reportSchema.index({ assignedDepartment: 1 });
reportSchema.index({ createdAt: -1 });
reportSchema.index({ 'location.coordinates.latitude': 1, 'location.coordinates.longitude': 1 });
reportSchema.index({ keywords: 1 });
reportSchema.index({ isVerified: 1 });
reportSchema.index({ isDuplicate: 1 });

// Compound indexes
reportSchema.index({ status: 1, priority: 1 });
reportSchema.index({ category: 1, status: 1 });
reportSchema.index({ assignedDepartment: 1, status: 1 });

// Virtual for report age in days
reportSchema.virtual('ageInDays').get(function() {
  return Math.floor((new Date() - this.createdAt) / (1000 * 60 * 60 * 24));
});

// Virtual for resolution time in days
reportSchema.virtual('resolutionTimeInDays').get(function() {
  if (this.actualResolutionDate) {
    return Math.floor((this.actualResolutionDate - this.createdAt) / (1000 * 60 * 60 * 24));
  }
  return null;
});

// Virtual for full location string
reportSchema.virtual('fullLocation').get(function() {
  const parts = [
    this.location?.address,
    this.location?.landmark,
    this.location?.city,
    this.location?.state,
    this.location?.pincode
  ].filter(Boolean);
  return parts.join(', ');
});

// Virtual for urgency score (computed from priority, urgency, impact)
reportSchema.virtual('urgencyScore').get(function() {
  const priorityScore = { low: 1, medium: 2, high: 3, critical: 4 }[this.priority] || 2;
  const urgencyScore = { low: 1, medium: 2, high: 3, emergency: 4 }[this.urgency] || 2;
  const impactScore = { individual: 1, community: 2, city_wide: 3, regional: 4 }[this.impact] || 2;
  
  return (priorityScore + urgencyScore + impactScore) / 3;
});

// Pre-save middleware
reportSchema.pre('save', function(next) {
  // Auto-assign department based on category
  if (!this.assignedDepartment && this.category) {
    const categoryDepartmentMap = {
      'garbage_collection': 'garbage_collection',
      'road_maintenance': 'road_maintenance',
      'street_lights': 'street_lights',
      'water_supply': 'water_supply',
      'drainage': 'drainage',
      'public_safety': 'public_safety',
      'health_services': 'health_services',
      'education': 'education',
      'transportation': 'transportation'
    };
    
    this.assignedDepartment = categoryDepartmentMap[this.category] || 'general_administration';
  }
  
  // Set expected resolution date based on priority
  if (!this.expectedResolutionDate && this.isNew) {
    const priorityHours = { low: 168, medium: 72, high: 24, critical: 4 }[this.priority] || 72;
    this.expectedResolutionDate = new Date(Date.now() + priorityHours * 60 * 60 * 1000);
  }
  
  next();
});

// Static method to get reports by location
reportSchema.statics.findByLocation = function(latitude, longitude, radiusInKm = 5) {
  const radiusInRadians = radiusInKm / 6371; // Earth's radius in km
  
  return this.find({
    'location.coordinates.latitude': {
      $gte: latitude - radiusInRadians,
      $lte: latitude + radiusInRadians
    },
    'location.coordinates.longitude': {
      $gte: longitude - radiusInRadians,
      $lte: longitude + radiusInRadians
    }
  });
};

// Static method to get report statistics
reportSchema.statics.getReportStats = async function() {
  return await this.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        avgResolutionTime: {
          $avg: {
            $cond: [
              { $ne: ['$actualResolutionDate', null] },
              { $subtract: ['$actualResolutionDate', '$createdAt'] },
              null
            ]
          }
        }
      }
    }
  ]);
};

// Instance method to add update
reportSchema.methods.addUpdate = function(message, status, updatedBy, updatedByName, isInternal = false) {
  this.updates.push({
    message,
    status,
    updatedBy,
    updatedByName,
    isInternal
  });
  
  this.status = status;
  
  if (status === 'resolved') {
    this.actualResolutionDate = new Date();
    this.resolutionDetails.resolvedAt = new Date();
    this.resolutionDetails.resolvedBy = updatedBy;
  }
  
  return this.save();
};

// Instance method to calculate similarity with another report
reportSchema.methods.calculateSimilarity = function(otherReport) {
  let score = 0;
  
  // Location similarity (50% weight)
  const distance = this.getDistanceTo(otherReport);
  if (distance < 1) score += 50; // Within 1 km
  else if (distance < 5) score += 30; // Within 5 km
  else if (distance < 10) score += 15; // Within 10 km
  
  // Category similarity (30% weight)
  if (this.category === otherReport.category) score += 30;
  
  // Keyword similarity (20% weight)
  const commonKeywords = this.keywords.filter(k => otherReport.keywords.includes(k));
  score += (commonKeywords.length / Math.max(this.keywords.length, 1)) * 20;
  
  return score;
};

// Instance method to calculate distance to another report
reportSchema.methods.getDistanceTo = function(otherReport) {
  const lat1 = this.location.coordinates.latitude;
  const lon1 = this.location.coordinates.longitude;
  const lat2 = otherReport.location.coordinates.latitude;
  const lon2 = otherReport.location.coordinates.longitude;
  
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  
  return R * c; // Distance in km
};

module.exports = mongoose.model('Report', reportSchema);