const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  // Basic Information
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters'],
    maxlength: [100, 'Name cannot exceed 100 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Please enter a valid email']
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    match: [/^\+?[\d\s-()]{10,15}$/, 'Please enter a valid phone number']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false
  },

  // User Role & Permissions
  userType: {
    type: String,
    enum: {
      values: ['citizen', 'officer', 'admin'],
      message: 'User type must be either citizen, officer, or admin'
    },
    default: 'citizen'
  },
  
  // Location Information
  location: {
    address: {
      type: String,
      trim: true
    },
    city: {
      type: String,
      trim: true
    },
    state: {
      type: String,
      trim: true
    },
    pincode: {
      type: String,
      match: [/^\d{6}$/, 'Please enter a valid 6-digit pincode']
    },
    coordinates: {
      latitude: {
        type: Number,
        min: [-90, 'Latitude must be between -90 and 90'],
        max: [90, 'Latitude must be between -90 and 90']
      },
      longitude: {
        type: Number,
        min: [-180, 'Longitude must be between -180 and 180'],
        max: [180, 'Longitude must be between -180 and 180']
      }
    }
  },

  // Officer-specific Information
  department: {
    type: String,
    enum: {
      values: [
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
      ],
      message: 'Invalid department selected'
    },
    required: function() {
      return this.userType === 'officer';
    }
  },
  employeeId: {
    type: String,
    unique: true,
    sparse: true,
    required: function() {
      return this.userType === 'officer';
    }
  },
  designation: {
    type: String,
    trim: true,
    required: function() {
      return this.userType === 'officer';
    }
  },

  // Profile Information
  profilePicture: {
    type: String,
    default: null
  },
  dateOfBirth: {
    type: Date
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer_not_to_say']
  },

  // Account Status & Verification
  isActive: {
    type: Boolean,
    default: false // Default to false, admin activation required
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  emailVerified: {
    type: Boolean,
    default: false
  },
  phoneVerified: {
    type: Boolean,
    default: false
  },

  // Activity Tracking
  lastLogin: {
    type: Date
  },
  loginCount: {
    type: Number,
    default: 0
  },
  
  // Preferences & Settings
  preferences: {
    notifications: {
      email: {
        type: Boolean,
        default: true
      },
      sms: {
        type: Boolean,
        default: false
      },
      push: {
        type: Boolean,
        default: true
      }
    },
    language: {
      type: String,
      enum: ['en', 'hi', 'ta', 'te', 'kn', 'ml', 'gu', 'bn', 'or', 'pa'],
      default: 'en'
    },
    theme: {
      type: String,
      enum: ['light', 'dark', 'auto'],
      default: 'light'
    }
  },

  // Registration & Approval
  registrationDate: {
    type: Date,
    default: Date.now
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  approvedAt: {
    type: Date
  },
  rejectionReason: {
    type: String,
    trim: true
  },

  // Security Features
  passwordResetToken: {
    type: String,
    select: false
  },
  passwordResetExpires: {
    type: Date,
    select: false
  },
  emailVerificationToken: {
    type: String,
    select: false
  },
  emailVerificationExpires: {
    type: Date,
    select: false
  },

  // Two-Factor Authentication
  twoFactorEnabled: {
    type: Boolean,
    default: false
  },
  twoFactorSecret: {
    type: String,
    select: false
  },

  // Reports Statistics (for quick access)
  reportStats: {
    totalReports: {
      type: Number,
      default: 0
    },
    resolvedReports: {
      type: Number,
      default: 0
    },
    pendingReports: {
      type: Number,
      default: 0
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better performance
userSchema.index({ email: 1 });
userSchema.index({ phone: 1 });
userSchema.index({ userType: 1 });
userSchema.index({ department: 1 });
userSchema.index({ employeeId: 1 });
userSchema.index({ isActive: 1 });
userSchema.index({ 'location.coordinates.latitude': 1, 'location.coordinates.longitude': 1 });

// Virtual for user display name
userSchema.virtual('displayName').get(function() {
  if (this.userType === 'officer') {
    return `${this.name} (${this.designation})`;
  }
  return this.name;
});

// Virtual for complete address
userSchema.virtual('fullAddress').get(function() {
  const parts = [
    this.location?.address,
    this.location?.city,
    this.location?.state,
    this.location?.pincode
  ].filter(Boolean);
  return parts.join(', ');
});

// Pre-save middleware to hash password
userSchema.pre('save', async function(next) {
  // Only hash the password if it has been modified (or is new)
  if (!this.isModified('password')) return next();

  try {
    // Hash password with cost of 12
    const hashedPassword = await bcrypt.hash(this.password, 12);
    this.password = hashedPassword;
    next();
  } catch (error) {
    next(error);
  }
});

// Instance method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Instance method to generate password reset token
userSchema.methods.generatePasswordResetToken = function() {
  const crypto = require('crypto');
  const resetToken = crypto.randomBytes(32).toString('hex');
  
  this.passwordResetToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');
    
  this.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
  
  return resetToken;
};

// Instance method to generate email verification token
userSchema.methods.generateEmailVerificationToken = function() {
  const crypto = require('crypto');
  const verificationToken = crypto.randomBytes(32).toString('hex');
  
  this.emailVerificationToken = crypto
    .createHash('sha256')
    .update(verificationToken)
    .digest('hex');
    
  this.emailVerificationExpires = Date.now() + 24 * 60 * 60 * 1000; // 24 hours
  
  return verificationToken;
};

// Static method to find users by location
userSchema.statics.findByLocation = function(latitude, longitude, radiusInKm = 10) {
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

// Static method to get user statistics
userSchema.statics.getUserStats = async function() {
  return await this.aggregate([
    {
      $group: {
        _id: '$userType',
        count: { $sum: 1 },
        active: {
          $sum: { $cond: ['$isActive', 1, 0] }
        },
        verified: {
          $sum: { $cond: ['$isVerified', 1, 0] }
        }
      }
    }
  ]);
};

module.exports = mongoose.model('User', userSchema);