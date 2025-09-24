# 🔧 Server Environment Switcher

This document explains how to easily switch between localhost development server and Render.com production server.

## 📍 **Current Configuration**
The app is currently configured to use: **Render.com Production Server**
- **Production URL**: `https://civic-welfare-backend.onrender.com/api`
- **Development URL**: `http://localhost:3000/api`

## 🔄 **How to Switch Servers**

### **Method 1: Quick Switch (Recommended)**
1. Open the file: `lib/core/config/environment_switcher.dart`
2. Find line 6: `static const String currentEnvironment = 'production';`
3. Change the value:
   - For **localhost**: `'development'`
   - For **Render.com**: `'production'`
4. Save the file and restart the Flutter app

### **Method 2: Manual Configuration**
Edit the `currentEnvironment` variable in `environment_switcher.dart`:

```dart
// For localhost development server
static const String currentEnvironment = 'development';

// For Render.com production server  
static const String currentEnvironment = 'production';
```

## 🖥️ **Server Configurations**

### **🏠 Development (Localhost)**
```
Environment: development
Base URL: http://localhost:3000/api
Socket URL: http://localhost:3000
Timeout: 10 seconds
```

**Requirements:**
- Node.js backend running on `localhost:3000`
- MongoDB connection available
- All backend services started locally

### **☁️ Production (Render.com)**
```
Environment: production
Base URL: https://civic-welfare-backend.onrender.com/api
Socket URL: https://civic-welfare-backend.onrender.com
Timeout: 15 seconds (longer for cloud latency)
```

**Features:**
- Deployed backend on Render.com
- MongoDB Atlas cloud database
- Production-ready configuration
- Automatic HTTPS

## 🔍 **Debug Information**

When running in debug mode, the app will print configuration details in the console:
```
🔧 ===== API CONFIGURATION =====
   Environment: production
   Server Name: Render.com Production
   Base URL: https://civic-welfare-backend.onrender.com/api
   Socket URL: https://civic-welfare-backend.onrender.com
   Timeout: 15s
   Production Mode: true
🔧 =============================
```

## ⚠️ **Important Notes**

1. **Backend Requirements:**
   - Make sure your chosen backend server is running
   - For localhost: Start with `npm run dev` in the backend folder
   - For Render.com: Service should be deployed and accessible

2. **CORS Configuration:**
   - Backend is configured to accept requests from both environments
   - Production server allows Flutter web deployment

3. **Database:**
   - Both environments use MongoDB Atlas cloud database
   - Same data across development and production

4. **Hot Restart Required:**
   - After changing the environment, restart the Flutter app
   - Configuration is loaded at app startup

## 🚀 **Testing Connection**

After switching environments, test the connection:

1. **Login Test**: Try logging in with any user account
2. **API Test**: Check console for successful API calls  
3. **Real-time Test**: Test notifications and real-time features

## 🛠️ **Troubleshooting**

### **Common Issues:**
- **Connection failed**: Check if backend server is running
- **CORS errors**: Verify backend CORS configuration
- **Timeout errors**: Check network connection and server status

### **Backend Status Check:**
- **Localhost**: Visit `http://localhost:3000/api/health`
- **Render.com**: Visit `https://civic-welfare-backend.onrender.com/api/health`

Both should return: `{"status":"OK","timestamp":"...","environment":"..."}`

---
**💡 Quick Switch Summary:**
1. Edit `lib/core/config/environment_switcher.dart`
2. Change `currentEnvironment` to `'development'` or `'production'`
3. Restart Flutter app
4. Test connection with login