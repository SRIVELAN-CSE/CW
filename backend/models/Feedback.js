const mongoose = require('mongoose');

const feedbackSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['service_feedback', 'app_feedback', 'officer_rating', 'general_suggestion', 'complaint'],
    required: true
  },
  rating: {
    type: Number,
    min: 1,
    max: 5,
    required: function() {
      return this.type === 'service_feedback' || this.type === 'officer_rating';
    }
  },
  title: {
    type: String,
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  message: {
    type: String,
    required: [true, 'Message is required'],
    trim: true,
    maxlength: [2000, 'Message cannot exceed 2000 characters']
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  userName: {
    type: String,
    required: true
  },
  userEmail: {
    type: String,
    required: true
  },
  relatedId: {
    type: mongoose.Schema.Types.ObjectId,
    refPath: 'relatedModel'
  },
  relatedModel: {
    type: String,
    enum: ['Report', 'Certificate', 'NeedRequest', 'User']
  },
  category: {
    type: String,
    enum: [
      'User Experience',
      'Performance',
      'Feature Request',
      'Bug Report',
      'Service Quality',
      'Officer Performance',
      'Response Time',
      'Resolution Quality',
      'Others'
    ],
    default: 'Others'
  },
  status: {
    type: String,
    enum: ['submitted', 'acknowledged', 'under_review', 'resolved', 'closed'],
    default: 'submitted'
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High'],
    default: 'Medium'
  },
  isAnonymous: {
    type: Boolean,
    default: false
  },
  attachments: [{
    name: String,
    url: String,
    type: String
  }],
  response: {
    message: String,
    respondedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    respondedByName: String,
    respondedAt: Date
  },
  tags: [{
    type: String,
    trim: true
  }],
  isPublic: {
    type: Boolean,
    default: false
  },
  helpfulVotes: {
    type: Number,
    default: 0
  },
  votedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }]
}, {
  timestamps: true
});

// Indexes for better query performance
feedbackSchema.index({ type: 1 });
feedbackSchema.index({ rating: 1 });
feedbackSchema.index({ status: 1 });
feedbackSchema.index({ category: 1 });
feedbackSchema.index({ userId: 1 });
feedbackSchema.index({ createdAt: -1 });
feedbackSchema.index({ title: 'text', message: 'text' });

// Add response method
feedbackSchema.methods.addResponse = function(message, respondedBy, respondedByName) {
  this.response = {
    message: message,
    respondedBy: respondedBy,
    respondedByName: respondedByName,
    respondedAt: new Date()
  };
  this.status = 'resolved';
  
  return this.save();
};

// Vote helpful method
feedbackSchema.methods.voteHelpful = function(userId) {
  if (!this.votedBy.includes(userId)) {
    this.votedBy.push(userId);
    this.helpfulVotes += 1;
    return this.save();
  }
  return Promise.resolve(this);
};

module.exports = mongoose.model('Feedback', feedbackSchema);