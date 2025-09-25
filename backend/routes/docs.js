const express = require('express');
const router = express.Router();

// API Documentation Route
router.get('/', (req, res) => {
  const apiDocs = {
    "title": "CivicWelfare API Documentation",
    "version": "1.0.0",
    "description": "Complete API documentation for the CivicWelfare platform",
    "baseUrl": `${req.protocol}://${req.get('host')}/api`,
    "endpoints": {
      "authentication": {
        "register": {
          "method": "POST",
          "path": "/api/auth/register",
          "description": "Register a new user",
          "body": {
            "name": "string (required)",
            "email": "string (required)",
            "phone": "string (required)",
            "password": "string (required)",
            "confirmPassword": "string (required)",
            "userType": "string (required: 'public', 'officer', 'admin')",
            "location": "string (required)",
            "department": "string (optional, required for officers)"
          },
          "response": {
            "success": "boolean",
            "message": "string",
            "data": {
              "user": "object",
              "access_token": "string (for public users)"
            }
          }
        },
        "login": {
          "method": "POST",
          "path": "/api/auth/login",
          "description": "Login user",
          "body": {
            "email": "string (required)",
            "password": "string (required)"
          },
          "response": {
            "success": "boolean",
            "message": "string",
            "data": {
              "user": "object",
              "access_token": "string"
            }
          }
        },
        "profile": {
          "method": "GET",
          "path": "/api/auth/me",
          "description": "Get current user profile",
          "headers": {
            "Authorization": "Bearer <token>"
          },
          "response": {
            "success": "boolean",
            "data": {
              "user": "object"
            }
          }
        }
      },
      "reports": {
        "create": {
          "method": "POST",
          "path": "/api/reports",
          "description": "Create a new report",
          "headers": {
            "Authorization": "Bearer <token>"
          },
          "body": {
            "title": "string (required)",
            "description": "string (required)",
            "category": "string (required)",
            "location": "string (required)",
            "address": "string (required)",
            "latitude": "number (optional)",
            "longitude": "number (optional)",
            "priority": "string ('low', 'medium', 'high')"
          }
        },
        "getAll": {
          "method": "GET",
          "path": "/api/reports",
          "description": "Get all reports",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        },
        "getById": {
          "method": "GET",
          "path": "/api/reports/:id",
          "description": "Get specific report by ID",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        },
        "update": {
          "method": "PUT",
          "path": "/api/reports/:id",
          "description": "Update report",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        }
      },
      "users": {
        "profile": {
          "method": "GET",
          "path": "/api/users/profile",
          "description": "Get user profile",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        },
        "updateProfile": {
          "method": "PUT",
          "path": "/api/users/profile",
          "description": "Update user profile",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        },
        "getAllUsers": {
          "method": "GET",
          "path": "/api/users",
          "description": "Get all users (admin only)",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        }
      },
      "certificates": {
        "apply": {
          "method": "POST",
          "path": "/api/certificates",
          "description": "Apply for certificate",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        },
        "getUserCertificates": {
          "method": "GET",
          "path": "/api/certificates",
          "description": "Get user certificates",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        }
      },
      "notifications": {
        "getAll": {
          "method": "GET",
          "path": "/api/notifications",
          "description": "Get user notifications",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        },
        "markAsRead": {
          "method": "PUT",
          "path": "/api/notifications/:id/read",
          "description": "Mark notification as read",
          "headers": {
            "Authorization": "Bearer <token>"
          }
        }
      }
    },
    "statusCodes": {
      "200": "Success",
      "201": "Created",
      "400": "Bad Request",
      "401": "Unauthorized",
      "403": "Forbidden",
      "404": "Not Found",
      "500": "Internal Server Error"
    },
    "authentication": {
      "type": "Bearer Token",
      "header": "Authorization: Bearer <your-jwt-token>",
      "note": "Include the JWT token received from login in the Authorization header"
    }
  };

  res.json(apiDocs);
});

module.exports = router;