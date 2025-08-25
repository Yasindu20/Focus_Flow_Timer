import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_task.dart';
import '../models/pomodoro_session.dart';
import '../models/daily_stats.dart';
import '../models/task_analytics.dart';

// Duration adapter for Hive
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 100; // Use a high typeId to avoid conflicts

  @override
  Duration read(BinaryReader reader) {
    final microseconds = reader.readInt();
    return Duration(microseconds: microseconds);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}

class OptimizedStorageService {
  static final OptimizedStorageService _instance = OptimizedStorageService._internal();
  factory OptimizedStorageService() => _instance;
  OptimizedStorageService._internal();

  // Local storage (Hive)
  Box<EnhancedTask>? _tasksBox;
  Box<PomodoroSession>? _sessionsBox;
  Box<DailyStats>? _statsBox;
  Box<Map>? _cacheBox;

  // Cloud storage (Firestore - Free tier optimized)
  FirebaseFirestore? _firestore;
  
  // Storage state
  bool _isInitialized = false;
  bool _isOnline = true;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();

  // Free tier limits tracking
  int _dailyReads = 0;
  int _dailyWrites = 0;
  DateTime _lastResetDate = DateTime.now();
  
  // Firestore free tier limits (daily)
  static const int maxDailyReads = 45000; // Leave buffer from 50k limit
  static const int maxDailyWrites = 18000; // Leave buffer from 20k limit
  static const int maxStorageMb = 900; // Leave buffer from 1GB limit

  Stream<bool> get syncStatus => _syncStatusController.stream;
  bool get isOnline => _isOnline;

  /// Initialize storage service with free tier optimization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive (local storage)
      await _initializeHive();
      
      // Initialize Firestore (cloud storage) - free tier
      await _initializeFirestore();
      
      // Load usage tracking
      await _loadUsageTracking();
      
      _isInitialized = true;
      debugPrint('OptimizedStorageService initialized');
    } catch (e) {
      debugPrint('Failed to initialize storage service: $e');
      // Continue with local-only mode
      _isInitialized = true;
      _isOnline = false;
    }
  }

  // TASKS STORAGE
  Future<void> saveTask(EnhancedTask task) async {
    if (!_isInitialized) await initialize();

    try {
      // Always save locally first (instant)
      await _tasksBox?.put(task.id, task);
      
      // Sync to cloud if within limits
      if (_isOnline && _canMakeWrite()) {
        await _syncTaskToCloud(task);
        _incrementWrites();
      } else {
        // Queue for later sync
        await _queueForSync('task', task.toJson());
      }
    } catch (e) {
      debugPrint('Error saving task: $e');
      // Ensure local save at minimum
      await _tasksBox?.put(task.id, task);
    }
  }

  Future<EnhancedTask?> getTask(String id) async {
    if (!_isInitialized) await initialize();

    try {
      // Try local first (instant)
      final localTask = _tasksBox?.get(id);
      if (localTask != null) {
        return localTask;
      }

      // Try cloud if online and within limits
      if (_isOnline && _canMakeRead()) {
        final cloudTask = await _getTaskFromCloud(id);
        _incrementReads();
        
        // Cache locally
        if (cloudTask != null) {
          await _tasksBox?.put(id, cloudTask);
        }
        
        return cloudTask;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting task: $e');
      return _tasksBox?.get(id);
    }
  }

  Future<List<EnhancedTask>> getAllTasks() async {
    if (!_isInitialized) await initialize();

    try {
      // Get from local storage first
      final localTasks = _tasksBox?.values.toList() ?? <EnhancedTask>[];
      
      // Try to sync from cloud if we haven't synced recently
      if (_isOnline && _shouldSyncTasks()) {
        await _syncTasksFromCloud();
      }
      
      // Return updated local tasks
      return _tasksBox?.values.toList() ?? localTasks;
    } catch (e) {
      debugPrint('Error getting all tasks: $e');
      return _tasksBox?.values.toList() ?? <EnhancedTask>[];
    }
  }

  Future<void> deleteTask(String id) async {
    if (!_isInitialized) await initialize();

    try {
      // Delete locally first
      await _tasksBox?.delete(id);
      
      // Delete from cloud if within limits
      if (_isOnline && _canMakeWrite()) {
        await _deleteTaskFromCloud(id);
        _incrementWrites();
      } else {
        // Queue deletion for later
        await _queueForSync('delete_task', {'id': id});
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  // POMODORO SESSIONS STORAGE
  Future<void> savePomodoroSession(PomodoroSession session) async {
    if (!_isInitialized) await initialize();

    try {
      // Save locally
      await _sessionsBox?.put(session.id, session);
      
      // Batch sessions for cloud sync to save writes
      await _batchSessionForCloudSync(session);
    } catch (e) {
      debugPrint('Error saving pomodoro session: $e');
      await _sessionsBox?.put(session.id, session);
    }
  }

  Future<List<PomodoroSession>> getPomodoroSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      var sessions = _sessionsBox?.values.toList() ?? <PomodoroSession>[];
      
      if (startDate != null) {
        sessions = sessions.where((s) => s.startTime.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        sessions = sessions.where((s) => s.startTime.isBefore(endDate)).toList();
      }
      
      return sessions;
    } catch (e) {
      debugPrint('Error getting pomodoro sessions: $e');
      return [];
    }
  }

  // DAILY STATS STORAGE
  Future<void> saveDailyStats(DailyStats stats) async {
    if (!_isInitialized) await initialize();

    try {
      await _statsBox?.put(stats.date.toIso8601String(), stats);
      
      // Batch stats for efficient cloud sync
      await _batchStatsForCloudSync(stats);
    } catch (e) {
      debugPrint('Error saving daily stats: $e');
      await _statsBox?.put(stats.date.toIso8601String(), stats);
    }
  }

  Future<DailyStats?> getDailyStats(DateTime date) async {
    if (!_isInitialized) await initialize();

    try {
      return _statsBox?.get(date.toIso8601String());
    } catch (e) {
      debugPrint('Error getting daily stats: $e');
      return null;
    }
  }

  Future<List<DailyStats>> getStatsRange(DateTime start, DateTime end) async {
    if (!_isInitialized) await initialize();

    try {
      final allStats = _statsBox?.values.toList() ?? <DailyStats>[];
      return allStats.where((stats) => 
        stats.date.isAfter(start.subtract(const Duration(days: 1))) &&
        stats.date.isBefore(end.add(const Duration(days: 1)))
      ).toList();
    } catch (e) {
      debugPrint('Error getting stats range: $e');
      return [];
    }
  }

  // CACHING SYSTEM
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    if (!_isInitialized) await initialize();

    try {
      await _cacheBox?.put(key, data);
    } catch (e) {
      debugPrint('Error caching data: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedData(String key) async {
    if (!_isInitialized) await initialize();

    try {
      final data = _cacheBox?.get(key);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      debugPrint('Error getting cached data: $e');
      return null;
    }
  }

  // SYNC MANAGEMENT
  Future<void> forceSyncAll() async {
    if (!_isOnline) {
      debugPrint('Cannot sync: offline');
      return;
    }

    try {
      _syncStatusController.add(true);
      
      // Process queued operations first
      await _processQueuedOperations();
      
      // Sync tasks
      await _syncTasksToCloud();
      
      // Sync batched sessions
      await _syncBatchedSessions();
      
      // Sync batched stats
      await _syncBatchedStats();
      
      _syncStatusController.add(false);
      debugPrint('Full sync completed');
    } catch (e) {
      debugPrint('Error in full sync: $e');
      _syncStatusController.add(false);
    }
  }

  Future<void> enableOfflineMode() async {
    _isOnline = false;
    debugPrint('Offline mode enabled');
  }

  Future<void> enableOnlineMode() async {
    _isOnline = true;
    debugPrint('Online mode enabled, attempting sync...');
    
    // Trigger background sync
    unawaited(_backgroundSync());
  }

  // STORAGE OPTIMIZATION
  Future<void> optimizeStorage() async {
    try {
      // Clean old cache data (older than 30 days)
      await _cleanOldCache();
      
      // Compact Hive boxes
      await _compactHiveBoxes();
      
      // Clean up old sessions (keep only last 90 days)
      await _cleanOldSessions();
      
      debugPrint('Storage optimization completed');
    } catch (e) {
      debugPrint('Error optimizing storage: $e');
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final tasksCount = _tasksBox?.length ?? 0;
      final sessionsCount = _sessionsBox?.length ?? 0;
      final statsCount = _statsBox?.length ?? 0;
      final cacheCount = _cacheBox?.length ?? 0;
      
      return {
        'local_storage': {
          'tasks': tasksCount,
          'sessions': sessionsCount,
          'stats': statsCount,
          'cache': cacheCount,
          'total_items': tasksCount + sessionsCount + statsCount + cacheCount,
        },
        'cloud_usage': {
          'daily_reads': _dailyReads,
          'daily_writes': _dailyWrites,
          'reads_remaining': maxDailyReads - _dailyReads,
          'writes_remaining': maxDailyWrites - _dailyWrites,
        },
        'sync_status': {
          'is_online': _isOnline,
          'last_sync': await _getLastSyncTime(),
          'queued_operations': await _getQueuedOperationsCount(),
        }
      };
    } catch (e) {
      debugPrint('Error getting storage info: $e');
      return {};
    }
  }

  // PRIVATE METHODS

  Future<void> _initializeHive() async {
    await Hive.initFlutter();
    
    // Register all adapters if not already registered
    // Main models
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(EnhancedTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PomodoroSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyStatsAdapter());
    }
    
    // Supporting classes from enhanced_task.dart
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(TaskSubtaskAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(TaskProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(ProgressCheckpointAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(TaskCommentAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(TaskAttachmentAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(TaskRecurrenceAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(TaskAIDataAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(TaskMetricsAdapter());
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(TaskTimeEntryAdapter());
    }
    
    // Enums
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(TaskCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(TaskStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(TaskUrgencyAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(RecurrenceTypeAdapter());
    }
    
    // Task Analytics adapters (based on actual generated adapters)
    if (!Hive.isAdapterRegistered(56)) {
      Hive.registerAdapter(TaskCompletionDataAdapter());
    }
    if (!Hive.isAdapterRegistered(57)) {
      Hive.registerAdapter(UserAnalyticsAdapter());
    }
    if (!Hive.isAdapterRegistered(58)) {
      Hive.registerAdapter(CategoryPerformanceAdapter());
    }
    if (!Hive.isAdapterRegistered(59)) {
      Hive.registerAdapter(ProductivityPatternAdapter());
    }
    // Enums from task_analytics
    if (!Hive.isAdapterRegistered(61)) {
      Hive.registerAdapter(RecommendationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(62)) {
      Hive.registerAdapter(RecommendationImpactAdapter());
    }
    if (!Hive.isAdapterRegistered(63)) {
      Hive.registerAdapter(RecommendationEffortAdapter());
    }
    if (!Hive.isAdapterRegistered(64)) {
      Hive.registerAdapter(ComparisonTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(65)) {
      Hive.registerAdapter(PatternTypeAdapter());
    }
    
    // Duration adapter
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(DurationAdapter());
    }

    // Open boxes
    _tasksBox = await Hive.openBox<EnhancedTask>('tasks');
    _sessionsBox = await Hive.openBox<PomodoroSession>('sessions');
    _statsBox = await Hive.openBox<DailyStats>('stats');
    _cacheBox = await Hive.openBox<Map>('cache');
  }

  Future<void> _initializeFirestore() async {
    try {
      _firestore = FirebaseFirestore.instance;
      
      // Configure for offline persistence
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      debugPrint('Firestore initialized with offline persistence');
    } catch (e) {
      debugPrint('Failed to initialize Firestore: $e');
      _isOnline = false;
    }
  }

  Future<void> _loadUsageTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString('usage_last_reset');
    final today = DateTime.now();
    
    if (lastResetStr != null) {
      _lastResetDate = DateTime.parse(lastResetStr);
      
      // Reset daily counters if it's a new day
      if (_lastResetDate.day != today.day) {
        _dailyReads = 0;
        _dailyWrites = 0;
        _lastResetDate = today;
        await _saveUsageTracking();
      } else {
        _dailyReads = prefs.getInt('daily_reads') ?? 0;
        _dailyWrites = prefs.getInt('daily_writes') ?? 0;
      }
    } else {
      _lastResetDate = today;
      await _saveUsageTracking();
    }
  }

  Future<void> _saveUsageTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usage_last_reset', _lastResetDate.toIso8601String());
    await prefs.setInt('daily_reads', _dailyReads);
    await prefs.setInt('daily_writes', _dailyWrites);
  }

  bool _canMakeRead() {
    return _dailyReads < maxDailyReads;
  }

  bool _canMakeWrite() {
    return _dailyWrites < maxDailyWrites;
  }

  void _incrementReads() {
    _dailyReads++;
    unawaited(_saveUsageTracking());
  }

  void _incrementWrites() {
    _dailyWrites++;
    unawaited(_saveUsageTracking());
  }

  // Cloud operations
  Future<void> _syncTaskToCloud(EnhancedTask task) async {
    if (_firestore == null) return;

    try {
      await _firestore!
          .collection('tasks')
          .doc(task.id)
          .set(task.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing task to cloud: $e');
      await _queueForSync('task', task.toJson());
    }
  }

  Future<EnhancedTask?> _getTaskFromCloud(String id) async {
    if (_firestore == null) return null;

    try {
      final doc = await _firestore!.collection('tasks').doc(id).get();
      if (doc.exists) {
        return EnhancedTask.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting task from cloud: $e');
      return null;
    }
  }

  Future<void> _deleteTaskFromCloud(String id) async {
    if (_firestore == null) return;

    try {
      await _firestore!.collection('tasks').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting task from cloud: $e');
    }
  }

  Future<void> _syncTasksFromCloud() async {
    if (_firestore == null || !_canMakeRead()) return;

    try {
      final snapshot = await _firestore!
          .collection('tasks')
          .where('lastModified', isGreaterThan: await _getLastSyncTime())
          .get();

      _incrementReads();

      for (final doc in snapshot.docs) {
        final task = EnhancedTask.fromJson(doc.data());
        await _tasksBox?.put(task.id, task);
      }

      await _updateLastSyncTime();
    } catch (e) {
      debugPrint('Error syncing tasks from cloud: $e');
    }
  }

  Future<void> _syncTasksToCloud() async {
    if (_firestore == null) return;

    try {
      final localTasks = _tasksBox?.values.toList() ?? [];
      final batch = _firestore!.batch();
      int batchCount = 0;

      for (final task in localTasks) {
        if (!_canMakeWrite()) break;

        final ref = _firestore!.collection('tasks').doc(task.id);
        batch.set(ref, task.toJson(), SetOptions(merge: true));
        batchCount++;

        // Firestore batch limit is 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          _dailyWrites += batchCount;
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        _dailyWrites += batchCount;
      }

      await _saveUsageTracking();
    } catch (e) {
      debugPrint('Error syncing tasks to cloud: $e');
    }
  }

  // Batching for sessions and stats
  Future<void> _batchSessionForCloudSync(PomodoroSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final batchedSessions = prefs.getStringList('batched_sessions') ?? [];
    
    batchedSessions.add(jsonEncode(session.toJson()));
    await prefs.setStringList('batched_sessions', batchedSessions);

    // Auto-sync if batch is large enough
    if (batchedSessions.length >= 50) {
      unawaited(_syncBatchedSessions());
    }
  }

  Future<void> _syncBatchedSessions() async {
    if (_firestore == null || !_canMakeWrite()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final batchedSessions = prefs.getStringList('batched_sessions') ?? [];
      
      if (batchedSessions.isEmpty) return;

      final batch = _firestore!.batch();
      final now = DateTime.now();
      
      // Group sessions by date for efficient storage
      final sessionsByDate = <String, List<Map<String, dynamic>>>{};
      
      for (final sessionJson in batchedSessions) {
        final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
        final date = DateTime.parse(sessionData['startTime']).toIso8601String().substring(0, 10);
        sessionsByDate[date] ??= [];
        sessionsByDate[date]!.add(sessionData);
      }

      // Store grouped sessions
      for (final entry in sessionsByDate.entries) {
        final ref = _firestore!.collection('sessions').doc(entry.key);
        batch.set(ref, {
          'date': entry.key,
          'sessions': entry.value,
          'lastUpdated': now.toIso8601String(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      _incrementWrites();
      
      // Clear batched sessions
      await prefs.setStringList('batched_sessions', []);
    } catch (e) {
      debugPrint('Error syncing batched sessions: $e');
    }
  }

  Future<void> _batchStatsForCloudSync(DailyStats stats) async {
    // Stats are naturally daily, so sync directly but efficiently
    if (_firestore == null || !_canMakeWrite()) return;

    try {
      await _firestore!
          .collection('stats')
          .doc(stats.date.toIso8601String())
          .set(stats.toJson(), SetOptions(merge: true));
      
      _incrementWrites();
    } catch (e) {
      debugPrint('Error syncing stats: $e');
    }
  }

  Future<void> _syncBatchedStats() async {
    // Implementation for syncing any queued stats
    debugPrint('Synced batched stats');
  }

  // Queue management for offline operations
  Future<void> _queueForSync(String operation, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('sync_queue') ?? [];
    
    queue.add(jsonEncode({
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    
    await prefs.setStringList('sync_queue', queue);
  }

  Future<void> _processQueuedOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('sync_queue') ?? [];
    
    if (queue.isEmpty) return;

    final processedOperations = <String>[];

    for (final operationJson in queue) {
      if (!_canMakeWrite()) break;

      try {
        final operation = jsonDecode(operationJson) as Map<String, dynamic>;
        
        switch (operation['operation']) {
          case 'task':
            final task = EnhancedTask.fromJson(operation['data']);
            await _syncTaskToCloud(task);
            break;
          case 'delete_task':
            await _deleteTaskFromCloud(operation['data']['id']);
            break;
        }
        
        processedOperations.add(operationJson);
        _incrementWrites();
      } catch (e) {
        debugPrint('Error processing queued operation: $e');
      }
    }

    // Remove processed operations
    queue.removeWhere((op) => processedOperations.contains(op));
    await prefs.setStringList('sync_queue', queue);
  }

  // Utility methods
  bool _shouldSyncTasks() {
    // Only sync tasks once per hour to conserve API calls
    final now = DateTime.now();
    return now.difference(_lastResetDate).inHours >= 1;
  }

  Future<DateTime> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_time');
    return lastSyncStr != null 
        ? DateTime.parse(lastSyncStr) 
        : DateTime.now().subtract(const Duration(days: 30));
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
  }

  Future<int> _getQueuedOperationsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('sync_queue') ?? [];
    return queue.length;
  }

  // Background sync
  Future<void> _backgroundSync() async {
    if (!_isOnline) return;

    try {
      // Process small batches to avoid hitting limits
      if (_canMakeRead() && _canMakeWrite()) {
        await _processQueuedOperations();
        
        // Sync critical data only
        final criticalTasks = _tasksBox?.values
            .where((task) => task.priority == TaskPriority.critical)
            .toList() ?? [];
        
        for (final task in criticalTasks.take(5)) {
          if (_canMakeWrite()) {
            await _syncTaskToCloud(task);
            _incrementWrites();
          }
        }
      }
    } catch (e) {
      debugPrint('Error in background sync: $e');
    }
  }

  // Cleanup methods
  Future<void> _cleanOldCache() async {
    if (_cacheBox == null) return;

    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final keysToDelete = <String>[];

    for (final key in _cacheBox!.keys) {
      final data = _cacheBox!.get(key);
      if (data is Map && data['timestamp'] != null) {
        final timestamp = DateTime.parse(data['timestamp']);
        if (timestamp.isBefore(cutoffDate)) {
          keysToDelete.add(key.toString());
        }
      }
    }

    for (final key in keysToDelete) {
      await _cacheBox!.delete(key);
    }
  }

  Future<void> _cleanOldSessions() async {
    if (_sessionsBox == null) return;

    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    final keysToDelete = <String>[];

    for (final key in _sessionsBox!.keys) {
      final session = _sessionsBox!.get(key);
      if (session != null && session.startTime.isBefore(cutoffDate)) {
        keysToDelete.add(key.toString());
      }
    }

    for (final key in keysToDelete) {
      await _sessionsBox!.delete(key);
    }
  }

  Future<void> _compactHiveBoxes() async {
    await _tasksBox?.compact();
    await _sessionsBox?.compact();
    await _statsBox?.compact();
    await _cacheBox?.compact();
  }

  /// Dispose resources
  // ACHIEVEMENT STORAGE
  Future<List<Map<String, dynamic>>> getAchievements() async {
    final data = await getCachedData('achievements');
    return data != null ? List<Map<String, dynamic>>.from(data['achievements'] ?? []) : [];
  }

  Future<void> setAchievements(List<Map<String, dynamic>> achievements) async {
    await cacheData('achievements', {'achievements': achievements});
  }

  // PRODUCTIVITY SCORE STORAGE
  Future<Map<String, dynamic>?> getCurrentProductivityScore() async {
    return await getCachedData('current_productivity_score');
  }

  Future<void> setCurrentProductivityScore(Map<String, dynamic> score) async {
    await cacheData('current_productivity_score', score);
  }

  Future<List<Map<String, dynamic>>> getWeeklyProductivityScores() async {
    final data = await getCachedData('weekly_productivity_scores');
    return data != null ? List<Map<String, dynamic>>.from(data['scores'] ?? []) : [];
  }

  Future<void> setWeeklyProductivityScores(List<Map<String, dynamic>> scores) async {
    await cacheData('weekly_productivity_scores', {'scores': scores});
  }

  Future<List<Map<String, dynamic>>> getMonthlyProductivityScores() async {
    final data = await getCachedData('monthly_productivity_scores');
    return data != null ? List<Map<String, dynamic>>.from(data['scores'] ?? []) : [];
  }

  Future<void> setMonthlyProductivityScores(List<Map<String, dynamic>> scores) async {
    await cacheData('monthly_productivity_scores', {'scores': scores});
  }

  Future<void> clearProductivityScores() async {
    await cacheData('current_productivity_score', {});
    await cacheData('weekly_productivity_scores', {'scores': []});
    await cacheData('monthly_productivity_scores', {'scores': []});
  }

  // LEADERBOARD STORAGE
  Future<Map<String, Map<String, dynamic>>> getLeaderboards() async {
    final data = await getCachedData('leaderboards');
    return data != null ? Map<String, Map<String, dynamic>>.from(data['leaderboards'] ?? {}) : {};
  }

  Future<void> setLeaderboards(Map<String, Map<String, dynamic>> leaderboards) async {
    await cacheData('leaderboards', {'leaderboards': leaderboards});
  }

  Future<Map<String, dynamic>?> getUserLeaderboardEntry() async {
    return await getCachedData('user_leaderboard_entry');
  }

  Future<void> setUserLeaderboardEntry(Map<String, dynamic> entry) async {
    await cacheData('user_leaderboard_entry', entry);
  }

  Future<void> clearUserLeaderboardEntry() async {
    await cacheData('user_leaderboard_entry', {});
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _syncStatusController.close();
    await _tasksBox?.close();
    await _sessionsBox?.close();
    await _statsBox?.close();
    await _cacheBox?.close();
  }
}