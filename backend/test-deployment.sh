# API Testing Commands for Your Deployed Service
# Testing civic-welfare-backend deployment on Render

# 1. Health Check
curl https://civic-welfare-backend.onrender.com/api/health

# 2. API Documentation  
curl https://civic-welfare-backend.onrender.com/api/docs

# 3. Test Admin Login
curl -X POST https://civic-welfare-backend.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@civicwelfare.com","password":"CivicAdmin2024!"}'

# Expected Responses:
# Health: {"status":"healthy","database":"connected",...}
# Docs: Full API documentation HTML/JSON
# Login: {"success":true,"message":"Login successful","data":{...}}