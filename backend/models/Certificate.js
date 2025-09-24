const mongoose = require('mongoose');

const certificateSchema = new mongoose.Schema({
  certificateType: {
    type: String,
    required: [true, 'Certificate type is required'],
    enum: [
      'Birth Certificate',
      'Death Certificate',
      'Marriage Certificate',
      'Income Certificate',
      'Caste Certificate',
      'Domicile Certificate',
      'Character Certificate',
      'No Objection Certificate',
      'Business License',
      'Property Registration',
      'Others'
    ]
  },
  applicantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  applicantName: {
    type: String,
    required: true
  },
  applicantEmail: {
    type: String,
    required: true
  },
  applicantPhone: {
    type: String
  },
  applicationDetails: {
    fullName: String,
    dateOfBirth: Date,
    gender: {
      type: String,
      enum: ['Male', 'Female', 'Other']
    },
    fatherName: String,
    motherName: String,
    address: String,
    pincode: String,
    purpose: String,
    additionalInfo: mongoose.Schema.Types.Mixed
  },
  supportingDocuments: [{
    name: String,
    url: String,
    type: String,
    required: Boolean
  }],
  status: {
    type: String,
    enum: ['submitted', 'documents_verified', 'under_review', 'approved', 'rejected', 'issued', 'collected'],
    default: 'submitted'
  },
  priority: {
    type: String,
    enum: ['Normal', 'Urgent', 'Very Urgent'],
    default: 'Normal'
  },
  applicationNumber: {
    type: String,
    unique: true,
    required: true
  },
  submissionDate: {
    type: Date,
    default: Date.now
  },
  expectedDeliveryDate: {
    type: Date
  },
  actualDeliveryDate: {
    type: Date
  },
  processingOfficer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  processingOfficerName: {
    type: String
  },
  reviewNotes: {
    type: String,
    trim: true,
    maxlength: [1000, 'Review notes cannot exceed 1000 characters']
  },
  certificateUrl: {
    type: String
  },
  digitalSignature: {
    type: String
  },
  verificationCode: {
    type: String
  },
  fees: {
    amount: {
      type: Number,
      default: 0
    },
    currency: {
      type: String,
      default: 'INR'
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'refunded'],
      default: 'pending'
    },
    paymentMethod: String,
    transactionId: String,
    paidAt: Date
  },
  updates: [{
    message: String,
    status: String,
    updatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    updatedByName: String,
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  isUrgent: {
    type: Boolean,
    default: false
  },
  trackingEnabled: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Indexes for better query performance
certificateSchema.index({ applicationNumber: 1 });
certificateSchema.index({ certificateType: 1 });
certificateSchema.index({ status: 1 });
certificateSchema.index({ applicantId: 1 });
certificateSchema.index({ processingOfficer: 1 });
certificateSchema.index({ submissionDate: -1 });

// Generate application number
certificateSchema.pre('save', function(next) {
  if (this.isNew && !this.applicationNumber) {
    const year = new Date().getFullYear();
    const random = Math.floor(Math.random() * 1000000).toString().padStart(6, '0');
    this.applicationNumber = `CERT${year}${random}`;
  }
  next();
});

// Update status method
certificateSchema.methods.updateStatus = function(status, message, updatedBy, updatedByName) {
  this.status = status;
  this.updates.push({
    message: message,
    status: status,
    updatedBy: updatedBy,
    updatedByName: updatedByName
  });
  
  // Set delivery date if issued
  if (status === 'issued' && !this.actualDeliveryDate) {
    this.actualDeliveryDate = new Date();
  }
  
  return this.save();
};

// Generate verification code
certificateSchema.methods.generateVerificationCode = function() {
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  this.verificationCode = code;
  return code;
};

module.exports = mongoose.model('Certificate', certificateSchema);