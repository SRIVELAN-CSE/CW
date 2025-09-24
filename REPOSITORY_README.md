# CivicWelfare - Complete Civic Issue Reporting & Resolution System

A comprehensive **Flutter mobile application** with **Node.js backend** for crowdsourced civic issue reporting and resolution. This system enables citizens to report civic problems, government officers to manage issues, and administrators to oversee the entire process.

## 🚀 **Project Overview**

**CivicWelfare** is a full-stack solution designed for Smart India Hackathon (SIH) that bridges the gap between citizens and local government authorities for efficient civic issue management.

### **Key Features**
- 📱 **Cross-platform Flutter app** (Android, iOS, Web)
- 🗄️ **Node.js backend** with MongoDB Atlas
- 🔐 **Role-based authentication** (Public, Officer, Admin)
- 📸 **Photo capture & AI analysis** for issue classification
- 📍 **GPS location services** for precise issue reporting
- 🔔 **Real-time notifications** with Socket.IO
- 📧 **Email services** for communication
- 📊 **Analytics dashboard** for admins
- 🎯 **Smart categorization** of civic issues

## 🏗️ **Architecture**

### **Frontend (Flutter)**
- **Framework**: Flutter 3.x
- **State Management**: Provider pattern
- **Navigation**: GoRouter
- **Local Storage**: SQLite + SharedPreferences
- **HTTP Client**: Custom API service
- **Camera**: image_picker
- **Maps**: geolocator, geocoding

### **Backend (Node.js)**
- **Runtime**: Node.js ≥16.0.0
- **Framework**: Express.js 4.x
- **Database**: MongoDB Atlas
- **ODM**: Mongoose 8.x
- **Authentication**: JWT + bcryptjs
- **File Upload**: Multer + Cloudinary
- **Real-time**: Socket.IO
- **Email**: Nodemailer
- **Security**: Helmet, CORS, Rate Limiting

## 📦 **Tech Stack**

### **Frontend Dependencies**
```yaml
flutter_sdk: 3.x
cupertino_icons: ^1.0.8
provider: ^6.1.1
http: ^1.2.0
shared_preferences: ^2.2.2
sqflite: ^2.3.0
image_picker: ^1.0.7
geolocator: ^12.0.0
geocoding: ^3.0.0
go_router: ^14.8.1
intl: ^0.19.0
```

### **Backend Dependencies**
```json
{
  "express": "^4.18.2",
  "mongoose": "^8.0.3",
  "jsonwebtoken": "^9.0.2",
  "bcryptjs": "^2.4.3",
  "multer": "^1.4.5-lts.1",
  "nodemailer": "^6.9.7",
  "socket.io": "^4.7.4",
  "helmet": "^7.1.0",
  "cors": "^2.8.5",
  "joi": "^17.11.0"
}
```

## 🔧 **Installation & Setup**

### **Prerequisites**
- Flutter SDK 3.0+
- Node.js 16.0+
- MongoDB Atlas account
- Git

### **1. Clone Repository**
```bash
git clone https://github.com/SRIVELAN-CSE/CW.git
cd CW
```

### **2. Flutter Frontend Setup**
```bash
# Install Flutter dependencies
flutter pub get

# Run code generation (if needed)
flutter packages pub run build_runner build

# Check for issues
flutter doctor
flutter analyze
```

### **3. Backend Setup**
```bash
cd backend

# Install Node.js dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your configurations
# - MongoDB Atlas connection string
# - JWT secrets
# - Email credentials
# - Other service keys
```

### **4. Environment Configuration**

**Backend `.env` file:**
```properties
# Database
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/civic_welfare

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRE=7d

# Email
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# Server
PORT=3000
NODE_ENV=development
```

**Flutter API Configuration:**
Update `lib/services/backend_api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api'; // Development
// static const String baseUrl = 'https://your-domain.com/api'; // Production
```

## 🚀 **Running the Application**

### **Start Backend Server**
```bash
cd backend

# Development mode with auto-restart
npm run dev

# Or production mode
npm start

# The server will run on http://localhost:3000
```

### **Run Flutter App**
```bash
# Android/iOS
flutter run

# Web
flutter run -d chrome

# Specific device
flutter devices
flutter run -d <device-id>
```

## 👥 **User Roles & Access**

### **🙋‍♀️ Public Users**
- Register and create profiles
- Report civic issues with photos/location
- Track report status
- Request need certificates
- Rate and provide feedback

### **👮‍♂️ Government Officers**
- Manage assigned reports
- Update issue status
- Issue certificates
- Communicate with citizens

### **👨‍💼 Administrators**
- Manage all users and reports
- Approve officer registrations
- Generate analytics
- System-wide oversight

## 📱 **Features**

### **Core Functionality**
- ✅ **User Authentication** - Secure JWT-based login
- ✅ **Issue Reporting** - Photo, location, description
- ✅ **Status Tracking** - Real-time updates
- ✅ **Smart Classification** - AI-powered categorization
- ✅ **Certificate Management** - Digital certificates
- ✅ **Notifications** - Push & email notifications
- ✅ **Analytics** - Reports and insights
- ✅ **Multi-platform** - Android, iOS, Web support

### **Advanced Features**
- 🎯 **AI Image Analysis** - Automatic issue detection
- 📍 **GPS Integration** - Precise location mapping
- 🔄 **Real-time Updates** - Live status changes
- 📊 **Dashboard Analytics** - Comprehensive insights
- 🎮 **Gamification** - User engagement system
- 📱 **Offline Support** - Local data storage

## 🗄️ **Database Schema**

### **Main Collections (MongoDB)**
- **Users** - User profiles and authentication
- **Reports** - Civic issue reports
- **Certificates** - Digital certificates
- **Notifications** - System notifications
- **Feedback** - User feedback and ratings
- **NeedRequests** - Certificate requests
- **RegistrationRequests** - Officer approvals

## 🔒 **Security Features**
- JWT authentication with refresh tokens
- Password hashing with bcryptjs
- Rate limiting to prevent abuse
- Input validation with Joi
- CORS protection
- Security headers with Helmet
- File upload restrictions

## 📋 **API Documentation**

### **Authentication Endpoints**
```
POST /api/auth/register     - User registration
POST /api/auth/login        - User login
POST /api/auth/refresh      - Refresh token
POST /api/auth/logout       - User logout
```

### **Report Endpoints**
```
GET    /api/reports         - Get all reports
POST   /api/reports         - Create new report
GET    /api/reports/:id     - Get specific report
PUT    /api/reports/:id     - Update report
DELETE /api/reports/:id     - Delete report
```

*Full API documentation available in `/backend/README.md`*

## 🧪 **Testing**

### **Flutter Tests**
```bash
# Run all tests
flutter test

# Run specific tests
flutter test test/widget_test.dart

# Generate coverage
flutter test --coverage
```

### **Backend Tests**
```bash
cd backend

# Run tests
npm test

# Run with coverage
npm run test:coverage
```

## 🚀 **Deployment**

### **Flutter Deployment**
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### **Backend Deployment**
- Deploy to services like Heroku, AWS, Digital Ocean
- Use PM2 for process management
- Configure reverse proxy with Nginx
- Set up SSL certificates

## 📁 **Project Structure**
```
CW/
├── lib/                    # Flutter source code
│   ├── core/              # Core services & utilities
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── services/          # API & database services
│   └── widgets/           # Reusable widgets
├── backend/               # Node.js backend
│   ├── config/           # Database configuration
│   ├── middleware/       # Express middleware
│   ├── models/           # MongoDB models
│   ├── routes/           # API routes
│   ├── services/         # Business logic
│   └── utils/            # Utility functions
├── android/              # Android platform files
├── ios/                  # iOS platform files
├── web/                  # Web platform files
└── test/                 # Test files
```

## 🤝 **Contributing**
1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 **License**
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 **Development Team**
- **Lead Developer**: SRIVELAN CSE
- **Project Type**: Smart India Hackathon (SIH) Project
- **Institution**: [Your Institution Name]

## 📞 **Support**
For support and queries:
- 📧 Email: [your-email@domain.com]
- 💬 GitHub Issues: [Create Issue](https://github.com/SRIVELAN-CSE/CW/issues)

## 🔗 **Links**
- 🌐 **Live Demo**: [Coming Soon]
- 📱 **Play Store**: [Coming Soon]
- 🍎 **App Store**: [Coming Soon]

---
**Built with ❤️ for Smart India Hackathon 2025**