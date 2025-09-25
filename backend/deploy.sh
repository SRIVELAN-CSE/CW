#!/bin/bash

# Civic Welfare Backend - Render Deployment Script
echo "🚀 Deploying Civic Welfare Backend to Render..."

# 1. Install dependencies
echo "📦 Installing dependencies..."
npm install

# 2. Check environment variables
echo "🔧 Checking environment variables..."
if [ -z "$MONGODB_URI" ]; then
    echo "❌ MONGODB_URI environment variable is not set!"
    exit 1
fi

if [ -z "$JWT_SECRET" ]; then
    echo "❌ JWT_SECRET environment variable is not set!"
    exit 1
fi

# 3. Test database connection
echo "🔍 Testing database connection..."
node -e "
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('✅ Database connection successful');
    process.exit(0);
  })
  .catch((err) => {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1);
  });
"

# 4. Start the server
echo "🌐 Starting server..."
exec node server.js