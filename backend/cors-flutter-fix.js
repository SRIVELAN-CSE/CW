// CORS Fix for Flutter Web Development
// This script temporarily updates CORS to allow Flutter web connections

const express = require('express');
const cors = require('cors');

// More permissive CORS for Flutter web development
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    // Allow all localhost and 127.0.0.1 origins
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    
    // Allow production domains
    const allowedOrigins = [
      'https://civic-welfare-backend.onrender.com',
      'https://civic-welfare-frontend.onrender.com'
    ];
    
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: [
    'Content-Type', 
    'Authorization', 
    'Access-Control-Allow-Origin',
    'Access-Control-Allow-Headers',
    'Access-Control-Allow-Methods',
    'Access-Control-Allow-Credentials'
  ]
};

console.log('🔧 CORS Configuration for Flutter Web:');
console.log('✅ Allows all localhost origins');
console.log('✅ Allows all 127.0.0.1 origins');
console.log('✅ Supports credentials');
console.log('✅ Supports all standard methods');

module.exports = corsOptions;