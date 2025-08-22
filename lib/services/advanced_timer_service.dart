import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_session.dart';
import '../models/timer_settings.dart';
import 'notification_manager.dart';
import 'session_recovery_service.dart';

enum TimerState { idle, running, paused, completed, interrupted, recovering }

enum TimerType { work, shortBreak, longBreak, custom }

enum TimerPrecision {
  second, // 1000ms precision
  decisecond, // 100ms precision
  centisecond, // 10ms precision
  millisecond // 1ms precision
}

class AdvancedTimerService extends ChangeNotifier {
  static final AdvancedTimerService _instance =
      AdvancedTimerService._internal();
  factory AdvancedTimerService() => _instance;
  AdvancedTimerService._internal();

  // Core timer properties
  Timer? _primaryTimer;
  Timer? _precisionTimer;
  Stopwatch _stopwatch = Stopwatch();

  // State management
  TimerState _state = TimerState.idle;
  TimerType _currentType = TimerType.work;
  TimerSession? _currentSession;

  // Precision timing
  TimerPrecision _precision = TimerPrecision.centisecond;
  int _targetDurationMs = 0;
  int _elapsedMs = 0;
  int _pausedMs = 0;

  // Session management
  int _sessionCount = 0;
  int _workSessionsCompleted = 0;
  DateTime? _sessionStartTime;
  DateTime? _lastPauseTime;

  // Configuration
  TimerSettings _settings = TimerSettings.defaultSettings();

  // Services
  final NotificationManager _notificationManager = NotificationManager();
  final SessionRecoveryService _recoveryService = SessionRecoveryService();

  // Background isolation
  Isolate? _timingIsolate;
  ReceivePort? _isolateReceivePort;
  SendPort? _isolateSendPort;

  // Getters
  TimerState get state => _state;
  TimerType get currentType => _currentType;
  TimerSession? get currentSession => _currentSession;
  TimerSettings get settings => _settings;
  TimerPrecision get precision => _precision;

  int get sessionCount => _sessionCount;
  int get workSessionsCompleted => _workSessionsCompleted;
  int get targetDurationMs => _targetDurationMs;
  int get elapsedMs => _elapsedMs;
  int get remainingMs => _targetDurationMs - _elapsedMs;

  double get progress =>
      _targetDurationMs > 0 ? _elapsedMs / _targetDurationMs : 0.0;

  String get formattedTime => _formatDuration(remainingMs);
  String get formattedElapsed => _formatDuration(_elapsedMs);

  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isCompleted => _state == TimerState.completed;
  bool get canPause => _state == TimerState.running;
  bool get canResume => _state == TimerState.paused;
  bool get canReset => _state != TimerState.idle;

  // Callbacks
  VoidCallback? onSessionComplete;
  VoidCallback? onSessionStart;
  VoidCallback? onSessionPause;
  VoidCallback? onSessionResume;
  Function(String)? onInterruption;

  /// Initialize the advanced timer service
  Future<void> initialize() async {
    await _loadSettings();
    await _notificationManager.initialize();
    await _recoveryService.initialize();
    await _checkForPendingSessions();
    await _initializePrecisionTiming();
  }

  /// Set timer precision level
  void setPrecision(TimerPrecision precision) {
    _precision = precision;
    _savePrecisionSetting();
    notifyListeners();
  }

  /// Start a new timer session
  Future<void> startTimer({
    TimerType? type,
    int? customDurationMinutes,
    String? taskId,
    bool resumeSession = false,
  }) async {
    try {
      if (!resumeSession) {
        await _prepareNewSession(type, customDurationMinutes, taskId);
      }

      await _startTimingEngine();
      await _scheduleBackgroundNotifications();
      await _notificationManager.showTimerStartedNotification(_currentSession!);

      _state = TimerState.running;
      _sessionStartTime = DateTime.now();
      _stopwatch.start();

      onSessionStart?.call();
      notifyListeners();
    } catch (e) {
      await _handleTimerError('Failed to start timer', e);
    }
  }

  /// Pause the current timer session
  Future<void> pauseTimer() async {
    if (!canPause) return;

    try {
      _stopwatch.stop();
      _lastPauseTime = DateTime.now();
      _state = TimerState.paused;

      await _pauseTimingEngine();
      await _notificationManager.cancelScheduledNotifications();
      await _recoveryService.saveSessionState(_currentSession!);

      onSessionPause?.call();
      notifyListeners();
    } catch (e) {
      await _handleTimerError('Failed to pause timer', e);
    }
  }

  /// Resume a paused timer session
  Future<void> resumeTimer() async {
    if (!canResume) return;

    try {
      if (_lastPauseTime != null) {
        final pauseDuration = DateTime.now().difference(_lastPauseTime!);
        _pausedMs += pauseDuration.inMilliseconds;
      }

      _stopwatch.start();
      _state = TimerState.running;

      await _resumeTimingEngine();
      await _scheduleBackgroundNotifications();

      onSessionResume?.call();
      notifyListeners();
    } catch (e) {
      await _handleTimerError('Failed to resume timer', e);
    }
  }

  /// Stop and reset the current timer
  Future<void> stopTimer() async {
    try {
      await _stopTimingEngine();
      await _notificationManager.cancelScheduledNotifications();

      if (_currentSession != null) {
        _currentSession!.endTime = DateTime.now();
        _currentSession!.completed = false;
        await _recoveryService.archiveSession(_currentSession!);
      }

      _resetTimerState();
      notifyListeners();
    } catch (e) {
      await _handleTimerError('Failed to stop timer', e);
    }
  }

  /// Complete the current session and move to next
  Future<void> completeSession() async {
    try {
      await _stopTimingEngine();

      if (_currentSession != null) {
        _currentSession!.endTime = DateTime.now();
        _currentSession!.completed = true;
        _currentSession!.actualDuration = _elapsedMs;

        await _recoveryService.archiveSession(_currentSession!);
        await _notificationManager
            .showSessionCompletedNotification(_currentSession!);
      }

      _updateSessionCounts();
      await _transitionToNextSession();

      onSessionComplete?.call();
      notifyListeners();
    } catch (e) {
      await _handleTimerError('Failed to complete session', e);
    }
  }

  /// Skip current session
  Future<void> skipSession() async {
    await completeSession();
  }

  /// Handle interruptions (calls, etc.)
  Future<void> handleInterruption(String reason) async {
    if (_state == TimerState.running) {
      _state = TimerState.interrupted;
      await pauseTimer();
      onInterruption?.call(reason);

      // Schedule auto-resume if settings allow
      if (_settings.autoResumeAfterInterruption) {
        Timer(Duration(seconds: _settings.autoResumeDelaySeconds), () {
          if (_state == TimerState.interrupted) {
            resumeTimer();
          }
        });
      }
    }
  }

  /// Configure custom timer duration
  void setCustomDuration(int minutes) {
    if (minutes >= 1 && minutes <= 180) {
      _settings.customWorkDuration = minutes;
      _saveSettings();
      notifyListeners();
    }
  }

  /// Update timer settings
  Future<void> updateSettings(TimerSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  /// Get timer statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalSessions': _sessionCount,
      'workSessionsCompleted': _workSessionsCompleted,
      'currentStreak': _calculateCurrentStreak(),
      'averageSessionLength': _calculateAverageSessionLength(),
      'totalFocusTime': _calculateTotalFocusTime(),
      'productivityScore': _calculateProductivityScore(),
    };
  }

  // Private methods

  Future<void> _prepareNewSession(
      TimerType? type, int? customDurationMinutes, String? taskId) async {
    _currentType = type ?? _determineNextSessionType();

    final durationMinutes =
        customDurationMinutes ?? _getSessionDuration(_currentType);
    _targetDurationMs = durationMinutes * 60 * 1000;
    _elapsedMs = 0;
    _pausedMs = 0;

    _currentSession = TimerSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _currentType,
      plannedDuration: _targetDurationMs,
      startTime: DateTime.now(),
      taskId: taskId,
    );

    await _recoveryService.saveSessionState(_currentSession!);
  }

  TimerType _determineNextSessionType() {
    if (_currentType == TimerType.work) {
      _workSessionsCompleted++;
      if (_workSessionsCompleted % _settings.longBreakInterval == 0) {
        return TimerType.longBreak;
      } else {
        return TimerType.shortBreak;
      }
    } else {
      return TimerType.work;
    }
  }

  int _getSessionDuration(TimerType type) {
    switch (type) {
      case TimerType.work:
        return _settings.workDuration;
      case TimerType.shortBreak:
        return _settings.shortBreakDuration;
      case TimerType.longBreak:
        return _settings.longBreakDuration;
      case TimerType.custom:
        return _settings.customWorkDuration;
    }
  }

  Future<void> _startTimingEngine() async {
    _stopwatch.reset();

    // High precision timer for UI updates
    final updateInterval = _getPrecisionInterval();
    _precisionTimer = Timer.periodic(updateInterval, _updateTimerProgress);

    // Primary timer for session completion
    _primaryTimer =
        Timer(Duration(milliseconds: _targetDurationMs - _elapsedMs), () {
      completeSession();
    });

    // Initialize background timing isolate for critical precision
    if (_settings.useHighPrecisionTiming) {
      await _initializeTimingIsolate();
    }
  }

  Duration _getPrecisionInterval() {
    switch (_precision) {
      case TimerPrecision.second:
        return Duration(seconds: 1);
      case TimerPrecision.decisecond:
        return Duration(milliseconds: 100);
      case TimerPrecision.centisecond:
        return Duration(milliseconds: 10);
      case TimerPrecision.millisecond:
        return Duration(milliseconds: 1);
    }
  }

  void _updateTimerProgress(Timer timer) {
    if (_stopwatch.isRunning) {
      _elapsedMs = _stopwatch.elapsedMilliseconds;

      // Check for completion
      if (_elapsedMs >= _targetDurationMs) {
        timer.cancel();
        completeSession();
        return;
      }

      // Milestone notifications
      _checkForMilestoneNotifications();

      notifyListeners();
    }
  }

  void _checkForMilestoneNotifications() {
    final remaining = remainingMs;
    final minutes = remaining ~/ 60000;

    if (_settings.milestoneNotifications) {
      if (minutes == 10 || minutes == 5 || minutes == 1) {
        final secondsLeft = (remaining % 60000) ~/ 1000;
        if (secondsLeft == 0) {
          _notificationManager.showMilestoneNotification(minutes);
        }
      }
    }
  }

  Future<void> _scheduleBackgroundNotifications() async {
    await _notificationManager.cancelScheduledNotifications();

    final completionTime =
        DateTime.now().add(Duration(milliseconds: remainingMs));
    await _notificationManager.scheduleSessionCompleteNotification(
      _currentSession!,
      completionTime,
    );

    // Schedule milestone notifications
    if (_settings.milestoneNotifications) {
      for (final milestone in [10, 5, 1]) {
        final milestoneMs = milestone * 60 * 1000;
        if (remainingMs > milestoneMs) {
          final notificationTime = DateTime.now()
              .add(Duration(milliseconds: remainingMs - milestoneMs));
          await _notificationManager.scheduleMilestoneNotification(
              milestone, notificationTime);
        }
      }
    }
  }

  Future<void> _initializeTimingIsolate() async {
    _isolateReceivePort = ReceivePort();

    _timingIsolate = await Isolate.spawn(
      _timingIsolateEntryPoint,
      _isolateReceivePort!.sendPort,
    );

    _isolateSendPort = await _isolateReceivePort!.first as SendPort;

    _isolateReceivePort!.listen((message) {
      if (message is Map && message['type'] == 'tick') {
        // Handle high-precision tick from isolate
        _elapsedMs = message['elapsed'] as int;
        notifyListeners();
      }
    });
  }

  static void _timingIsolateEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    final stopwatch = Stopwatch();
    Timer? timer;

    receivePort.listen((message) {
      if (message is Map) {
        switch (message['action']) {
          case 'start':
            stopwatch.start();
            timer = Timer.periodic(Duration(milliseconds: 1), (t) {
              mainSendPort.send({
                'type': 'tick',
                'elapsed': stopwatch.elapsedMilliseconds,
              });
            });
            break;
          case 'pause':
            stopwatch.stop();
            timer?.cancel();
            break;
          case 'resume':
            stopwatch.start();
            timer = Timer.periodic(Duration(milliseconds: 1), (t) {
              mainSendPort.send({
                'type': 'tick',
                'elapsed': stopwatch.elapsedMilliseconds,
              });
            });
            break;
          case 'stop':
            stopwatch.stop();
            timer?.cancel();
            break;
        }
      }
    });
  }

  Future<void> _pauseTimingEngine() async {
    _primaryTimer?.cancel();
    _precisionTimer?.cancel();

    if (_isolateSendPort != null) {
      _isolateSendPort!.send({'action': 'pause'});
    }
  }

  Future<void> _resumeTimingEngine() async {
    final remainingTime = _targetDurationMs - _elapsedMs;

    _primaryTimer = Timer(Duration(milliseconds: remainingTime), () {
      completeSession();
    });

    final updateInterval = _getPrecisionInterval();
    _precisionTimer = Timer.periodic(updateInterval, _updateTimerProgress);

    if (_isolateSendPort != null) {
      _isolateSendPort!.send({'action': 'resume'});
    }
  }

  Future<void> _stopTimingEngine() async {
    _stopwatch.stop();
    _primaryTimer?.cancel();
    _precisionTimer?.cancel();

    if (_isolateSendPort != null) {
      _isolateSendPort!.send({'action': 'stop'});
    }

    if (_timingIsolate != null) {
      _timingIsolate!.kill();
      _timingIsolate = null;
    }

    _isolateReceivePort?.close();
  }

  void _resetTimerState() {
    _state = TimerState.idle;
    _elapsedMs = 0;
    _pausedMs = 0;
    _targetDurationMs = 0;
    _currentSession = null;
    _sessionStartTime = null;
    _lastPauseTime = null;
    _stopwatch.reset();
  }

  void _updateSessionCounts() {
    _sessionCount++;
    if (_currentType == TimerType.work) {
      _workSessionsCompleted++;
    }
  }

  Future<void> _transitionToNextSession() async {
    _state = TimerState.completed;

    // Auto-start next session if enabled
    if (_settings.autoStartBreaks || _settings.autoStartWork) {
      final nextType = _determineNextSessionType();
      final shouldAutoStart =
          (nextType == TimerType.work && _settings.autoStartWork) ||
              (nextType != TimerType.work && _settings.autoStartBreaks);

      if (shouldAutoStart) {
        Timer(Duration(seconds: _settings.autoStartDelaySeconds), () {
          startTimer(type: nextType);
        });
      }
    }
  }

  Future<void> _checkForPendingSessions() async {
    final pendingSession = await _recoveryService.getPendingSession();
    if (pendingSession != null && _shouldRecoverSession(pendingSession)) {
      _state = TimerState.recovering;
      _currentSession = pendingSession;
      _currentType = pendingSession.type;

      // Calculate elapsed time based on start time
      final elapsed = DateTime.now().difference(pendingSession.startTime);
      _elapsedMs = elapsed.inMilliseconds;
      _targetDurationMs = pendingSession.plannedDuration;

      if (_elapsedMs >= _targetDurationMs) {
        // Session should have completed
        await completeSession();
      } else {
        // Offer to resume
        await _notificationManager
            .showSessionRecoveryNotification(pendingSession);
      }
    }
  }

  bool _shouldRecoverSession(TimerSession session) {
    final sessionAge = DateTime.now().difference(session.startTime);
    return sessionAge.inHours < 24; // Only recover sessions within 24 hours
  }

  Future<void> _initializePrecisionTiming() async {
    // Pre-warm timing systems for better accuracy
    final testStopwatch = Stopwatch()..start();
    await Future.delayed(Duration(milliseconds: 1));
    testStopwatch.stop();
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final ms = duration.inMilliseconds.remainder(1000);

    switch (_precision) {
      case TimerPrecision.second:
        if (hours > 0) {
          return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      case TimerPrecision.decisecond:
        final deciseconds = ms ~/ 100;
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${deciseconds}';

      case TimerPrecision.centisecond:
        final centiseconds = ms ~/ 10;
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';

      case TimerPrecision.millisecond:
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
    }
  }

  int _calculateCurrentStreak() {
    // Implementation for calculating current work session streak
    return 0; // Placeholder
  }

  double _calculateAverageSessionLength() {
    // Implementation for calculating average session length
    return 0.0; // Placeholder
  }

  int _calculateTotalFocusTime() {
    // Implementation for calculating total focus time
    return 0; // Placeholder
  }

  double _calculateProductivityScore() {
    // Implementation for calculating productivity score
    return 0.0; // Placeholder
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('advanced_timer_settings');
    if (settingsJson != null) {
      _settings = TimerSettings.fromJson(settingsJson);
    }

    final precisionIndex =
        prefs.getInt('timer_precision') ?? TimerPrecision.centisecond.index;
    _precision = TimerPrecision.values[precisionIndex];
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('advanced_timer_settings', _settings.toJson());
  }

  Future<void> _savePrecisionSetting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timer_precision', _precision.index);
  }

  Future<void> _handleTimerError(String message, dynamic error) async {
    debugPrint('Timer Error: $message - $error');
    await _notificationManager.showErrorNotification(message);

    // Attempt recovery
    _state = TimerState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimingEngine();
    _notificationManager.dispose();
    super.dispose();
  }
}
