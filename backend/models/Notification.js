const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  // Recipient Information
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  userType: {
    type: String,
    enum: ['citizen', 'officer', 'admin'],
    required: true
  },
  
  // Notification Content
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  message: {
    type: String,
    required: [true, 'Message is required'],
    trim: true,
    maxlength: [500, 'Message cannot exceed 500 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  
  // Notification Type and Category
  type: {
    type: String,
    enum: {
      values: [
        'report_status_update',
        'report_assignment',
        'report_created',
        'report_resolved',
        'registration_approved',
        'registration_rejected',
        'password_reset_approved',
        'password_reset_rejected',
        'system_announcement',
        'maintenance_alert',
        'emergency_alert',
        'feedback_request',
        'certificate_ready',
        'general'
      ],
      message: 'Invalid notification type'
    },
    required: true
  },
  category: {
    type: String,
    enum: ['system', 'report', 'account', 'emergency', 'info'],
    required: true
  },
  
  // Priority and Urgency
  priority: {
    type: String,
    enum: {
      values: ['low', 'medium', 'high', 'critical'],
      message: 'Invalid priority level'
    },
    default: 'medium'
  },
  isUrgent: {
    type: Boolean,
    default: false
  },
  
  // Status and Interaction
  isRead: {
    type: Boolean,
    default: false
  },
  readAt: {
    type: Date
  },
  isArchived: {
    type: Boolean,
    default: false
  },
  archivedAt: {
    type: Date
  },
  
  // Related Entities
  relatedEntities: {
    reportId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Report'
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    registrationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RegistrationRequest'
    },
    passwordResetId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PasswordResetRequest'
    },
    certificateId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Certificate'
    }
  },
  
  // Action Information
  actionable: {
    type: Boolean,
    default: false
  },
  actionButtons: [{
    label: {
      type: String,
      required: true
    },
    action: {
      type: String,
      required: true
    },
    url: String,
    style: {
      type: String,
      enum: ['primary', 'secondary', 'success', 'warning', 'danger'],
      default: 'primary'
    }
  }],
  
  // Delivery Information
  deliveryChannels: {
    inApp: {
      type: Boolean,
      default: true
    },
    email: {
      type: Boolean,
      default: false
    },
    sms: {
      type: Boolean,
      default: false
    },
    push: {
      type: Boolean,
      default: false
    }
  },
  
  // Delivery Status
  deliveryStatus: {
    inApp: {
      delivered: { type: Boolean, default: false },
      deliveredAt: Date,
      error: String
    },
    email: {
      delivered: { type: Boolean, default: false },
      deliveredAt: Date,
      error: String
    },
    sms: {
      delivered: { type: Boolean, default: false },
      deliveredAt: Date,
      error: String
    },
    push: {
      delivered: { type: Boolean, default: false },
      deliveredAt: Date,
      error: String
    }
  },
  
  // Additional Data
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  metadata: {
    source: String,
    version: String,
    deviceType: String,
    ipAddress: String
  },
  
  // Scheduling
  scheduledFor: {
    type: Date
  },
  expiresAt: {
    type: Date
  },
  
  // Sender Information
  sender: {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    name: String,
    type: {
      type: String,
      enum: ['system', 'admin', 'officer', 'citizen'],
      default: 'system'
    }
  },
  
  // Grouping and Threading
  groupId: {
    type: String // For grouping related notifications
  },
  threadId: {
    type: String // For conversation threading
  },
  parentNotificationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Notification'
  },
  
  // Analytics
  clickCount: {
    type: Number,
    default: 0
  },
  lastClickedAt: {
    type: Date
  },
  
  // Bulk Notification Support
  isBulk: {
    type: Boolean,
    default: false
  },
  bulkId: {
    type: String
  },
  totalRecipients: {
    type: Number
  },
  
  // Retry and Error Handling
  retryCount: {
    type: Number,
    default: 0
  },
  maxRetries: {
    type: Number,
    default: 3
  },
  lastError: {
    type: String
  }

}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better performance
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userType: 1 });
notificationSchema.index({ type: 1 });
notificationSchema.index({ category: 1 });
notificationSchema.index({ priority: 1 });
notificationSchema.index({ isRead: 1 });
notificationSchema.index({ isArchived: 1 });
notificationSchema.index({ scheduledFor: 1 });
notificationSchema.index({ expiresAt: 1 });
notificationSchema.index({ bulkId: 1 });
notificationSchema.index({ groupId: 1 });

// Compound indexes
notificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });
notificationSchema.index({ type: 1, priority: 1 });

// Virtual for notification age
notificationSchema.virtual('ageInMinutes').get(function() {
  return Math.floor((new Date() - this.createdAt) / (1000 * 60));
});

// Virtual for expiry status
notificationSchema.virtual('isExpired').get(function() {
  return this.expiresAt && new Date() > this.expiresAt;
});

// Virtual for delivery summary
notificationSchema.virtual('deliverySummary').get(function() {
  const channels = ['inApp', 'email', 'sms', 'push'];
  const delivered = channels.filter(ch => 
    this.deliveryChannels[ch] && this.deliveryStatus[ch]?.delivered
  ).length;
  const total = channels.filter(ch => this.deliveryChannels[ch]).length;
  
  return { delivered, total, percentage: total > 0 ? (delivered / total) * 100 : 0 };
});

// Pre-save middleware
notificationSchema.pre('save', function(next) {
  // Set expiry date if not set (default 30 days)
  if (!this.expiresAt && this.isNew) {
    this.expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  }
  
  // Set delivery status timestamps
  if (this.isRead && !this.readAt) {
    this.readAt = new Date();
  }
  
  if (this.isArchived && !this.archivedAt) {
    this.archivedAt = new Date();
  }
  
  next();
});

// Static method to mark as read
notificationSchema.statics.markAsRead = async function(notificationIds, userId) {
  return await this.updateMany(
    { 
      _id: { $in: notificationIds }, 
      userId: userId,
      isRead: false 
    },
    { 
      isRead: true, 
      readAt: new Date() 
    }
  );
};

// Static method to archive notifications
notificationSchema.statics.archiveOldNotifications = async function(daysOld = 30) {
  const cutoffDate = new Date(Date.now() - daysOld * 24 * 60 * 60 * 1000);
  return await this.updateMany(
    { 
      createdAt: { $lt: cutoffDate },
      isArchived: false 
    },
    { 
      isArchived: true, 
      archivedAt: new Date() 
    }
  );
};

// Static method to get notification statistics
notificationSchema.statics.getNotificationStats = async function(userId) {
  const stats = await this.aggregate([
    { $match: { userId: mongoose.Types.ObjectId(userId) } },
    {
      $group: {
        _id: null,
        total: { $sum: 1 },
        unread: { $sum: { $cond: ['$isRead', 0, 1] } },
        urgent: { $sum: { $cond: ['$isUrgent', 1, 0] } },
        byType: { 
          $push: { 
            type: '$type', 
            isRead: '$isRead' 
          } 
        }
      }
    }
  ]);
  
  return stats[0] || { total: 0, unread: 0, urgent: 0, byType: [] };
};

// Instance method to mark as clicked
notificationSchema.methods.recordClick = function() {
  this.clickCount += 1;
  this.lastClickedAt = new Date();
  return this.save();
};

// Instance method to update delivery status
notificationSchema.methods.updateDeliveryStatus = function(channel, delivered, error = null) {
  if (this.deliveryStatus[channel]) {
    this.deliveryStatus[channel].delivered = delivered;
    this.deliveryStatus[channel].deliveredAt = delivered ? new Date() : null;
    this.deliveryStatus[channel].error = error;
  }
  return this.save();
};

module.exports = mongoose.model('Notification', notificationSchema);