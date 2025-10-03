#!/bin/bash

echo "🚀 Deploying CORS fix to Render..."
echo "📡 Backend URL: https://civic-welfare-backend.onrender.com"

# Add changes to git
git add .
git commit -m "Fix CORS for Flutter web development - allow all localhost origins"

# Push to main branch (this will trigger Render deployment)
git push origin main

echo "✅ CORS fix deployed!"
echo "🔄 Render will automatically redeploy the backend"
echo "⏱️ Deployment usually takes 2-3 minutes"
echo ""
echo "📋 What was fixed:"
echo "   ✅ Allow all localhost origins (any port)"
echo "   ✅ Allow all 127.0.0.1 origins (any port)" 
echo "   ✅ Support for Flutter web development"
echo "   ✅ Maintain production security"
echo ""
echo "🧪 Test the fix:"
echo "   1. Wait 2-3 minutes for deployment"
echo "   2. Run: flutter run -d chrome"
echo "   3. Check browser console for connection success"
echo ""
echo "🌐 Monitor deployment at: https://dashboard.render.com"