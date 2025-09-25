# URL Replacement Instructions for Flutter App

## File to Edit: 
lib/core/config/environment_switcher.dart

## Lines to Update: 
Lines 19-20 in the 'production' ServerConfig

## Current Code:
```dart
'production': ServerConfig(
  name: 'Render.com Production', 
  baseUrl: 'https://YOUR_ACTUAL_RENDER_URL.onrender.com/api',      // ← Replace this line
  socketUrl: 'https://YOUR_ACTUAL_RENDER_URL.onrender.com',        // ← Replace this line
  timeout: 15,
  description: 'Live cloud server',
  icon: '☁️',
),
```

## After Getting Your Render URL, Update To:
```dart
'production': ServerConfig(
  name: 'Render.com Production', 
  baseUrl: 'https://YOUR_RENDER_URL_HERE.onrender.com/api',        // ← Your actual URL + /api
  socketUrl: 'https://YOUR_RENDER_URL_HERE.onrender.com',          // ← Your actual URL
  timeout: 15,
  description: 'Live cloud server',
  icon: '☁️',
),
```

## Example (if your Render URL is https://civic-welfare-backend-xyz123.onrender.com):
```dart
'production': ServerConfig(
  name: 'Render.com Production', 
  baseUrl: 'https://civic-welfare-backend-xyz123.onrender.com/api',
  socketUrl: 'https://civic-welfare-backend-xyz123.onrender.com',
  timeout: 15,
  description: 'Live cloud server',
  icon: '☁️',
),
```

## Important Notes:
- baseUrl should end with '/api'
- socketUrl should NOT end with '/api'
- Both URLs should use 'https://' (not 'http://')
- Don't include trailing slashes