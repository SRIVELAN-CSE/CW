"""
Civic Welfare Management System - Backend API

This is the MongoDB backend for the Flutter civic welfare application.
It provides REST API endpoints for managing users, reports, notifications, 
registration requests, and password reset requests.

Features:
- MongoDB Atlas database
- FastAPI for REST endpoints
- JWT authentication
- Real-time notifications support

Usage:
    python main.py

API Documentation:
    http://localhost:8000/docs
"""

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from datetime import datetime
import os
from dotenv import load_dotenv

# TODO: Add MongoDB imports and routes when implementing MongoDB integration
# from motor.motor_asyncio import AsyncIOMotorClient
# from api.routes import users, reports, notifications, auth

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="Civic Welfare Management API",
    description="Backend API for Flutter civic welfare application with MongoDB Atlas",
    version="2.0.0",
    contact={
        "name": "Civic Welfare Team",
        "email": "support@civicwelfare.com",
    },
)

# Setup CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual Flutter app origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# TODO: Initialize MongoDB connection
# mongodb_url = os.getenv("MONGODB_URL", "your_mongodb_atlas_connection_string")
# client = AsyncIOMotorClient(mongodb_url)
# database = client.civic_welfare

# TODO: Include routers when implementing MongoDB integration
# app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
# app.include_router(users.router, prefix="/api/users", tags=["Users"])
# app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
# app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications"])

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Civic Welfare Management API",
        "version": "2.0.0",
        "documentation": "/docs",
        "status": "running",
        "database": "MongoDB Atlas (pending implementation)"
    }

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    # TODO: Add MongoDB connection health check
    return {
        "status": "healthy",
        "database": "MongoDB Atlas (pending implementation)",
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    # Run the application
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
        reload=True,  # Set to False in production
        log_level="info"
    )