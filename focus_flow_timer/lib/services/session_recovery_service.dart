import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_session.dart';

class SessionRecoveryService {
  static const String _activeSessionKey = 'active_timer_session';
  static const String _sessionHistoryKey = 'timer_session_history';
  static const String _crashRecoveryKey = 'timer_crash_recovery';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _cleanupOldSessions();
  }

  /// Save current session state for recovery
  Future<void> saveSessionState(TimerSession session) async {
    final sessionJson = jsonEncode(session.toJson());
    await _prefs.setString(_activeSessionKey, sessionJson);

    // Save crash recovery data
    await _saveCrashRecoveryData(session);
  }

  /// Get pending session for recovery
  Future<TimerSession?> getPendingSession() async {
    final sessionJson = _prefs.getString(_activeSessionKey);
    if (sessionJson == null) return null;

    try {
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      return TimerSession.fromJson(sessionData);
    } catch (e) {
      // Clean up corrupted data
      await clearActiveSession();
      return null;
    }
  }

  /// Archive completed session
  Future<void> archiveSession(TimerSession session) async {
    await _addToSessionHistory(session);
    await clearActiveSession();
  }

  /// Clear active session
  Future<void> clearActiveSession() async {
    await _prefs.remove(_activeSessionKey);
    await _prefs.remove(_crashRecoveryKey);
  }

  /// Get session history
  Future<List<TimerSession>> getSessionHistory({int? limit}) async {
    final historyJson = _prefs.getString(_sessionHistoryKey);
    if (historyJson == null) return [];

    try {
      final historyData = jsonDecode(historyJson) as List;
      final sessions = historyData
          .map((data) => TimerSession.fromJson(data as Map<String, dynamic>))
          .toList();

      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

      if (limit != null && sessions.length > limit) {
        return sessions.take(limit).toList();
      }

      return sessions;
    } catch (e) {
      return [];
    }
  }

  /// Detect app crash and provide recovery
  Future<bool> detectCrashRecovery() async {
    final crashData = _prefs.getString(_crashRecoveryKey);
    if (crashData == null) return false;

    try {
      final data = jsonDecode(crashData) as Map<String, dynamic>;
      final lastUpdateTime = DateTime.parse(data['lastUpdate']);

      // If last update was more than 2 minutes ago, consider it a crash
      final timeSinceUpdate = DateTime.now().difference(lastUpdateTime);
      return timeSinceUpdate.inMinutes > 2;
    } catch (e) {
      return false;
    }
  }

  /// Update crash recovery heartbeat
  Future<void> updateCrashRecoveryHeartbeat(TimerSession session) async {
    if (session.isActive) {
      final data = {
        'sessionId': session.id,
        'lastUpdate': DateTime.now().toIso8601String(),
        'elapsedMs': session.actualDuration ?? 0,
      };

      await _prefs.setString(_crashRecoveryKey, jsonEncode(data));
    }
  }

  /// Get recovery statistics
  Future<Map<String, dynamic>> getRecoveryStats() async {
    final history = await getSessionHistory();

    final completedSessions = history.where((s) => s.completed).length;
    final interruptedSessions = history.where((s) => !s.completed).length;
    final totalSessions = history.length;

    final completionRate =
        totalSessions > 0 ? completedSessions / totalSessions : 0.0;

    return {
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'interruptedSessions': interruptedSessions,
      'completionRate': completionRate,
      'averageSessionLength': _calculateAverageSessionLength(history),
    };
  }

  // Private methods

  Future<void> _saveCrashRecoveryData(TimerSession session) async {
    final data = {
      'sessionId': session.id,
      'lastUpdate': DateTime.now().toIso8601String(),
      'elapsedMs': session.actualDuration ?? 0,
    };

    await _prefs.setString(_crashRecoveryKey, jsonEncode(data));
  }

  Future<void> _addToSessionHistory(TimerSession session) async {
    final history = await getSessionHistory();
    history.insert(0, session);

    // Keep only last 100 sessions
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }

    final historyJson = jsonEncode(history.map((s) => s.toJson()).toList());
    await _prefs.setString(_sessionHistoryKey, historyJson);
  }

  Future<void> _cleanupOldSessions() async {
    final history = await getSessionHistory();
    final now = DateTime.now();

    // Remove sessions older than 30 days
    final recentHistory = history.where((session) {
      final age = now.difference(session.startTime);
      return age.inDays <= 30;
    }).toList();

    if (recentHistory.length != history.length) {
      final historyJson =
          jsonEncode(recentHistory.map((s) => s.toJson()).toList());
      await _prefs.setString(_sessionHistoryKey, historyJson);
    }
  }

  double _calculateAverageSessionLength(List<TimerSession> sessions) {
    if (sessions.isEmpty) return 0.0;

    final completedSessions =
        sessions.where((s) => s.completed && s.actualDuration != null);
    if (completedSessions.isEmpty) return 0.0;

    final totalDuration =
        completedSessions.map((s) => s.actualDuration!).reduce((a, b) => a + b);

    return totalDuration / completedSessions.length;
  }
}
