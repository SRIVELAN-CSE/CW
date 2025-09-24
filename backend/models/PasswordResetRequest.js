const mongoose = require('mongoose');

const passwordResetRequestSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  userType: {
    type: String,
    enum: ['public', 'officer', 'admin'],
    required: true
  },
  reason: {
    type: String,
    trim: true,
    maxlength: [500, 'Reason cannot exceed 500 characters']
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'completed'],
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
  newPassword: {
    type: String,
    select: false
  },
  passwordChangedAt: {
    type: Date
  },
  verificationCode: {
    type: String
  },
  verificationCodeExpire: {
    type: Date
  }
}, {
  timestamps: true
});

// Indexes for better query performance
passwordResetRequestSchema.index({ email: 1 });
passwordResetRequestSchema.index({ status: 1 });
passwordResetRequestSchema.index({ userType: 1 });
passwordResetRequestSchema.index({ createdAt: -1 });

// Update status method
passwordResetRequestSchema.methods.updateStatus = function(status, reviewedBy, reviewedByName, reviewNotes) {
  this.status = status;
  this.reviewedBy = reviewedBy;
  this.reviewedByName = reviewedByName;
  this.reviewedAt = new Date();
  this.reviewNotes = reviewNotes;
  
  return this.save();
};

// Generate verification code
passwordResetRequestSchema.methods.generateVerificationCode = function() {
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  this.verificationCode = code;
  this.verificationCodeExpire = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  return code;
};

module.exports = mongoose.model('PasswordResetRequest', passwordResetRequestSchema);