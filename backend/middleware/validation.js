const Joi = require('joi');

// Validation middleware factory
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        details: error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message
        }))
      });
    }
    
    next();
  };
};

// User validation schemas
const userSchemas = {
  register: Joi.object({
    name: Joi.string().trim().min(2).max(100).required(),
    email: Joi.string().email().lowercase().required(),
    phone: Joi.string().pattern(/^\+?[\d\s-()]{10,15}$/).required(),
    password: Joi.string().min(6).required(),
    userType: Joi.string().valid('public', 'officer').default('public'),
    location: Joi.string().trim().allow(''),
    department: Joi.string().valid('garbageCollection', 'drainage', 'roadMaintenance', 'streetLights', 'waterSupply', 'others').when('userType', {
      is: 'officer',
      then: Joi.required(),
      otherwise: Joi.optional()
    }),
    reason: Joi.string().trim().max(500).allow('')
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),

  update: Joi.object({
    name: Joi.string().trim().min(2).max(100),
    phone: Joi.string().pattern(/^\+?[\d\s-()]{10,15}$/),
    location: Joi.string().trim().allow(''),
    department: Joi.string().valid('garbageCollection', 'drainage', 'roadMaintenance', 'streetLights', 'waterSupply', 'others'),
    profileImageUrl: Joi.string().uri().allow('')
  })
};

// Report validation schemas
const reportSchemas = {
  create: Joi.object({
    title: Joi.string().trim().max(200).required(),
    description: Joi.string().trim().max(2000).required(),
    category: Joi.string().valid(
      'Garbage Collection',
      'Road Maintenance',
      'Street Lights',
      'Water Supply',
      'Drainage',
      'Public Safety',
      'Noise Pollution',
      'Infrastructure',
      'Environment',
      'Health & Sanitation',
      'Traffic',
      'Others'
    ).required(),
    location: Joi.string().trim().required(),
    address: Joi.string().trim().allow(''),
    latitude: Joi.number().min(-90).max(90),
    longitude: Joi.number().min(-180).max(180),
    priority: Joi.string().valid('Low', 'Medium', 'High', 'Critical').default('Medium'),
    imageUrls: Joi.array().items(Joi.string().uri()),
    videoUrls: Joi.array().items(Joi.string().uri()),
    tags: Joi.array().items(Joi.string().trim())
  }),

  update: Joi.object({
    title: Joi.string().trim().max(200),
    description: Joi.string().trim().max(2000),
    status: Joi.string().valid('submitted', 'acknowledged', 'in_progress', 'resolved', 'closed'),
    priority: Joi.string().valid('Low', 'Medium', 'High', 'Critical'),
    assignedOfficerId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
    estimatedResolutionTime: Joi.string().trim(),
    tags: Joi.array().items(Joi.string().trim())
  })
};

// Certificate validation schemas
const certificateSchemas = {
  create: Joi.object({
    certificateType: Joi.string().valid(
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
    ).required(),
    applicationDetails: Joi.object({
      fullName: Joi.string().required(),
      dateOfBirth: Joi.date(),
      gender: Joi.string().valid('Male', 'Female', 'Other'),
      fatherName: Joi.string(),
      motherName: Joi.string(),
      address: Joi.string(),
      pincode: Joi.string().pattern(/^\d{6}$/),
      purpose: Joi.string().required(),
      additionalInfo: Joi.object()
    }).required(),
    priority: Joi.string().valid('Normal', 'Urgent', 'Very Urgent').default('Normal'),
    supportingDocuments: Joi.array().items(Joi.object({
      name: Joi.string().required(),
      url: Joi.string().uri().required(),
      type: Joi.string().required(),
      required: Joi.boolean().default(false)
    }))
  })
};

// Need Request validation schemas
const needRequestSchemas = {
  create: Joi.object({
    title: Joi.string().trim().max(200).required(),
    description: Joi.string().trim().max(2000).required(),
    category: Joi.string().valid(
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
    ).required(),
    urgencyLevel: Joi.string().valid('Low', 'Medium', 'High', 'Critical').default('Medium'),
    location: Joi.string().trim().required(),
    address: Joi.string().trim().allow(''),
    beneficiaryCount: Joi.number().min(1).default(1),
    estimatedCost: Joi.number().min(0),
    supportingDocuments: Joi.array().items(Joi.object({
      name: Joi.string().required(),
      url: Joi.string().uri().required(),
      type: Joi.string().required()
    })),
    tags: Joi.array().items(Joi.string().trim())
  })
};

// Feedback validation schemas
const feedbackSchemas = {
  create: Joi.object({
    type: Joi.string().valid('service_feedback', 'app_feedback', 'officer_rating', 'general_suggestion', 'complaint').required(),
    rating: Joi.number().min(1).max(5).when('type', {
      is: Joi.string().valid('service_feedback', 'officer_rating'),
      then: Joi.required(),
      otherwise: Joi.optional()
    }),
    title: Joi.string().trim().max(200),
    message: Joi.string().trim().max(2000).required(),
    relatedId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
    relatedModel: Joi.string().valid('Report', 'Certificate', 'NeedRequest', 'User'),
    category: Joi.string().valid(
      'User Experience',
      'Performance',
      'Feature Request',
      'Bug Report',
      'Service Quality',
      'Officer Performance',
      'Response Time',
      'Resolution Quality',
      'Others'
    ).default('Others'),
    priority: Joi.string().valid('Low', 'Medium', 'High').default('Medium'),
    isAnonymous: Joi.boolean().default(false),
    attachments: Joi.array().items(Joi.object({
      name: Joi.string().required(),
      url: Joi.string().uri().required(),
      type: Joi.string().required()
    })),
    tags: Joi.array().items(Joi.string().trim())
  })
};

// Password reset validation schemas
const passwordResetSchemas = {
  create: Joi.object({
    email: Joi.string().email().required(),
    userType: Joi.string().valid('public', 'officer', 'admin').required(),
    reason: Joi.string().trim().max(500).allow('')
  }),

  update: Joi.object({
    status: Joi.string().valid('pending', 'approved', 'rejected', 'completed').required(),
    reviewNotes: Joi.string().trim().max(1000).allow(''),
    newPassword: Joi.string().min(6).when('status', {
      is: 'approved',
      then: Joi.required(),
      otherwise: Joi.optional()
    })
  })
};

module.exports = {
  validate,
  userSchemas,
  reportSchemas,
  certificateSchemas,
  needRequestSchemas,
  feedbackSchemas,
  passwordResetSchemas
};