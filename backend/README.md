# Civic Welfare Backend - Node.js

A comprehensive Node.js backend for the Civic Welfare Platform, providing robust APIs for civic issue reporting, user management, real-time notifications, and administrative functions.

## 🚀 Features

- **Multi-User System**: Support for public users, officers, and administrators
- **Issue Reporting**: Complete civic issue reporting and tracking system
- **Real-time Notifications**: Socket.io powered real-time updates
- **Certificate Management**: Digital certificate application and processing
- **File Upload**: Secure file upload with validation and storage
- **Email Services**: Automated email notifications and communications
- **JWT Authentication**: Secure token-based authentication system
- **MongoDB Integration**: Robust database operations with Mongoose ODM
- **Rate Limiting**: Protection against API abuse
- **Comprehensive Validation**: Input validation and sanitization

## 🛠️ Technology Stack

- **Runtime**: Node.js (v16+)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JSON Web Tokens (JWT)
- **Real-time**: Socket.io
- **Email**: Nodemailer
- **File Upload**: Multer
- **Security**: Helmet, CORS, Rate Limiting
- **Validation**: Express Validator

## 📁 Project Structure

```
backend/
├── config/
│   └── database.js          # Database configuration
├── middleware/
│   ├── auth.js              # Authentication middleware
│   ├── authorization.js     # Role-based authorization
│   ├── errorHandler.js      # Error handling middleware
│   ├── uploadMiddleware.js  # File upload configuration
│   └── validation.js        # Input validation rules
├── models/
│   ├── User.js              # User data model
│   ├── Report.js            # Issue report model
│   ├── Certificate.js       # Certificate model
│   ├── Notification.js      # Notification model
│   ├── NeedRequest.js       # Need request model
│   ├── Feedback.js          # Feedback model
│   ├── RegistrationRequest.js
│   └── PasswordResetRequest.js
├── routes/
│   ├── auth.js              # Authentication routes
│   ├── users.js             # User management routes
│   ├── reports.js           # Report management routes
│   ├── certificates.js      # Certificate processing routes
│   ├── notifications.js     # Notification routes
│   ├── needRequests.js      # Need request routes
│   ├── feedback.js          # Feedback routes
│   ├── registrations.js     # Registration management
│   └── passwordReset.js     # Password reset functionality
├── services/
│   └── emailService.js      # Email service functions
├── utils/
│   └── databaseUtils.js     # Database utility functions
├── scripts/
│   └── seedDatabase.js      # Database seeding script
├── uploads/                 # File upload directory
├── logs/                    # Application logs
├── server.js                # Main application file
├── package.json             # Dependencies and scripts
└── .env.example             # Environment variables template
```

## 🔧 Installation & Setup

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- MongoDB Atlas account or local MongoDB installation

### 1. Clone and Navigate

```bash
cd backend
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Configuration

Copy the environment template:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Database
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/civic_welfare

# JWT Secrets
JWT_SECRET=your-super-secret-jwt-key
JWT_REFRESH_SECRET=your-refresh-secret-key

# Email Configuration
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# URLs
FRONTEND_URL=http://localhost:8080
API_BASE_URL=http://localhost:3000
```

### 4. Database Setup

Seed the database with initial data:

```bash
npm run seed
```

This prepares the database:
- Clears any existing data
- Sets up database structure
- *Note: Sample data creation has been disabled for production use*

### 5. Start the Server

Development mode with auto-restart:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - User logout

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `GET /api/users` - Get all users (admin only)
- `PUT /api/users/:id/status` - Update user status (admin)

### Reports
- `GET /api/reports` - Get all reports
- `POST /api/reports` - Create new report
- `GET /api/reports/:id` - Get specific report
- `PUT /api/reports/:id` - Update report
- `PUT /api/reports/:id/assign` - Assign to officer

### Certificates
- `POST /api/certificates` - Apply for certificate
- `GET /api/certificates` - Get user certificates
- `PUT /api/certificates/:id/process` - Process application (admin)
- `GET /api/certificates/verify/:code` - Verify certificate

### Notifications
- `GET /api/notifications` - Get user notifications
- `PUT /api/notifications/:id/read` - Mark as read
- `POST /api/notifications/broadcast` - Send broadcast (admin)

## 🔐 Authentication & Authorization

The system uses JWT-based authentication with role-based access control:

### User Types
- **public**: Can report issues, apply for certificates
- **officer**: Can manage assigned reports, update status
- **admin**: Full system access, user management

### Protected Routes
Routes are protected using middleware that verifies JWT tokens and user roles.

## 📁 File Upload System

Supports file uploads for:
- Report images (5MB max, 5 files)
- Certificate documents (10MB max, 3 files)
- Profile pictures (5MB max, 1 file)

Files are stored in organized directories with unique naming to prevent conflicts.

## 🔄 Real-time Features

Socket.io implementation provides:
- Real-time report status updates
- Live notification delivery
- Officer assignment notifications
- System-wide announcements

## 📧 Email System

Automated email notifications for:
- Welcome messages for new users
- Report status updates
- Certificate application updates
- Password reset requests
- Officer assignment notifications

## 🛡️ Security Features

- JWT token authentication
- Password hashing with bcrypt
- Rate limiting to prevent abuse
- Input validation and sanitization
- CORS protection
- Helmet security headers
- MongoDB injection protection

## 🧪 Testing

Run tests:
```bash
npm test
```

Run with coverage:
```bash
npm run test:coverage
```

## 📊 Database Management

### Health Check
```bash
GET /api/health/database
```

### Statistics
```bash
GET /api/health/stats
```

### Cleanup
The system includes utilities for:
- Cleaning old notifications
- File cleanup
- Data integrity validation

## 🚀 Deployment

### Environment Variables for Production

Ensure these are set in production:

```env
NODE_ENV=production
JWT_SECRET=very-long-random-production-secret
MONGODB_URI=your-production-mongodb-uri
EMAIL_USER=your-production-email
FRONTEND_URL=https://your-frontend-domain.com
```

### PM2 Deployment (Recommended)

```bash
npm install -g pm2
pm2 start server.js --name "civic-welfare-backend"
pm2 startup
pm2 save
```

## 🔍 Monitoring & Logging

- Application logs are stored in `/logs` directory
- Morgan HTTP request logging
- Error tracking and reporting
- Health check endpoints for monitoring

## 🤝 API Integration with Flutter Frontend

The backend is specifically designed to work with the Flutter frontend:

- **Matching Models**: All data models exactly match Flutter app requirements
- **Consistent Response Format**: Standardized API response structure
- **Real-time Sync**: Socket.io events match Flutter expectations
- **File Upload Compatibility**: Supports Flutter file upload patterns

## 📱 Flutter Integration Points

### Backend API Service
The Flutter app uses `backend_api_service.dart` which expects:
- Bearer token authentication
- RESTful endpoint structure
- JSON response format
- Proper error handling

### Database Service
Matches `database_service.dart` functionality for:
- Local data caching
- Offline support compatibility
- Data synchronization

## 🐛 Troubleshooting

### Common Issues

1. **MongoDB Connection Failed**
   - Check MONGODB_URI in .env
   - Ensure MongoDB Atlas IP whitelist includes your IP
   - Verify database credentials

2. **JWT Token Errors**
   - Ensure JWT_SECRET is set and consistent
   - Check token expiration settings
   - Verify authentication middleware

3. **File Upload Issues**
   - Check file size limits
   - Ensure upload directories exist
   - Verify file type restrictions

4. **Email Not Sending**
   - Configure EMAIL_USER and EMAIL_PASSWORD
   - Enable 2-factor authentication and app passwords for Gmail
   - Check email service settings

## 📋 Development Guidelines

- Follow RESTful API conventions
- Use proper HTTP status codes
- Implement comprehensive error handling
- Write descriptive commit messages
- Add comments for complex logic
- Validate all inputs
- Use environment variables for configuration

## 🔄 Version History

- **v1.0.0**: Initial release with complete backend functionality
- Full CRUD operations for all entities
- Real-time notifications
- File upload system
- Email services
- Comprehensive authentication and authorization

## 👥 Team

Developed for the Smart India Hackathon (SIH) project by the Civic Welfare development team.

## 📄 License

This project is licensed under the MIT License.