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
      'Noise Pollution',
      'Infrastructure',
      'Environment',
      'Health & Sanitation',
      'Traffic',
      'Others'
    ]
  },
  location: {
    type: String,
    required: [true, 'Location is required'],
    trim: true
  },
  address: {
    type: String,
    trim: true
  },
  latitude: {
    type: Number,
    min: -90,
    max: 90
  },
  longitude: {
    type: Number,
    min: -180,
    max: 180
  },
  status: {
    type: String,
    enum: ['submitted', 'acknowledged', 'in_progress', 'resolved', 'closed'],
    default: 'submitted'
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High', 'Critical'],
    default: 'Medium'
  },
  reporterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  reporterName: {
    type: String,
    required: true
  },
  reporterEmail: {
    type: String,
    required: true
  },
  reporterPhone: {
    type: String
  },
  assignedOfficerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  assignedOfficerName: {
    type: String
  },
  department: {
    type: String,
    enum: ['garbageCollection', 'drainage', 'roadMaintenance', 'streetLights', 'waterSupply', 'others'],
    default: 'others'
  },
  imageUrls: [{
    type: String
  }],
  videoUrls: [{
    type: String
  }],
  estimatedResolutionTime: {
    type: String,
    default: 'Within 5 days'
  },
  departmentContact: {
    name: String,
    phone: String,
    email: String
  },
  updates: [reportUpdateSchema],
  upvotes: {
    type: Number,
    default: 0
  },
  upvotedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  isPublic: {
    type: Boolean,
    default: true
  },
  tags: [{
    type: String,
    trim: true
  }],
  resolvedAt: Date,
  closedAt: Date
}, {
  timestamps: true
});

// Indexes for better query performance
reportSchema.index({ category: 1 });
reportSchema.index({ status: 1 });
reportSchema.index({ priority: 1 });
reportSchema.index({ department: 1 });
reportSchema.index({ reporterId: 1 });
reportSchema.index({ assignedOfficerId: 1 });
reportSchema.index({ createdAt: -1 });
reportSchema.index({ location: 'text', title: 'text', description: 'text' });

// Virtual for formatted location
reportSchema.virtual('formattedLocation').get(function() {
  if (this.latitude && this.longitude) {
    return `${this.latitude}, ${this.longitude}`;
  }
  return this.address || this.location;
});

// Update status and add to updates array
reportSchema.methods.updateStatus = function(status, message, updatedBy, updatedByName) {
  this.status = status;
  this.updates.push({
    message: message,
    status: status,
    updatedBy: updatedBy,
    updatedByName: updatedByName
  });
  
  if (status === 'resolved') {
    this.resolvedAt = new Date();
  } else if (status === 'closed') {
    this.closedAt = new Date();
  }
  
  return this.save();
};

// Auto-set department based on category
reportSchema.pre('save', function(next) {
  if (this.isNew || this.isModified('category')) {
    const categoryToDepartment = {
      'Garbage Collection': 'garbageCollection',
      'Road Maintenance': 'roadMaintenance',
      'Street Lights': 'streetLights',
      'Water Supply': 'waterSupply',
      'Drainage': 'drainage',
      'Others': 'others'
    };
    
    this.department = categoryToDepartment[this.category] || 'others';
  }
  next();
});

module.exports = mongoose.model('Report', reportSchema);