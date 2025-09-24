const mongoose = require('mongoose');

const needRequestSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    trim: true,
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  category: {
    type: String,
    required: [true, 'Category is required'],
    enum: [
      'Financial Aid',
      'Medical Assistance',
      'Food Support',
      'Educational Support',
      'Housing Assistance',
      'Employment Help',
      'Disaster Relief',
      'Senior Care',
      'Child Welfare',
      'Disability Support',
      'Others'
    ]
  },
  urgencyLevel: {
    type: String,
    enum: ['Low', 'Medium', 'High', 'Critical'],
    default: 'Medium'
  },
  requesterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  requesterName: {
    type: String,
    required: true
  },
  requesterEmail: {
    type: String,
    required: true
  },
  requesterPhone: {
    type: String
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
  beneficiaryCount: {
    type: Number,
    min: 1,
    default: 1
  },
  estimatedCost: {
    type: Number,
    min: 0
  },
  status: {
    type: String,
    enum: ['submitted', 'under_review', 'approved', 'in_progress', 'fulfilled', 'rejected', 'closed'],
    default: 'submitted'
  },
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  assignedToName: {
    type: String
  },
  assignedAt: {
    type: Date
  },
  supportingDocuments: [{
    name: String,
    url: String,
    type: String
  }],
  verificationStatus: {
    type: String,
    enum: ['pending', 'verified', 'rejected'],
    default: 'pending'
  },
  verifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  verifiedAt: {
    type: Date
  },
  fulfillmentDetails: {
    fulfilledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    fulfilledByName: String,
    fulfilledAt: Date,
    actualCost: Number,
    notes: String
  },
  updates: [{
    message: String,
    updatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    updatedByName: String,
    status: String,
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  tags: [{
    type: String,
    trim: true
  }],
  isPublic: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Indexes for better query performance
needRequestSchema.index({ category: 1 });
needRequestSchema.index({ status: 1 });
needRequestSchema.index({ urgencyLevel: 1 });
needRequestSchema.index({ requesterId: 1 });
needRequestSchema.index({ assignedTo: 1 });
needRequestSchema.index({ createdAt: -1 });
needRequestSchema.index({ location: 'text', title: 'text', description: 'text' });

// Update status method
needRequestSchema.methods.updateStatus = function(status, message, updatedBy, updatedByName) {
  this.status = status;
  this.updates.push({
    message: message,
    status: status,
    updatedBy: updatedBy,
    updatedByName: updatedByName
  });
  
  return this.save();
};

// Assign to user method
needRequestSchema.methods.assignTo = function(userId, userName) {
  this.assignedTo = userId;
  this.assignedToName = userName;
  this.assignedAt = new Date();
  this.status = 'in_progress';
  
  return this.save();
};

module.exports = mongoose.model('NeedRequest', needRequestSchema);