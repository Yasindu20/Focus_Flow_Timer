# Analytics & Insights Engine Setup Guide

## Overview
This guide will help you integrate the Analytics & Insights Engine into your Focus Flow Timer app. The engine provides comprehensive analytics, goal tracking, and data export capabilities using Firebase Firestore.

## 🚀 Quick Setup

### 1. Dependencies
The required dependencies are already added to `pubspec.yaml`. Run:
```bash
flutter pub get
```

### 2. Provider Registration
Add the `AnalyticsDashboardProvider` to your main.dart:

```dart
// In your main.dart file
import 'package:provider/provider.dart';
import 'providers/analytics_dashboard_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // ... your existing providers
        ChangeNotifierProvider(create: (_) => AnalyticsDashboardProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

### 3. Navigation Integration
Add the analytics screen to your navigation:

```dart
// In your navigation/routing file
import 'screens/analytics_dashboard_screen.dart';

// Add route
'/analytics': (context) => const AnalyticsDashboardScreen(),

// Or add navigation button
IconButton(
  icon: Icon(Icons.analytics),
  onPressed: () => Navigator.pushNamed(context, '/analytics'),
)
```

### 4. Session Recording Integration
Integrate session recording with your existing timer logic:

```dart
// In your timer completion logic
import 'package:firebase_auth/firebase_auth.dart';
import 'models/session_analytics.dart';
import 'providers/analytics_dashboard_provider.dart';

// When a session completes
void onSessionComplete(DateTime startTime, DateTime endTime, int durationMinutes, bool completed) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final session = SessionAnalytics(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      status: completed ? 'completed' : 'interrupted',
    );
    
    // Record the session
    final analyticsProvider = Provider.of<AnalyticsDashboardProvider>(context, listen: false);
    await analyticsProvider.recordSession(session);
  }
}
```

### 5. Firebase Setup
1. Deploy the updated Firestore rules:
```bash
firebase deploy --only firestore:rules
```

2. (Optional) Import sample data for testing:
   - Go to Firebase Console → Firestore Database
   - Use the Import/Export feature to import `firestore_seed_data.json`

## 📊 Features Overview

### 1. Daily/Weekly/Monthly Reports
- **Daily Sessions Chart**: Bar chart showing sessions over the last 7 days
- **Weekly Progress Chart**: Line chart tracking hours over 4 weeks  
- **Monthly Overview**: Pie chart showing completion vs interruption rates

### 2. Focus Patterns
- **Hourly Heatmap**: Visual representation of productive hours
- **Peak Focus Time**: Identifies most productive hour of the day
- **Time-based Insights**: Morning, afternoon, evening productivity analysis

### 3. Streak Tracking
- **Consecutive Days**: Tracks daily focus consistency
- **Visual Badges**: Milestone indicators for motivation
- **Streak Messages**: Encouraging feedback based on progress

### 4. Efficiency Metrics
- **Completion Rate**: Percentage of completed vs interrupted sessions
- **Circular Progress**: Visual efficiency indicator with color coding
- **Improvement Suggestions**: Context-aware feedback messages

### 5. Goal Setting
- **Daily Sessions Target**: Set daily session goals
- **Weekly Hours Target**: Set weekly time goals
- **Progress Tracking**: Real-time progress indicators
- **Personalized Recommendations**: Smart goal suggestions

### 6. Data Export
- **CSV Export**: Detailed session data with summary statistics
- **PDF Reports**: Professional analytics reports
- **Local Storage**: Files saved to device documents folder

## 🔧 Firestore Schema

### Sessions Collection
```json
{
  "sessions": {
    "sessionId": {
      "userId": "string",
      "startTime": "timestamp", 
      "endTime": "timestamp",
      "durationMinutes": "number",
      "status": "completed|interrupted",
      "createdAt": "timestamp"
    }
  }
}
```

### Goals Collection
```json
{
  "goals": {
    "userId": {
      "userId": "string",
      "dailySessions": "number",
      "weeklyHours": "number", 
      "updatedAt": "timestamp"
    }
  }
}
```

## 🛡️ Security Rules
Updated rules ensure:
- Users can only access their own session data
- Goal documents are user-specific
- Proper authentication checks
- Data validation on write operations

## 🎨 Customization

### Theme Integration
The analytics dashboard respects your app theme:
```dart
// Custom colors for charts
final primaryColor = Theme.of(context).primaryColor;
final cardColor = Theme.of(context).cardColor;
```

### Chart Customization
Modify chart appearance in `analytics_charts.dart`:
- Colors, fonts, and styling
- Data aggregation periods
- Chart types and layouts

### Export Customization
Modify export formats in `data_export_service.dart`:
- Custom CSV fields
- PDF layout and styling
- File naming conventions

## 🚨 Error Handling
The system includes robust error handling:
- Network connectivity checks
- Firebase auth validation
- Graceful fallbacks for missing data
- User-friendly error messages

## 📱 Testing
1. **Mock Data**: Use the provided seed data for testing
2. **Local Testing**: Test offline functionality
3. **Export Testing**: Verify CSV/PDF generation
4. **Goal Testing**: Test goal setting and progress tracking

## 🔄 Migration from Existing Data
If you have existing session data in Hive:
1. Create a migration service to convert Hive data to Firestore format
2. Batch upload existing sessions with proper userId mapping
3. Maintain backward compatibility during transition

## 📈 Performance Optimization
- **Pagination**: Large datasets are automatically paginated
- **Efficient Queries**: Indexed queries for fast data retrieval
- **Caching**: Provider-level caching for better UX
- **Background Sync**: Optional background data synchronization

## 🎯 Next Steps
1. Run `flutter pub get` to install dependencies
2. Add provider registration to main.dart
3. Integrate session recording in your timer logic
4. Add navigation to analytics dashboard
5. Deploy Firestore rules
6. Test with sample data
7. Customize styling to match your app theme

Your Analytics & Insights Engine is now ready to provide powerful insights into user focus patterns and productivity!