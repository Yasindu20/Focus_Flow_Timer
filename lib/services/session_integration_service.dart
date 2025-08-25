import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_analytics.dart';
import 'analytics_firestore_service.dart';

class SessionIntegrationService {
  static SessionIntegrationService? _instance;
  static SessionIntegrationService get instance => _instance ??= SessionIntegrationService._();
  SessionIntegrationService._();

  // Record a completed session to Firestore
  Future<void> recordCompletedSession({
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    String? taskId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User not authenticated, skip Firestore recording
        return;
      }

      final session = SessionAnalytics(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        status: 'completed',
      );

      await AnalyticsFirestoreService.createSession(session);
    } catch (e) {
      // Don't throw error to avoid breaking the timer flow
      debugPrint('Warning: Failed to record completed session to Firestore: $e');
    }
  }

  // Record an interrupted session to Firestore
  Future<void> recordInterruptedSession({
    required DateTime startTime,
    required DateTime interruptedTime,
    required int actualMinutes,
    required int plannedMinutes,
    String? taskId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User not authenticated, skip Firestore recording
        return;
      }

      final session = SessionAnalytics(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        startTime: startTime,
        endTime: interruptedTime,
        durationMinutes: actualMinutes,
        status: 'interrupted',
      );

      await AnalyticsFirestoreService.createSession(session);
    } catch (e) {
      // Don't throw error to avoid breaking the timer flow
      debugPrint('Warning: Failed to record interrupted session to Firestore: $e');
    }
  }

}