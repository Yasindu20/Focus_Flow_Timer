import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/enhanced_task.dart';
import '../models/pomodoro_session.dart';
import '../models/daily_stats.dart';
import '../models/task_analytics.dart';
import '../models/timer_session.dart';
import 'firebase_service.dart';
import 'web_storage_service.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box<Task> _tasksBox;
  static late Box<EnhancedTask> _enhancedTasksBox;
  static late Box<PomodoroSession> _sessionsBox;
  static late Box<TimerSession> _timerSessionsBox;
  static late Box<DailyStats> _statsBox;
  static late Box<UserAnalytics> _analyticsBox;
  static final FirebaseService _firebaseService = FirebaseService();
  static bool _isInitialized = false;
  static bool _syncEnabled = true;
  static bool _useWebFallback = false;

  /// Initialize the storage service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    await init();
    _isInitialized = true;
  }

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences initialization failed: $e');
      if (kIsWeb) {
        await WebStorageService.initialize();
        _useWebFallback = true;
      } else {
        rethrow;
      }
    }

    if (!_useWebFallback) {
      try {
        await Hive.initFlutter();

        // Register adapters
        Hive.registerAdapter(TaskAdapter());
        Hive.registerAdapter(TaskPriorityAdapter());
        Hive.registerAdapter(TaskCategoryAdapter());
        Hive.registerAdapter(TaskStatusAdapter());
        Hive.registerAdapter(TaskUrgencyAdapter());
        Hive.registerAdapter(RecurrenceTypeAdapter());
        Hive.registerAdapter(ProductivityTrendDirectionAdapter());
        Hive.registerAdapter(EnhancedTaskAdapter());
        Hive.registerAdapter(TaskSubtaskAdapter());
        Hive.registerAdapter(TaskProgressAdapter());
        Hive.registerAdapter(ProgressCheckpointAdapter());
        Hive.registerAdapter(TaskCommentAdapter());
        Hive.registerAdapter(TaskAttachmentAdapter());
        Hive.registerAdapter(TaskRecurrenceAdapter());
        Hive.registerAdapter(TaskAIDataAdapter());
        Hive.registerAdapter(TaskMetricsAdapter());
        Hive.registerAdapter(TaskTimeEntryAdapter());
        Hive.registerAdapter(PomodoroSessionAdapter());
        Hive.registerAdapter(TimerSessionAdapter());
        Hive.registerAdapter(SessionTypeAdapter());
        Hive.registerAdapter(DailyStatsAdapter());
        Hive.registerAdapter(UserAnalyticsAdapter());
        Hive.registerAdapter(CategoryPerformanceAdapter());
        Hive.registerAdapter(ProductivityRecommendationAdapter());
        Hive.registerAdapter(ProductivityPatternAdapter());

        // Open boxes
        _tasksBox = await Hive.openBox<Task>('tasks');
        _enhancedTasksBox = await Hive.openBox<EnhancedTask>('enhanced_tasks');
        _sessionsBox = await Hive.openBox<PomodoroSession>('sessions');
        _timerSessionsBox = await Hive.openBox<TimerSession>('timer_sessions');
        _statsBox = await Hive.openBox<DailyStats>('stats');
        _analyticsBox = await Hive.openBox<UserAnalytics>('analytics');
        
        debugPrint('Hive storage initialized successfully');
      } catch (e) {
        debugPrint('Hive initialization failed: $e');
        if (kIsWeb) {
          await WebStorageService.initialize();
          _useWebFallback = true;
          debugPrint('Using web storage fallback');
        } else {
          rethrow;
        }
      }
    }
  }

  // Theme settings
  static bool get isDarkMode {
    if (_useWebFallback) {
      return WebStorageService.getBool('isDarkMode') ?? false;
    }
    return _prefs.getBool('isDarkMode') ?? false;
  }
  
  static Future<void> setDarkMode(bool value) async {
    if (_useWebFallback) {
      await WebStorageService.setBool('isDarkMode', value);
    } else {
      await _prefs.setBool('isDarkMode', value);
    }
  }

  // Sound settings
  static String get selectedSound {
    if (_useWebFallback) {
      return WebStorageService.getString('selectedSound') ?? 'Forest Rain';
    }
    return _prefs.getString('selectedSound') ?? 'Forest Rain';
  }
  
  static Future<void> setSelectedSound(String sound) async {
    if (_useWebFallback) {
      await WebStorageService.setString('selectedSound', sound);
    } else {
      await _prefs.setString('selectedSound', sound);
    }
  }

  static double get soundVolume {
    if (_useWebFallback) {
      return WebStorageService.getDouble('soundVolume') ?? 0.5;
    }
    return _prefs.getDouble('soundVolume') ?? 0.5;
  }
  
  static Future<void> setSoundVolume(double volume) async {
    if (_useWebFallback) {
      await WebStorageService.setDouble('soundVolume', volume);
    } else {
      await _prefs.setDouble('soundVolume', volume);
    }
  }

  // Tasks
  static List<Task> get tasks {
    if (_useWebFallback) {
      final tasksJson = WebStorageService.getStringList('tasks') ?? [];
      return tasksJson.map((json) => Task.fromJson(Map<String, dynamic>.from(
          Map.fromEntries(json.split('|').map((item) {
        final parts = item.split(':');
        return MapEntry(parts[0], parts[1]);
      }))))).toList();
    }
    return _tasksBox.values.toList();
  }

  static Future<void> addTask(Task task) async {
    await _tasksBox.put(task.id, task);
  }

  static Future<void> updateTask(Task task) async {
    await _tasksBox.put(task.id, task);
  }

  static Future<void> deleteTask(String taskId) async {
    await _tasksBox.delete(taskId);
  }

  // Sessions
  static List<PomodoroSession> get sessions => _sessionsBox.values.toList();

  static Future<void> addSession(PomodoroSession session) async {
    await _sessionsBox.put(session.id, session);
  }

  // Daily Stats
  static DailyStats? getStatsForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return _statsBox.get(dateKey);
  }

  static Future<void> updateDailyStats(DailyStats stats) async {
    final dateKey = '${stats.date.year}-${stats.date.month}-${stats.date.day}';
    await _statsBox.put(dateKey, stats);
  }

  static List<DailyStats> getStatsForRange(DateTime start, DateTime end) {
    final stats = <DailyStats>[];
    for (var date = start;
        date.isBefore(end) || date.isAtSameMomentAs(end);
        date = date.add(const Duration(days: 1))) {
      final dayStats = getStatsForDate(date);
      if (dayStats != null) {
        stats.add(dayStats);
      }
    }
    return stats;
  }

  // Enhanced Tasks
  static List<EnhancedTask> get enhancedTasks => _enhancedTasksBox.values.toList();

  static Future<void> addEnhancedTask(EnhancedTask task) async {
    await _enhancedTasksBox.put(task.id, task);
    if (_syncEnabled && _firebaseService.isAuthenticated) {
      try {
        await _firebaseService.saveTask(task);
      } catch (e) {
        print('Failed to sync task to Firebase: $e');
      }
    }
  }

  static Future<void> updateEnhancedTask(EnhancedTask task) async {
    await _enhancedTasksBox.put(task.id, task);
    if (_syncEnabled && _firebaseService.isAuthenticated) {
      try {
        await _firebaseService.saveTask(task);
      } catch (e) {
        print('Failed to sync task update to Firebase: $e');
      }
    }
  }

  static Future<void> deleteEnhancedTask(String taskId) async {
    await _enhancedTasksBox.delete(taskId);
    if (_syncEnabled && _firebaseService.isAuthenticated) {
      try {
        await _firebaseService.deleteTask(taskId);
      } catch (e) {
        print('Failed to sync task deletion to Firebase: $e');
      }
    }
  }

  static EnhancedTask? getEnhancedTask(String taskId) {
    return _enhancedTasksBox.get(taskId);
  }

  static List<EnhancedTask> getEnhancedTasksByCategory(TaskCategory category) {
    return enhancedTasks.where((task) => task.category == category).toList();
  }

  static List<EnhancedTask> getEnhancedTasksByStatus(TaskStatus status) {
    return enhancedTasks.where((task) => task.status == status).toList();
  }

  static List<EnhancedTask> getIncompleteEnhancedTasks() {
    return enhancedTasks.where((task) => !task.isCompleted).toList();
  }

  static List<EnhancedTask> getCompletedEnhancedTasks() {
    return enhancedTasks.where((task) => task.isCompleted).toList();
  }

  // Timer Sessions
  static List<TimerSession> get timerSessions => _timerSessionsBox.values.toList();

  static Future<void> addTimerSession(TimerSession session) async {
    await _timerSessionsBox.put(session.id, session);
    if (_syncEnabled && _firebaseService.isAuthenticated) {
      try {
        await _firebaseService.saveSession(session.toJson());
      } catch (e) {
        print('Failed to sync session to Firebase: $e');
      }
    }
  }

  static TimerSession? getTimerSession(String sessionId) {
    return _timerSessionsBox.get(sessionId);
  }

  static List<TimerSession> getTimerSessionsForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return timerSessions.where((session) {
      final sessionDate = session.startTime;
      final sessionDateKey = '${sessionDate.year}-${sessionDate.month}-${sessionDate.day}';
      return sessionDateKey == dateKey;
    }).toList();
  }

  // Analytics
  static UserAnalytics? get cachedAnalytics => _analyticsBox.get('current');

  static Future<void> cacheAnalytics(UserAnalytics analytics) async {
    await _analyticsBox.put('current', analytics);
  }

  static Future<void> clearAnalyticsCache() async {
    await _analyticsBox.clear();
  }

  // Sync Management
  static bool get isSyncEnabled => _syncEnabled;

  static Future<void> setSyncEnabled(bool enabled) async {
    _syncEnabled = enabled;
    await _prefs.setBool('syncEnabled', enabled);
  }

  static Future<void> syncWithFirebase() async {
    if (!_firebaseService.isAuthenticated) return;

    try {
      // Sync enhanced tasks
      final localTasks = enhancedTasks;
      for (final task in localTasks) {
        await _firebaseService.saveTask(task);
      }

      // Sync sessions
      final localSessions = timerSessions;
      for (final session in localSessions) {
        await _firebaseService.saveSession(session.toJson());
      }

      print('Sync with Firebase completed');
    } catch (e) {
      print('Firebase sync error: $e');
    }
  }

  // Data Export
  static Map<String, dynamic> exportAllData() {
    return {
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'enhancedTasks': enhancedTasks.map((t) => t.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'timerSessions': timerSessions.map((s) => s.toJson()).toList(),
      'stats': _statsBox.values.map((s) => s.toJson()).toList(),
      'analytics': cachedAnalytics?.toJson(),
      'settings': {
        'isDarkMode': isDarkMode,
        'selectedSound': selectedSound,
        'soundVolume': soundVolume,
        'syncEnabled': isSyncEnabled,
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // Data Cleanup
  static Future<void> cleanupOldData({int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    // Clean old completed tasks
    final oldTasks = enhancedTasks.where((task) => 
      task.isCompleted && 
      task.completedAt != null && 
      task.completedAt!.isBefore(cutoffDate)
    ).toList();

    for (final task in oldTasks) {
      await _enhancedTasksBox.delete(task.id);
    }

    // Clean old sessions
    final oldSessions = timerSessions.where((session) => 
      session.startTime.isBefore(cutoffDate)
    ).toList();

    for (final session in oldSessions) {
      await _timerSessionsBox.delete(session.id);
    }

    print('Cleaned up ${oldTasks.length} old tasks and ${oldSessions.length} old sessions');
  }

  // Offline Support
  static Future<void> markForOfflineSync(String dataType, String id) async {
    final offlineQueue = _prefs.getStringList('offlineQueue') ?? [];
    final entry = '$dataType:$id:${DateTime.now().millisecondsSinceEpoch}';
    offlineQueue.add(entry);
    await _prefs.setStringList('offlineQueue', offlineQueue);
  }

  static Future<void> processOfflineQueue() async {
    if (!_firebaseService.isAuthenticated) return;

    final offlineQueue = _prefs.getStringList('offlineQueue') ?? [];
    final processedItems = <String>[];

    for (final entry in offlineQueue) {
      try {
        final parts = entry.split(':');
        final dataType = parts[0];
        final id = parts[1];

        switch (dataType) {
          case 'task':
            final task = getEnhancedTask(id);
            if (task != null) {
              await _firebaseService.saveTask(task);
            }
            break;
          case 'session':
            final session = getTimerSession(id);
            if (session != null) {
              await _firebaseService.saveSession(session.toJson());
            }
            break;
        }

        processedItems.add(entry);
      } catch (e) {
        print('Failed to process offline item $entry: $e');
      }
    }

    // Remove processed items
    offlineQueue.removeWhere((item) => processedItems.contains(item));
    await _prefs.setStringList('offlineQueue', offlineQueue);

    print('Processed ${processedItems.length} offline items');
  }

  // Close all boxes
  static Future<void> close() async {
    if (_isInitialized) {
      await _tasksBox.close();
      await _enhancedTasksBox.close();
      await _sessionsBox.close();
      await _timerSessionsBox.close();
      await _statsBox.close();
      await _analyticsBox.close();
      _isInitialized = false;
    }
  }
}
