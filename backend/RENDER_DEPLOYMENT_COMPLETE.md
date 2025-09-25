# Render Deployment for Civic Welfare Backend

## Deployment Steps

### 1. Environment Variables
Set these in Render dashboard:
```
MONGODB_URI=mongodb+srv://srivelan:srivelansrivelan@cluster0.rts6zvy.mongodb.net/civic_welfare?retryWrites=true&w=majority
NODE_ENV=production
JWT_SECRET=a7f3b8c2e9d1f4a6b8c3e7f2a9d4b6c8e1f5a3b7c9d2e6f8a1b4c7e9f2a5b8c1e4f7
JWT_EXPIRE=7d
PORT=10000
```

### 2. Build Command
```bash
npm install
```

### 3. Start Command
```bash
node server.js
```

### 4. Health Check URL
```
/api/health
```

## Auto-Deploy Configuration

### render.yaml (for automatic deployments)
```yaml
services:
  - type: web
    name: civic-welfare-backend
    env: node
    buildCommand: npm install
    startCommand: node server.js
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        fromService:
          type: web
          name: civic-welfare-backend
          property: port
```

## Post-Deployment

1. Update Flutter app with production URL
2. Test all API endpoints
3. Verify database connections
4. Check CORS settings

## Monitoring

- Health Check: `https://your-render-url.onrender.com/api/health`
- API Docs: `https://your-render-url.onrender.com/api/docs`
- Logs: Available in Render dashboard