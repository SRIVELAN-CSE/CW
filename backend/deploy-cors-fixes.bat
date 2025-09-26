@echo off
echo 🚀 Deploying CORS fixes to Render...

REM Check if there are changes to commit
git status --porcelain > temp_status.txt
for /f %%i in (temp_status.txt) do set changes=%%i
del temp_status.txt

if defined changes (
    echo 📝 Committing CORS configuration updates...
    
    git add .env server.js
    git commit -m "Fix CORS configuration for Flutter development ports - Add Flutter development server ports to CORS_ORIGIN - Update server.js CORS configuration to be more permissive - Include common Flutter ports: 60548, 60257, 9101 - Support both localhost and 127.0.0.1 variations - This fixes the frontend connection issues"
    
    echo ⬆️ Pushing changes to trigger Render deployment...
    git push origin main
    
    echo ✅ Changes pushed successfully!
    echo ⏳ Render will redeploy automatically (takes ~2-3 minutes)
    echo.
    echo 🔍 Monitor deployment at: https://dashboard.render.com
    echo 🏥 Test health after deployment: https://civic-welfare-backend.onrender.com/api/health
) else (
    echo ✅ No changes detected. Repository is up to date.
)

echo.
echo 📋 Next steps:
echo 1. Wait for Render deployment to complete (~2-3 minutes)
echo 2. Test the Flutter app connection again
echo 3. The CORS errors should be resolved

pause