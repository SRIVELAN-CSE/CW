# 🚀 Render.com Deployment Guide for Civic Welfare Backend

## Quick Deploy Button
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/your-username/civic-welfare-backend)

## Manual Deployment Steps

### 1. **Prepare Your Repository**
```bash
# Push your backend code to GitHub
git add .
git commit -m "Prepare for Render deployment"
git push origin main
```

### 2. **Create Render Service**
1. Go to [Render.com](https://render.com) and sign up/login
2. Click "New +" → "Web Service"
3. Connect your GitHub repository
4. Select your repository and branch (main)

### 3. **Configuration Settings**
- **Name**: `civic-welfare-sih`
- **Environment**: `Node`
- **Region**: Choose closest to your users
- **Branch**: `main`
- **Root Directory**: `backend`
- **Build Command**: `npm install`
- **Start Command**: `npm start`

### 4. **Environment Variables**
Add these environment variables in Render dashboard:

```
NODE_ENV=production
PORT=10000
MONGODB_URI=your_mongodb_atlas_connection_string
JWT_SECRET=your_super_secure_jwt_secret_key_here
JWT_REFRESH_SECRET=your_super_secure_refresh_secret_key_here
CORS_ORIGIN=*
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

### 5. **MongoDB Atlas Setup**
1. Create MongoDB Atlas account
2. Create new cluster (Free tier is fine)
3. Create database user
4. Whitelist all IP addresses (0.0.0.0/0) for production
5. Get connection string and add to MONGODB_URI

### 6. **Auto Deploy**
Once configured, Render will automatically deploy on every push to main branch.

## Your Deployment URL
After deployment, your backend will be available at:
`https://civic-welfare-sih.onrender.com`

## API Endpoints
- Health Check: `https://civic-welfare-sih.onrender.com/api/health`
- API Base: `https://civic-welfare-sih.onrender.com/api`

## Important Notes
- ✅ Free tier has 750 hours/month (enough for development)
- ✅ Auto-sleep after 15 minutes of inactivity
- ✅ Cold start time: 1-2 minutes when waking up
- ✅ Automatic HTTPS/SSL certificates
- ✅ Automatic deployments on git push

## Monitoring Your Deployment
- Check logs in Render dashboard
- Use health check endpoint to verify service status
- Monitor MongoDB Atlas for database connections

## Update Your Flutter App
After deployment, update the cloud server URL in:
`lib/config/server_config.dart`

Replace `https://civic-welfare-sih.onrender.com` with your actual Render URL.

## Testing Production Server
1. Switch to cloud server in your Flutter app
2. Test user registration and login
3. Create test reports
4. Verify data sync across multiple devices