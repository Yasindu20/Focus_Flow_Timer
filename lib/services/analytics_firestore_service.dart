import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_analytics.dart';
import '../models/user_goals.dart';

class AnalyticsFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  // Sessions Collection Methods
  static CollectionReference get _sessionsCollection =>
      _firestore.collection('sessions');

  static CollectionReference get _goalsCollection =>
      _firestore.collection('goals');

  // Create Session
  static Future<void> createSession(SessionAnalytics session) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    await _sessionsCollection.doc(session.id).set({
      'userId': _userId,
      'startTime': Timestamp.fromDate(session.startTime),
      'endTime': session.endTime != null ? Timestamp.fromDate(session.endTime!) : null,
      'durationMinutes': session.durationMinutes,
      'status': session.status,
      'createdAt': Timestamp.now(),
    });
  }

  // Get Sessions by Date Range
  static Future<List<SessionAnalytics>> getSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_userId == null) return [];

    final snapshot = await _sessionsCollection
        .where('userId', isEqualTo: _userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('startTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SessionAnalytics.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Get Daily Sessions
  static Future<List<SessionAnalytics>> getDailySessions(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getSessionsByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // Get Weekly Sessions
  static Future<List<SessionAnalytics>> getWeeklySessions(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return getSessionsByDateRange(
      startDate: weekStart,
      endDate: weekEnd,
    );
  }

  // Get Monthly Sessions
  static Future<List<SessionAnalytics>> getMonthlySessions(DateTime monthStart) async {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    
    return getSessionsByDateRange(
      startDate: monthStart,
      endDate: monthEnd,
    );
  }

  // Get Sessions for Focus Patterns (last 30 days)
  static Future<List<SessionAnalytics>> getSessionsForFocusPatterns() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return getSessionsByDateRange(
      startDate: thirtyDaysAgo,
      endDate: DateTime.now(),
    );
  }

  // Get Streak Data (last 90 days)
  static Future<List<SessionAnalytics>> getStreakData() async {
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    return getSessionsByDateRange(
      startDate: ninetyDaysAgo,
      endDate: DateTime.now(),
    );
  }

  // Goals Methods
  static Future<void> saveUserGoals(UserGoals goals) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _goalsCollection.doc(_userId).set({
      'userId': _userId,
      'dailySessions': goals.dailySessions,
      'weeklyHours': goals.weeklyHours,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  static Future<UserGoals?> getUserGoals() async {
    if (_userId == null) return null;

    final doc = await _goalsCollection.doc(_userId).get();
    if (!doc.exists) return null;

    return UserGoals.fromFirestore(doc.data() as Map<String, dynamic>);
  }

  // Analytics Queries
  static Future<double> getEfficiencyRate({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final sessions = await getSessionsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    if (sessions.isEmpty) return 0.0;

    final completedSessions = sessions.where((s) => s.status == 'completed').length;
    return (completedSessions / sessions.length) * 100;
  }

  static Future<Map<int, int>> getFocusPatternsByHour() async {
    final sessions = await getSessionsForFocusPatterns();
    final hourlyData = <int, int>{};

    // Initialize all hours
    for (int i = 0; i < 24; i++) {
      hourlyData[i] = 0;
    }

    // Count sessions by hour
    for (final session in sessions) {
      if (session.status == 'completed') {
        final hour = session.startTime.hour;
        hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
      }
    }

    return hourlyData;
  }

  static Future<int> getCurrentStreak() async {
    final sessions = await getStreakData();
    
    // Group sessions by date
    final sessionsByDate = <DateTime, List<SessionAnalytics>>{};
    for (final session in sessions) {
      final date = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
      sessionsByDate.putIfAbsent(date, () => []).add(session);
    }

    // Check for consecutive days with completed sessions
    int streak = 0;
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < 90; i++) {
      final checkDate = currentDate.subtract(Duration(days: i));
      final dailySessions = sessionsByDate[checkDate] ?? [];
      
      final hasCompletedSession = dailySessions.any((s) => s.status == 'completed');
      
      if (hasCompletedSession) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  static Future<Map<String, dynamic>> getDashboardData() async {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(today.year, today.month, 1);

    final [
      dailySessions,
      weeklySessions,
      monthlySessions,
      goals,
      efficiency,
      focusPatterns,
      streak,
    ] = await Future.wait([
      getDailySessions(today),
      getWeeklySessions(weekStart),
      getMonthlySessions(monthStart),
      getUserGoals(),
      getEfficiencyRate(startDate: monthStart, endDate: today),
      getFocusPatternsByHour(),
      getCurrentStreak(),
    ]);

    return {
      'daily': dailySessions,
      'weekly': weeklySessions,
      'monthly': monthlySessions,
      'goals': goals,
      'efficiency': efficiency,
      'focusPatterns': focusPatterns,
      'streak': streak,
    };
  }
}