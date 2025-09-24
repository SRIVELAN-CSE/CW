const mongoose = require('mongoose');

const registrationRequestSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: [100, 'Name cannot exceed 100 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    match: [/^\+?[\d\s-()]{10,15}$/, 'Please enter a valid phone number']
  },
  userType: {
    type: String,
    enum: ['public', 'officer'],
    required: true
  },
  location: {
    type: String,
    trim: true
  },
  department: {
    type: String,
    enum: ['garbageCollection', 'drainage', 'roadMaintenance', 'streetLights', 'waterSupply', 'others'],
    required: function() {
      return this.userType === 'officer';
    }
  },
  reason: {
    type: String,
    trim: true,
    maxlength: [500, 'Reason cannot exceed 500 characters']
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  reviewedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  reviewedByName: {
    type: String
  },
  reviewedAt: {
    type: Date
  },
  reviewNotes: {
    type: String,
    trim: true,
    maxlength: [1000, 'Review notes cannot exceed 1000 characters']
  },
  documentsUrls: [{
    type: String
  }],
  idProof: {
    type: String
  },
  addressProof: {
    type: String
  }
}, {
  timestamps: true
});

// Indexes for better query performance
registrationRequestSchema.index({ email: 1 });
registrationRequestSchema.index({ status: 1 });
registrationRequestSchema.index({ userType: 1 });
registrationRequestSchema.index({ department: 1 });
registrationRequestSchema.index({ createdAt: -1 });

// Update status method
registrationRequestSchema.methods.updateStatus = function(status, reviewedBy, reviewedByName, reviewNotes) {
  this.status = status;
  this.reviewedBy = reviewedBy;
  this.reviewedByName = reviewedByName;
  this.reviewedAt = new Date();
  this.reviewNotes = reviewNotes;
  
  return this.save();
};

module.exports = mongoose.model('RegistrationRequest', registrationRequestSchema);