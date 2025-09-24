# 🧪 Certificate Generation Testing Guide

## Test Steps to Verify Certificate Generation

### Step 1: Create a Citizen Account
1. Open the app
2. Go to "Register New User" 
3. Create account: `testcitizen@example.com` / `citizen` role
4. Login as citizen

### Step 2: Submit a Test Report
1. Click "Submit New Report"
2. Fill out report details:
   - **Title**: "Test Infrastructure Issue"
   - **Category**: "Infrastructure" (should award 20 points)
   - **Description**: "Testing certificate generation"
   - **Location**: "Test Location"
3. Submit the report
4. Note the Report ID

### Step 3: Switch to Officer Account
1. Logout from citizen account
2. Login as officer: `testofficer@example.com` / `officer` role
3. Go to officer dashboard
4. Find the submitted report

### Step 4: Mark Report as Done
1. Click on the test report
2. Change status from "Submitted" to "Done"
3. Save the changes
4. **Look for debug logs** in browser console:
   ```
   🔍 [CERTIFICATE DEBUG] Checking certificate generation conditions
   🏆 [CERTIFICATE] Conditions met! Generating certificate...
   🎉 Certificate generated and notification sent...
   ```

### Step 5: Verify Certificate Generation
1. Logout from officer account
2. Login back as citizen: `testcitizen@example.com`
3. Go to "My Certificates" section
4. Check if certificate appears
5. Verify certificate details:
   - Report title matches
   - Points awarded: 20 (for Infrastructure)
   - Certificate shows government branding

### Expected Results
- ✅ Certificate should be automatically generated when status changes to "Done"
- ✅ Certificate should appear in citizen's "My Certificates" section
- ✅ Certificate should award 20 points for Infrastructure category
- ✅ Citizen should receive notification about certificate

### Debug Information to Check
- Browser console logs for certificate generation
- localStorage data for certificates
- Notification creation
- Report status update confirmation

### If Certificates Don't Appear
1. Check browser console for error messages
2. Verify localStorage has certificate data:
   ```javascript
   // In browser console:
   localStorage.getItem('civic_welfare_certificates')
   ```
3. Check if report status actually changed to "Done"
4. Verify user session is correct (citizen who submitted report)

### Common Issues
- **Status not changing**: Officer might not have permission to update
- **Wrong user session**: Certificate generated for wrong user
- **localStorage issues**: Data not persisting between sessions
- **Status comparison bug**: Original vs updated status not comparing correctly

## 🔍 Debugging Commands

### Check localStorage Data
```javascript
// Check reports
console.log('Reports:', JSON.parse(localStorage.getItem('civic_welfare_reports') || '[]'));

// Check certificates
console.log('Certificates:', JSON.parse(localStorage.getItem('civic_welfare_certificates') || '[]'));

// Check current user session
console.log('User Session:', JSON.parse(localStorage.getItem('civic_welfare_user_session') || 'null'));
```

### Clear Data for Fresh Test
```javascript
// Clear all app data
localStorage.removeItem('civic_welfare_reports');
localStorage.removeItem('civic_welfare_certificates');
localStorage.removeItem('civic_welfare_user_session');
localStorage.removeItem('civic_welfare_notifications');
```