const express = require('express');
const router = express.Router();

const Certificate = require('../models/Certificate');
const Notification = require('../models/Notification');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, certificateSchemas } = require('../middleware/validation');

// @route   GET /api/certificates
// @desc    Get certificates with filtering
// @access  Private
router.get('/', authenticate, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      certificateType,
      status,
      priority,
      applicantId,
      sort = 'submissionDate',
      order = 'desc'
    } = req.query;

    let filter = {};

    // Admins and officers can see all, users can only see their own
    if (req.user.userType === 'public') {
      filter.applicantId = req.user._id;
    }

    if (certificateType) filter.certificateType = certificateType;
    if (status) filter.status = status;
    if (priority) filter.priority = priority;
    if (applicantId && req.user.userType !== 'public') filter.applicantId = applicantId;

    const skip = (page - 1) * parseInt(limit);
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    const certificates = await Certificate.find(filter)
      .populate('applicantId', 'name email phone')
      .populate('processingOfficer', 'name email')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const totalCertificates = await Certificate.countDocuments(filter);

    res.json({
      success: true,
      data: {
        certificates,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalCertificates / parseInt(limit)),
          totalCertificates
        }
      }
    });
  } catch (error) {
    console.error('Get certificates error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch certificates'
    });
  }
});

// @route   POST /api/certificates/anonymous
// @desc    Apply for a new certificate (anonymous users)
// @access  Public
router.post('/anonymous', validate(certificateSchemas.create), async (req, res) => {
  try {
    const {
      certificateType,
      applicantName,
      applicantEmail,
      applicantPhone,
      applicationDetails,
      priority = 'Normal',
      supportingDocuments = []
    } = req.body;

    console.log('📜 Anonymous certificate application:', {
      certificateType,
      applicantName,
      applicantEmail: applicantEmail ? '***' + applicantEmail.slice(-10) : 'not provided'
    });

    // Generate application number
    const applicationNumber = certificateType.substring(0, 2).toUpperCase() + Date.now();

    const certificateData = {
      certificateType,
      applicantName: applicantName || 'Anonymous',
      applicantEmail: applicantEmail || 'anonymous@example.com',
      applicantPhone: applicantPhone || 'Not provided',
      applicationDetails,
      applicationNumber,
      priority,
      supportingDocuments,
      status: 'submitted',
      // Calculate expected delivery (7 days for Normal, 3 days for Urgent)
      expectedDeliveryDate: new Date(Date.now() + (priority === 'Urgent' ? 3 : 7) * 24 * 60 * 60 * 1000)
    };

    const certificate = await Certificate.create(certificateData);
    console.log('✅ Anonymous certificate application created:', certificate._id);

    // Create notification for admins
    const adminUsers = await User.find({ userType: 'admin' });
    
    for (const admin of adminUsers) {
      await Notification.create({
        title: 'New Certificate Application',
        message: `New ${certificateType} application from ${applicantName}`,
        type: 'system_alert',
        userId: admin._id,
        relatedId: certificate._id,
        relatedModel: 'Certificate',
        priority: priority === 'Urgent' ? 'high' : 'medium'
      });
    }

    res.status(201).json({
      success: true,
      message: 'Certificate application submitted successfully',
      data: {
        applicationId: certificate._id,
        applicationNumber: certificate.applicationNumber,
        certificateType: certificate.certificateType,
        status: certificate.status,
        expectedDelivery: certificate.expectedDeliveryDate
      }
    });

  } catch (error) {
    console.error('❌ Anonymous certificate application error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit certificate application. Please try again.',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// @route   POST /api/certificates
// @desc    Apply for a new certificate (authenticated users)
// @access  Private
router.post('/', authenticate, validate(certificateSchemas.create), async (req, res) => {
  try {
    const certificateData = {
      ...req.body,
      applicantId: req.user._id,
      applicantName: req.user.name,
      applicantEmail: req.user.email,
      applicantPhone: req.user.phone
    };

    // Set expected delivery date (7-14 days from now)
    const expectedDays = req.body.priority === 'Very Urgent' ? 3 : 
                        req.body.priority === 'Urgent' ? 7 : 14;
    certificateData.expectedDeliveryDate = new Date(Date.now() + expectedDays * 24 * 60 * 60 * 1000);

    const certificate = await Certificate.create(certificateData);

    // Notify admins
    const adminUsers = await require('../models/User').find({ userType: 'admin' });
    
    for (const admin of adminUsers) {
      await Notification.create({
        title: 'New Certificate Application',
        message: `New ${certificate.certificateType} application from ${certificate.applicantName}`,
        type: 'system_alert',
        userId: admin._id,
        relatedId: certificate._id,
        relatedModel: 'Certificate',
        priority: certificate.priority === 'Very Urgent' ? 'high' : 'medium'
      });
    }

    res.status(201).json({
      success: true,
      message: 'Certificate application submitted successfully',
      data: { 
        certificate,
        applicationNumber: certificate.applicationNumber,
        expectedDeliveryDate: certificate.expectedDeliveryDate
      }
    });
  } catch (error) {
    console.error('Create certificate application error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit certificate application'
    });
  }
});

// @route   GET /api/certificates/:id
// @desc    Get single certificate
// @access  Private
router.get('/:id', authenticate, async (req, res) => {
  try {
    const certificate = await Certificate.findById(req.params.id)
      .populate('applicantId', 'name email phone')
      .populate('processingOfficer', 'name email')
      .populate('updates.updatedBy', 'name');

    if (!certificate) {
      return res.status(404).json({
        success: false,
        message: 'Certificate not found'
      });
    }

    // Check access permissions
    const canView = 
      certificate.applicantId._id.toString() === req.user._id.toString() ||
      req.user.userType === 'admin' ||
      req.user.userType === 'officer';

    if (!canView) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: { certificate }
    });
  } catch (error) {
    console.error('Get certificate error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch certificate'
    });
  }
});

// @route   PUT /api/certificates/:id/status
// @desc    Update certificate status
// @access  Private (Admin/Officer only)
router.put('/:id/status', authenticate, authorize('admin', 'officer'), async (req, res) => {
  try {
    const { status, message, certificateUrl } = req.body;

    const certificate = await Certificate.findById(req.params.id);

    if (!certificate) {
      return res.status(404).json({
        success: false,
        message: 'Certificate not found'
      });
    }

    // Update certificate
    await certificate.updateStatus(status, message, req.user._id, req.user.name);

    // If issuing certificate, add URL and generate verification code
    if (status === 'issued' && certificateUrl) {
      certificate.certificateUrl = certificateUrl;
      certificate.verificationCode = certificate.generateVerificationCode();
      await certificate.save();
    }

    // Create notification for applicant
    await Notification.create({
      title: 'Certificate Status Updated',
      message: `Your ${certificate.certificateType} application status: ${status}`,
      type: 'system_alert',
      userId: certificate.applicantId,
      relatedId: certificate._id,
      relatedModel: 'Certificate'
    });

    res.json({
      success: true,
      message: 'Certificate status updated successfully',
      data: { certificate }
    });
  } catch (error) {
    console.error('Update certificate status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update certificate status'
    });
  }
});

// @route   GET /api/certificates/track/:applicationNumber
// @desc    Track certificate by application number
// @access  Public
router.get('/track/:applicationNumber', async (req, res) => {
  try {
    const certificate = await Certificate.findOne({ 
      applicationNumber: req.params.applicationNumber 
    }).select('applicationNumber certificateType status submissionDate expectedDeliveryDate updates');

    if (!certificate) {
      return res.status(404).json({
        success: false,
        message: 'Certificate application not found'
      });
    }

    res.json({
      success: true,
      data: { certificate }
    });
  } catch (error) {
    console.error('Track certificate error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to track certificate'
    });
  }
});

module.exports = router;