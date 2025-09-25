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
JWT_SECRET=a7f3b8c2e9d1f4a6b8c3e7f2a9d4b6c8e1f5a3b7c9d2e6f8a1b4c7e9f2a5b8c1e4f7
JWT_EXPIRE=7d
CORS_ORIGIN=https://civic-welfare-backend.onrender.com
EMAIL_SERVICE=gmail
EMAIL_USER=your-citivoice6@gmail.com
EMAIL_PASSWORD=CitiVoice@teamof6
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