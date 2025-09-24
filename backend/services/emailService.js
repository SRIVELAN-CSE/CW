const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');

class EmailService {
  constructor() {
    this.transporter = null;
    this.initializeTransporter();
  }

  initializeTransporter() {
    try {
      this.transporter = nodemailer.createTransporter({
        service: process.env.EMAIL_SERVICE || 'gmail',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASSWORD
        }
      });
    } catch (error) {
      console.error('Email transporter initialization failed:', error);
    }
  }

  async sendEmail(to, subject, html, attachments = []) {
    if (!this.transporter) {
      console.error('Email transporter not initialized');
      return false;
    }

    try {
      const mailOptions = {
        from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
        to,
        subject,
        html,
        attachments
      };

      const result = await this.transporter.sendMail(mailOptions);
      console.log('Email sent successfully:', result.messageId);
      return true;
    } catch (error) {
      console.error('Email sending failed:', error);
      return false;
    }
  }

  async sendWelcomeEmail(user) {
    const subject = 'Welcome to Civic Welfare Platform';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2196F3;">Welcome to Civic Welfare Platform!</h2>
        <p>Dear ${user.name},</p>
        <p>Thank you for registering with our Civic Welfare Platform. Your account has been successfully created.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3>Account Details:</h3>
          <p><strong>Name:</strong> ${user.name}</p>
          <p><strong>Email:</strong> ${user.email}</p>
          <p><strong>User Type:</strong> ${user.userType}</p>
          <p><strong>Location:</strong> ${user.location}</p>
        </div>
        <p>You can now log in to the platform and start reporting civic issues or accessing services based on your user type.</p>
        <p>If you have any questions, please don't hesitate to contact our support team.</p>
        <p>Best regards,<br>Civic Welfare Team</p>
      </div>
    `;

    return await this.sendEmail(user.email, subject, html);
  }

  async sendPasswordResetEmail(user, resetToken) {
    const subject = 'Password Reset Request';
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
    
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #FF5722;">Password Reset Request</h2>
        <p>Dear ${user.name},</p>
        <p>We received a request to reset your password for your Civic Welfare Platform account.</p>
        <p>Click the button below to reset your password:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" style="background-color: #2196F3; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a>
        </div>
        <p>Or copy and paste this link in your browser:</p>
        <p style="word-break: break-all; background-color: #f5f5f5; padding: 10px; border-radius: 3px;">${resetUrl}</p>
        <p style="color: #666; font-size: 14px;">This link will expire in 1 hour for security reasons.</p>
        <p>If you didn't request this password reset, please ignore this email.</p>
        <p>Best regards,<br>Civic Welfare Team</p>
      </div>
    `;

    return await this.sendEmail(user.email, subject, html);
  }

  async sendReportStatusUpdateEmail(report, user) {
    const subject = `Report Status Updated: ${report.title}`;
    const statusColors = {
      'submitted': '#FFC107',
      'acknowledged': '#2196F3',
      'in_progress': '#FF9800',
      'resolved': '#4CAF50',
      'rejected': '#F44336'
    };

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2196F3;">Report Status Update</h2>
        <p>Dear ${user.name},</p>
        <p>The status of your report has been updated.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3>Report Details:</h3>
          <p><strong>Title:</strong> ${report.title}</p>
          <p><strong>Category:</strong> ${report.category}</p>
          <p><strong>Location:</strong> ${report.location}</p>
          <p><strong>Status:</strong> <span style="color: ${statusColors[report.status]}; font-weight: bold;">${report.status.toUpperCase()}</span></p>
          ${report.assignedOfficerName ? `<p><strong>Assigned Officer:</strong> ${report.assignedOfficerName}</p>` : ''}
          ${report.officerComments ? `<p><strong>Officer Comments:</strong> ${report.officerComments}</p>` : ''}
        </div>
        <p>You can view more details about your report by logging into the platform.</p>
        <p>Thank you for helping us improve our community!</p>
        <p>Best regards,<br>Civic Welfare Team</p>
      </div>
    `;

    return await this.sendEmail(user.email, subject, html);
  }

  async sendCertificateStatusEmail(certificate, user) {
    const subject = `Certificate Application Status: ${certificate.certificateType}`;
    const statusColors = {
      'pending': '#FFC107',
      'under_review': '#2196F3',
      'approved': '#4CAF50',
      'rejected': '#F44336'
    };

    let statusMessage = '';
    switch (certificate.status) {
      case 'approved':
        statusMessage = 'Congratulations! Your certificate application has been approved.';
        break;
      case 'rejected':
        statusMessage = 'We regret to inform you that your certificate application has been rejected.';
        break;
      case 'under_review':
        statusMessage = 'Your certificate application is currently under review.';
        break;
      default:
        statusMessage = 'Your certificate application status has been updated.';
    }

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2196F3;">Certificate Application Update</h2>
        <p>Dear ${user.name},</p>
        <p>${statusMessage}</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3>Application Details:</h3>
          <p><strong>Certificate Type:</strong> ${certificate.certificateType}</p>
          <p><strong>Application ID:</strong> ${certificate.applicationId}</p>
          <p><strong>Status:</strong> <span style="color: ${statusColors[certificate.status]}; font-weight: bold;">${certificate.status.toUpperCase()}</span></p>
          <p><strong>Applied Date:</strong> ${new Date(certificate.createdAt).toLocaleDateString()}</p>
          ${certificate.verificationCode && certificate.status === 'approved' ? `<p><strong>Verification Code:</strong> ${certificate.verificationCode}</p>` : ''}
          ${certificate.adminComments ? `<p><strong>Comments:</strong> ${certificate.adminComments}</p>` : ''}
        </div>
        ${certificate.status === 'approved' ? '<p>You can now download your certificate from the platform.</p>' : ''}
        <p>For any queries, please contact our support team.</p>
        <p>Best regards,<br>Civic Welfare Team</p>
      </div>
    `;

    return await this.sendEmail(user.email, subject, html);
  }

  async sendOfficerAssignmentEmail(officer, report) {
    const subject = `New Report Assignment: ${report.title}`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2196F3;">New Report Assignment</h2>
        <p>Dear ${officer.name},</p>
        <p>A new report has been assigned to you for resolution.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3>Report Details:</h3>
          <p><strong>Title:</strong> ${report.title}</p>
          <p><strong>Category:</strong> ${report.category}</p>
          <p><strong>Priority:</strong> ${report.priority}</p>
          <p><strong>Location:</strong> ${report.location}</p>
          <p><strong>Description:</strong> ${report.description}</p>
          <p><strong>Reported by:</strong> ${report.reporterName}</p>
          <p><strong>Reporter Contact:</strong> ${report.reporterPhone}</p>
        </div>
        <p>Please log in to the platform to view complete details and take appropriate action.</p>
        <p>Best regards,<br>Civic Welfare Team</p>
      </div>
    `;

    return await this.sendEmail(officer.email, subject, html);
  }

  async sendBulkNotificationEmail(users, subject, message) {
    const results = [];
    for (const user of users) {
      const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2196F3;">Civic Welfare Platform Notification</h2>
          <p>Dear ${user.name},</p>
          <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
            ${message}
          </div>
          <p>Best regards,<br>Civic Welfare Team</p>
        </div>
      `;
      
      const result = await this.sendEmail(user.email, subject, html);
      results.push({ email: user.email, sent: result });
    }
    return results;
  }
}

module.exports = new EmailService();