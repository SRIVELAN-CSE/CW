// Flutter API Compatibility Fixes
// This script fixes the data format issues between Flutter frontend and Node.js backend

const express = require('express');
const router = express.Router();

// Fix 1: Add a Flutter-compatible reports endpoint that returns direct array
// @route   GET /api/reports/flutter
// @desc    Get reports in Flutter-compatible format (direct array)
// @access  Public
router.get('/flutter', async (req, res) => {
  try {
    const Report = require('../models/Report');
    
    const reports = await Report.find()
      .populate('reporterId', 'name email')
      .populate('assignedOfficerId', 'name email department')
      .sort({ createdAt: -1 })
      .limit(50); // Limit for performance

    // Return direct array for Flutter compatibility
    res.json(reports);
  } catch (error) {
    console.error('Get Flutter reports error:', error);
    res.status(500).json({
      error: 'Failed to fetch reports',
      message: error.message
    });
  }
});

// Fix 2: Add debug endpoint for registration testing
// @route   POST /api/debug/test-registration
// @desc    Test registration with detailed logging
// @access  Public
router.post('/test-registration', async (req, res) => {
  try {
    const RegistrationRequest = require('../models/RegistrationRequest');
    
    console.log('🧪 Debug Registration Test');
    console.log('📥 Request Body:', JSON.stringify(req.body, null, 2));
    console.log('📥 Request Headers:', JSON.stringify(req.headers, null, 2));
    
    // Create registration request with detailed logging
    const registrationData = {
      name: req.body.name,
      email: req.body.email,
      phone: req.body.phone,
      userType: req.body.userType || req.body.user_type,
      location: req.body.location,
      department: req.body.department,
      reason: req.body.reason || `Debug test registration for ${req.body.userType || req.body.user_type}`
    };
    
    console.log('💾 Saving to database:', JSON.stringify(registrationData, null, 2));
    
    const registrationRequest = await RegistrationRequest.create(registrationData);
    
    console.log('✅ Registration saved successfully:', registrationRequest._id);
    
    res.json({
      success: true,
      message: 'Debug registration test successful',
      data: registrationRequest
    });
    
  } catch (error) {
    console.error('❌ Debug registration error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error
    });
  }
});

module.exports = router;