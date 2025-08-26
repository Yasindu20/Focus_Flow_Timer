import 'package:flutter/foundation.dart';
import 'dart:async';
import '../core/enums/timer_enums.dart';
import '../services/optimized_storage_service.dart';
import '../services/notification_manager.dart';
import '../services/session_integration_service.dart';
import '../models/timer_session.dart';
import 'timer_settings_provider.dart';

class EnhancedTimerProvider extends ChangeNotifier {
  final OptimizedStorageService _storage = OptimizedStorageService();
  final NotificationManager _notifications = NotificationManager();
  TimerSettingsProvider? _settingsProvider;
  
  // Timer state
  TimerState _state = TimerState.idle;
  TimerType _currentType = TimerType.pomodoro;
  Duration _remainingTime = const Duration(minutes: 25);
  Duration _totalTime = const Duration(minutes: 25);
  Timer? _timer;
  DateTime? _startTime;
  
  // Session tracking
  String? _currentTaskId;
  int _sessionCount = 0;
  bool _isInitialized = false;
  
  // Error handling
  String? _lastError;
  DateTime? _lastErrorTime;

  // Getters
  String? get currentTaskId => _currentTaskId;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  
  // Timer state getters
  TimerState get state => _state;
  TimerType get currentType => _currentType;
  int get sessionCount => _sessionCount;
  Duration get remainingTime => _remainingTime;
  Duration get totalTime => _totalTime;
  double get progress => _totalTime.inMilliseconds > 0 
      ? 1.0 - (_remainingTime.inMilliseconds / _totalTime.inMilliseconds)
      : 0.0;
  String get formattedTime => TimerPrecision.seconds.formatDuration(_remainingTime);
  bool get isRunning => _state.isRunning;
  bool get isPaused => _state.isPaused;
  bool get canPause => _state.canPause;
  bool get canStart => _state.canStart;
  bool get canStop => _state.canStop;

  EnhancedTimerProvider([TimerSettingsProvider? settingsProvider]) {
    _settingsProvider = settingsProvider;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _storage.initialize();
      
      // Initialize notifications with error handling for web
      try {
        await _notifications.initialize();
      } catch (e) {
        if (kIsWeb) {
          debugPrint('Notification initialization skipped for web: $e');
        } else {
          rethrow;
        }
      }
      
      await _loadSettings();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _handleError('Failed to initialize timer services', e);
    }
  }
  
  Future<void> _loadSettings() async {
    try {
      final settings = await _storage.getCachedData('timer_settings');
      if (settings != null) {
        _currentType = TimerType.values.firstWhere(
          (type) => type.toString() == settings['currentType'],
          orElse: () => TimerType.pomodoro,
        );
        _totalTime = _getCustomDurationForType(_currentType);
        _remainingTime = _totalTime;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        notifyListeners();
      } else {
        _completeSession();
      }
    });
  }
  
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
  
  void _completeSession() {
    _stopTimer();
    _state = TimerState.completed;
    _sessionCount++;
    _showNotification();
    _saveSession();
    _recordCompletedSessionAnalytics();
    notifyListeners();
  }
  
  Future<void> _showNotification() async {
    try {
      if (kIsWeb) {
        // Skip notifications on web or use alternative notification method
        debugPrint('Session completed: ${_currentType.name}');
        return;
      }
      
      // Create a basic timer session for notification
      final session = TimerSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _currentType,
        plannedDuration: _totalTime.inMilliseconds,
        actualDuration: _totalTime.inMilliseconds,
        startTime: _startTime ?? DateTime.now(),
        endTime: DateTime.now(),
        completed: true,
      );
      await _notifications.showSessionCompletedNotification(session);
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
  
  Future<void> _saveSession() async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final session = {
        'id': sessionId,
        'type': _currentType.toString(),
        'duration': _totalTime.inMinutes,
        'completedAt': DateTime.now().toIso8601String(),
        'taskId': _currentTaskId,
      };
      await _storage.cacheData('timer_session_$sessionId', session);
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  // Record completed session to Firestore analytics
  Future<void> _recordCompletedSessionAnalytics() async {
    try {
      if (_startTime != null && _currentType == TimerType.pomodoro) {
        // Only record focus/work sessions, not breaks
        await SessionIntegrationService.instance.recordCompletedSession(
          startTime: _startTime!,
          endTime: DateTime.now(),
          durationMinutes: _totalTime.inMinutes,
          taskId: _currentTaskId,
        );
      }
    } catch (e) {
      debugPrint('Error recording completed session analytics: $e');
    }
  }

  // Record interrupted session to Firestore analytics
  Future<void> _recordInterruptedSessionAnalytics() async {
    try {
      if (_startTime != null && _currentType == TimerType.pomodoro) {
        // Only record focus/work sessions, not breaks
        final now = DateTime.now();
        final elapsedDuration = now.difference(_startTime!);
        final actualMinutes = elapsedDuration.inMinutes;
        
        if (actualMinutes > 0) { // Only record if some time has passed
          await SessionIntegrationService.instance.recordInterruptedSession(
            startTime: _startTime!,
            interruptedTime: now,
            actualMinutes: actualMinutes,
            plannedMinutes: _totalTime.inMinutes,
            taskId: _currentTaskId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error recording interrupted session analytics: $e');
    }
  }

  Future<void> startTimer({
    TimerType? type,
    int? customDurationMinutes,
    String? taskId,
  }) async {
    try {
      _currentTaskId = taskId;
      _currentType = type ?? TimerType.pomodoro;
      
      if (customDurationMinutes != null) {
        _totalTime = Duration(minutes: customDurationMinutes);
      } else {
        _totalTime = _getCustomDurationForType(_currentType);
      }
      
      _remainingTime = _totalTime;
      _state = TimerState.running;
      _startTime = DateTime.now();
      _startTimer();
      _clearError();
      
      notifyListeners();
    } catch (e) {
      _handleError('Failed to start timer', e);
    }
  }

  Future<void> pauseTimer() async {
    try {
      if (_state.canPause) {
        _stopTimer();
        _state = TimerState.paused;
        notifyListeners();
      }
    } catch (e) {
      _handleError('Failed to pause timer', e);
    }
  }

  Future<void> resumeTimer() async {
    try {
      if (_state.isPaused) {
        _state = TimerState.running;
        _startTimer();
        notifyListeners();
      }
    } catch (e) {
      _handleError('Failed to resume timer', e);
    }
  }

  Future<void> stopTimer() async {
    try {
      // Record as interrupted session if timer was running
      if (_state.isRunning && _startTime != null) {
        await _recordInterruptedSessionAnalytics();
      }
      
      _stopTimer();
      _state = TimerState.idle;
      _remainingTime = _totalTime;
      _currentTaskId = null;
      notifyListeners();
    } catch (e) {
      _handleError('Failed to stop timer', e);
    }
  }

  Future<void> completeSession() async {
    try {
      _completeSession();
    } catch (e) {
      _handleError('Failed to complete session', e);
    }
  }

  Future<void> skipSession() async {
    try {
      _stopTimer();
      _state = TimerState.cancelled;
      _sessionCount++;
      notifyListeners();
    } catch (e) {
      _handleError('Failed to skip session', e);
    }
  }

  void setCurrentTask(String? taskId) {
    _currentTaskId = taskId;
    notifyListeners();
  }

  Future<void> updateTimerType(TimerType type) async {
    try {
      if (_state.isIdle) {
        _currentType = type;
        _totalTime = _getCustomDurationForType(type);
        _remainingTime = _totalTime;
        await _saveSettings();
        notifyListeners();
      }
    } catch (e) {
      _handleError('Failed to update timer type', e);
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final settings = {
        'currentType': _currentType.toString(),
        'sessionCount': _sessionCount,
      };
      await _storage.cacheData('timer_settings', settings);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Map<String, dynamic> getStatistics() {
    return {
      'sessionCount': _sessionCount,
      'currentType': _currentType.displayName,
      'state': _state.toString(),
      'totalTime': _totalTime.inMinutes,
      'remainingTime': _remainingTime.inMinutes,
      'lastError': _lastError,
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> runDiagnostics() async {
    try {
      return {
        'timer': {
          'state': _state.toString(),
          'type': _currentType.displayName,
          'isInitialized': _isInitialized,
        },
        'storage': {
          'available': true,
          'type': 'OptimizedStorageService',
        },
        'notifications': {
          'available': true,
          'type': 'NotificationManager',
        },
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }


  void _handleError(String message, dynamic error) {
    _lastError = message;
    _lastErrorTime = DateTime.now();
    debugPrint('EnhancedTimerProvider Error: $message - $error');
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    _lastErrorTime = null;
  }

  // Get custom duration for timer type
  Duration _getCustomDurationForType(TimerType type) {
    if (_settingsProvider != null) {
      final minutes = _settingsProvider!.getDurationForType(type);
      return Duration(minutes: minutes);
    }
    return type.defaultDuration;
  }

  // Update custom duration for current timer type
  Future<void> updateCustomDuration(int minutes) async {
    try {
      if (_state.isIdle && _settingsProvider != null) {
        await _settingsProvider!.setDurationForType(_currentType, minutes);
        _totalTime = Duration(minutes: minutes);
        _remainingTime = _totalTime;
        notifyListeners();
      }
    } catch (e) {
      _handleError('Failed to update custom duration', e);
    }
  }

  // Get current custom duration in minutes
  int getCurrentCustomDuration() {
    if (_settingsProvider != null) {
      return _settingsProvider!.getDurationForType(_currentType);
    }
    return _currentType.defaultDuration.inMinutes;
  }

  // Set settings provider reference
  void setSettingsProvider(TimerSettingsProvider provider) {
    _settingsProvider = provider;
  }

  // Check if should show long break based on session count
  bool shouldShowLongBreak() {
    if (_settingsProvider != null) {
      return _sessionCount > 0 && 
             _sessionCount % _settingsProvider!.settings.longBreakInterval == 0;
    }
    return _sessionCount > 0 && _sessionCount % 4 == 0;
  }

  // Get next recommended timer type
  TimerType getNextRecommendedType() {
    if (_currentType == TimerType.pomodoro) {
      return shouldShowLongBreak() ? TimerType.longBreak : TimerType.shortBreak;
    }
    return TimerType.pomodoro;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
