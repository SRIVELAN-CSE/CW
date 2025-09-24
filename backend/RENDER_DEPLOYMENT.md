# Render.com Configuration for CivicWelfare Backend

## Deployment Settings
- **Service Name**: civic-welfare-backend
- **Environment**: Node.js
- **Build Command**: npm install
- **Start Command**: npm start
- **Root Directory**: backend
- **Port**: 10000 (Render default)

## Required Environment Variables
Set these in Render dashboard:

```
NODE_ENV=production
PORT=10000
MONGODB_URI=mongodb+srv://srivelansv2006_db_user:9YxxIF6TGmNQEsNg@civic-welfare-cluster.rts6zvy.mongodb.net/civic_welfare?retryWrites=true&w=majority&appName=civic-welfare-cluster
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
CORS_ORIGIN=https://your-frontend-domain.com
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-specific-password
```

## Health Check
- **Path**: /api/health
- **Expected Response**: 200 OK with JSON status

## Auto-Deploy
- **Trigger**: On commit to main branch
- **Build Filter**: Include backend/** only

## Notes
- Render automatically sets PORT environment variable
- MongoDB Atlas connection should work out of the box
- Update CORS_ORIGIN after frontend deployment
- Configure email credentials for notifications