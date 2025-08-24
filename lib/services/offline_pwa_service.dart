import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflinePwaService {
  static final OfflinePwaService _instance = OfflinePwaService._internal();
  factory OfflinePwaService() => _instance;
  OfflinePwaService._internal();

  bool _isInitialized = false;
  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _syncController = StreamController<Map<String, dynamic>>.broadcast();

  // Background sync queue
  final List<Map<String, dynamic>> _backgroundSyncQueue = [];
  
  // IndexedDB for offline storage
  static const String dbName = 'focus_flow_offline';
  static const int dbVersion = 1;

  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<Map<String, dynamic>> get syncStream => _syncController.stream;
  bool get isOnline => _isOnline;

  /// Initialize PWA offline capabilities
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!kIsWeb) {
      debugPrint('PWA service only available on web platform');
      return;
    }

    try {
      await _setupConnectivityListener();
      await _setupBackgroundSync();
      await _initializeOfflineStorage();
      
      _isInitialized = true;
      debugPrint('OfflinePwaService initialized');
    } catch (e) {
      debugPrint('Failed to initialize OfflinePwaService: $e');
    }
  }

  /// Setup connectivity monitoring (simplified for cross-platform)
  Future<void> _setupConnectivityListener() async {
    // For web platform, we'll simulate connectivity
    if (kIsWeb) {
      _isOnline = true;
      // Simulate connectivity changes for testing
      Timer.periodic(const Duration(seconds: 30), (_) {
        // This is just a placeholder for actual connectivity detection
      });
    }
    
    debugPrint('Connectivity monitoring setup complete');
  }

  /// Setup background sync capabilities (simplified)
  Future<void> _setupBackgroundSync() async {
    debugPrint('Background sync setup complete');
  }

  /// Initialize offline storage (simplified)
  Future<void> _initializeOfflineStorage() async {
    try {
      await _loadSyncQueue();
      debugPrint('Offline storage initialized');
    } catch (e) {
      debugPrint('Offline storage initialization failed: $e');
    }
  }

  /// Store data for offline access (using SharedPreferences for cross-platform)
  Future<void> storeOfflineData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_$key', jsonEncode(data));
    } catch (e) {
      debugPrint('Error storing offline data: $e');
    }
  }

  /// Retrieve offline data (using SharedPreferences for cross-platform)
  Future<Map<String, dynamic>?> getOfflineData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('offline_$key');
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting offline data: $e');
      return null;
    }
  }

  /// Queue operation for background sync
  Future<void> queueForBackgroundSync(String operation, Map<String, dynamic> data) async {
    final syncItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };

    _backgroundSyncQueue.add(syncItem);
    await _persistSyncQueue();

    // Try immediate sync if online
    if (_isOnline) {
      await _processPendingSyncs();
    } else {
      // Register for background sync when connection returns
      debugPrint('Registered for background sync: $operation-sync');
    }
  }

  /// Process pending background syncs
  Future<void> _processPendingSyncs() async {
    if (!_isOnline || _backgroundSyncQueue.isEmpty) return;

    final itemsToProcess = List<Map<String, dynamic>>.from(_backgroundSyncQueue);
    final processedItems = <Map<String, dynamic>>[];

    for (final item in itemsToProcess) {
      try {
        final success = await _processSync(item);
        if (success) {
          processedItems.add(item);
          _syncController.add({
            'type': 'success',
            'operation': item['operation'],
            'id': item['id'],
          });
        } else {
          // Increment retry count
          item['retryCount'] = (item['retryCount'] as int) + 1;
          
          // Remove if too many retries
          if (item['retryCount'] >= 3) {
            processedItems.add(item);
            _syncController.add({
              'type': 'failed',
              'operation': item['operation'],
              'id': item['id'],
              'error': 'Max retries exceeded',
            });
          }
        }
      } catch (e) {
        debugPrint('Error processing sync item: $e');
        item['retryCount'] = (item['retryCount'] as int) + 1;
        
        if (item['retryCount'] >= 3) {
          processedItems.add(item);
        }
      }
    }

    // Remove processed items
    _backgroundSyncQueue.removeWhere((item) => processedItems.contains(item));
    await _persistSyncQueue();

    debugPrint('Processed ${processedItems.length} sync items');
  }

  /// Process individual sync operation
  Future<bool> _processSync(Map<String, dynamic> item) async {
    final operation = item['operation'] as String;
    final data = item['data'] as Map<String, dynamic>;

    try {
      switch (operation) {
        case 'save_task':
          return await _syncTask(data);
        case 'delete_task':
          return await _syncTaskDeletion(data);
        case 'save_session':
          return await _syncSession(data);
        case 'sync_analytics':
          return await _syncAnalytics(data);
        default:
          debugPrint('Unknown sync operation: $operation');
          return false;
      }
    } catch (e) {
      debugPrint('Sync operation failed: $e');
      return false;
    }
  }

  Future<bool> _syncTask(Map<String, dynamic> data) async {
    try {
      // Simulate API call to sync task
      // In real implementation, call your backend API
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('Task synced: ${data['id']}');
      return true;
    } catch (e) {
      debugPrint('Task sync failed: $e');
      return false;
    }
  }

  Future<bool> _syncTaskDeletion(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('Task deletion synced: ${data['id']}');
      return true;
    } catch (e) {
      debugPrint('Task deletion sync failed: $e');
      return false;
    }
  }

  Future<bool> _syncSession(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      debugPrint('Session synced: ${data['id']}');
      return true;
    } catch (e) {
      debugPrint('Session sync failed: $e');
      return false;
    }
  }

  Future<bool> _syncAnalytics(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      debugPrint('Analytics synced');
      return true;
    } catch (e) {
      debugPrint('Analytics sync failed: $e');
      return false;
    }
  }

  /// Persist sync queue to storage
  Future<void> _persistSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _backgroundSyncQueue.map((item) => jsonEncode(item)).toList();
      await prefs.setStringList('background_sync_queue', queueJson);
    } catch (e) {
      debugPrint('Error persisting sync queue: $e');
    }
  }

  /// Load sync queue from storage
  Future<void> _loadSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList('background_sync_queue') ?? [];
      
      _backgroundSyncQueue.clear();
      for (final itemJson in queueJson) {
        final item = jsonDecode(itemJson) as Map<String, dynamic>;
        _backgroundSyncQueue.add(item);
      }
      
      debugPrint('Loaded ${_backgroundSyncQueue.length} queued sync items');
    } catch (e) {
      debugPrint('Error loading sync queue: $e');
    }
  }

  /// Clear offline data
  Future<void> clearOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('offline_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('Offline data cleared');
    } catch (e) {
      debugPrint('Error clearing offline data: $e');
    }
  }

  /// Cache management
  Future<void> precacheImportantData() async {
    try {
      // Cache critical app data for offline use
      final tasks = await _getCriticalTasks();
      await storeOfflineData('critical_tasks', {'tasks': tasks});
      
      final recentSessions = await _getRecentSessions();
      await storeOfflineData('recent_sessions', {'sessions': recentSessions});
      
      debugPrint('Critical data precached for offline use');
    } catch (e) {
      debugPrint('Error precaching data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getCriticalTasks() async {
    // Get high-priority and recent tasks
    return []; // Placeholder
  }

  Future<List<Map<String, dynamic>>> _getRecentSessions() async {
    // Get recent pomodoro sessions
    return []; // Placeholder
  }

  /// Get offline storage info (simplified for cross-platform)
  Future<Map<String, dynamic>> getOfflineStorageInfo() async {
    try {
      return {
        'sync_queue_length': _backgroundSyncQueue.length,
        'is_online': _isOnline,
        'storage_type': 'SharedPreferences',
      };
    } catch (e) {
      debugPrint('Error getting storage info: $e');
      return {};
    }
  }

  /// Force sync all pending operations
  Future<void> forceSyncAll() async {
    if (!_isOnline) {
      debugPrint('Cannot sync: offline');
      return;
    }

    await _processPendingSyncs();
  }

  /// Install app prompt (simplified)
  Future<void> showInstallPrompt() async {
    debugPrint('Install prompt - use browser install option');
  }

  /// Check if app is installable
  bool isInstallable() {
    return kIsWeb;
  }

  /// Enable/disable offline mode
  Future<void> setOfflineMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_mode_enabled', enabled);
      
      if (enabled) {
        await precacheImportantData();
      }
      
      debugPrint('Offline mode ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error setting offline mode: $e');
    }
  }

  /// Check if offline mode is enabled
  Future<bool> isOfflineModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('offline_mode_enabled') ?? false;
    } catch (e) {
      debugPrint('Error checking offline mode: $e');
      return false;
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'pending_syncs': _backgroundSyncQueue.length,
      'failed_syncs': _backgroundSyncQueue.where((item) => item['retryCount'] >= 3).length,
      'is_online': _isOnline,
      'last_sync_attempt': _backgroundSyncQueue.isNotEmpty 
          ? _backgroundSyncQueue.last['timestamp'] 
          : null,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivityController.close();
    await _syncController.close();
  }
}