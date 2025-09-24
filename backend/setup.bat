@echo off
echo Setting up Civic Welfare Backend...
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo Error: Node.js is not installed. Please install Node.js first.
    echo Download from: https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js is installed.
node --version

REM Check if npm is installed
npm --version >nul 2>&1
if errorlevel 1 (
    echo Error: npm is not installed.
    pause
    exit /b 1
)

echo npm is installed.
npm --version
echo.

REM Install dependencies
echo Installing dependencies...
npm install

if errorlevel 1 (
    echo Error: Failed to install dependencies.
    pause
    exit /b 1
)

echo Dependencies installed successfully.
echo.

REM Create necessary directories
echo Creating directories...
if not exist "uploads" mkdir uploads
if not exist "uploads\reports" mkdir uploads\reports
if not exist "uploads\certificates" mkdir uploads\certificates
if not exist "uploads\profiles" mkdir uploads\profiles
if not exist "uploads\documents" mkdir uploads\documents
if not exist "logs" mkdir logs

echo Directories created.
echo.

REM Check if .env file exists
if not exist ".env" (
    echo Creating .env file from template...
    copy .env.example .env
    echo.
    echo IMPORTANT: Please edit .env file with your configuration:
    echo - MongoDB connection string
    echo - JWT secrets
    echo - Email credentials
    echo - Other environment variables
    echo.
) else (
    echo .env file already exists.
)

REM Check MongoDB connection (optional)
echo.
echo To complete setup:
echo 1. Edit .env file with your MongoDB URI and other settings
echo 2. Run: npm run seed (to clear database and prepare for production)
echo 3. Run: npm run dev (to start development server)
echo.

echo Setup completed successfully!
echo.
echo Quick start commands:
echo   npm run dev     - Start development server
echo   npm run seed    - Clear database and prepare for production
echo   npm start       - Start production server
echo   npm test        - Run tests
echo.
pause