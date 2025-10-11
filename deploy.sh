#!/bin/bash

# 🚀 Civic Welfare SIH - Render Deployment Script
echo "🚀 Starting Civic Welfare Backend Deployment..."

# Navigate to backend directory
cd backend

echo "📦 Installing dependencies..."
npm install --production

echo "🔧 Setting up environment..."
# Environment variables will be set in Render dashboard

echo "🗄️ Setting up database..."
# MongoDB Atlas connection will be established via MONGODB_URI

echo "✅ Deployment preparation complete!"
echo "🌐 Starting server..."

# Start the server
npm start