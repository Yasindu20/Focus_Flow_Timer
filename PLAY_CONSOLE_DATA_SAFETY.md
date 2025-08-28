# Google Play Console Data Safety Form Information

## Data Collection Summary

### Personal Information

#### Account Info
- **Data Type:** Email addresses
- **Collection:** Yes
- **Sharing:** No
- **Purpose:** Account management and authentication
- **Optional/Required:** Required for app functionality
- **User Control:** Users can delete their account and all data

#### Name
- **Data Type:** Name (Display name)
- **Collection:** Yes (Optional)
- **Sharing:** No
- **Purpose:** Account personalization
- **Optional/Required:** Optional
- **User Control:** Users can modify or delete at any time

### App Activity

#### App Interactions
- **Data Type:** App interactions, in-app search history, installed apps, other user-generated content
- **Collection:** Yes
- **Sharing:** No
- **Purpose:** App functionality, personalization, and analytics
- **Optional/Required:** Required for core app features
- **User Control:** Users can view and delete their data

#### Other App Interactions
- **Data Type:** Timer sessions, task data, productivity goals
- **Collection:** Yes
- **Sharing:** No
- **Purpose:** Core app functionality - Pomodoro timer and productivity tracking
- **Optional/Required:** Required for app functionality
- **User Control:** Full data export and deletion available

### App Info and Performance

#### Crash Logs
- **Data Type:** Crash logs
- **Collection:** Yes
- **Sharing:** Yes (with Google Firebase)
- **Purpose:** App performance monitoring and bug fixes
- **Optional/Required:** Optional (users can opt out in settings)
- **User Control:** Can be disabled in app settings

#### Diagnostics
- **Data Type:** Other app performance data
- **Collection:** Yes
- **Sharing:** Yes (with Google Firebase)
- **Purpose:** App functionality improvement and analytics
- **Optional/Required:** Optional (users can opt out in settings)
- **User Control:** Can be disabled in app settings

### Device or Other IDs

#### Device or Other IDs
- **Data Type:** Device or other IDs
- **Collection:** Yes (Firebase App Instance ID)
- **Sharing:** Yes (with Google Firebase)
- **Purpose:** Analytics and app functionality
- **Optional/Required:** Required for Firebase services
- **User Control:** Automatically managed by Firebase

## Data Sharing Details

### Third-Party Sharing
- **Primary Service Provider:** Google Firebase/Google Cloud Platform
- **Data Shared:** Account information, app usage analytics, crash reports
- **Purpose:** Authentication, data storage, analytics, crash reporting
- **Data Encryption:** All data encrypted in transit and at rest

### No Selling of Data
- We do not sell user data to any third parties
- We do not share data for advertising purposes
- We do not provide data to data brokers

## Security Measures

### Encryption
- All data transmitted between app and servers uses TLS encryption
- User passwords are encrypted using industry-standard methods
- All data stored in Firebase is encrypted at rest

### Access Controls
- Strict authentication required for all data access
- Role-based access controls for development team
- Regular security audits and updates

### Data Deletion
- Complete account deletion removes all user data
- Automatic cleanup of temporary files and caches
- 30-day maximum retention after account deletion

## User Rights and Controls

### In-App Controls
- **Data Export:** Full GDPR-compliant data export functionality
- **Account Deletion:** Complete account and data deletion
- **Settings Control:** Granular control over data collection and sharing
- **Opt-out Options:** Users can disable analytics and crash reporting

### GDPR Compliance
- Right to access personal data
- Right to rectify inaccurate data
- Right to delete personal data
- Right to data portability
- Right to restrict processing
- Right to object to processing

## Data Retention

- **Active accounts:** Data retained while account is active and in use
- **Inactive accounts:** Data automatically deleted after 3 years of inactivity
- **Deleted accounts:** All data permanently deleted within 30 days
- **Analytics data:** Anonymized data retained for maximum 2 years
- **Crash logs:** Automatically deleted after 90 days

## Target Audience

- **Age Rating:** 3+ (All ages)
- **Children's Privacy:** No data collection from children under 13
- **COPPA Compliance:** App is not directed at children but is safe for all ages

## Geographic Considerations

- **Primary Markets:** Global availability
- **Data Processing Location:** Primarily United States (Google Firebase)
- **GDPR Compliance:** Full compliance for EU users
- **CCPA Compliance:** Full compliance for California residents

---

**Important Notes for Play Console Submission:**

1. **Sensitive Permissions:** The app requests SYSTEM_ALERT_WINDOW and REQUEST_IGNORE_BATTERY_OPTIMIZATIONS - see permission justifications document for detailed explanations.

2. **Firebase Integration:** All Firebase services used comply with Google's privacy standards and Play Console requirements.

3. **Regular Updates:** This data safety information will be updated if our data practices change, with users notified appropriately.

4. **Support Contact:** Users can contact support@focusflow.app for any data privacy concerns or questions.