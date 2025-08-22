import 'dart:async';
import 'dart:isolate';
import 'package:workmanager/workmanager.dart';
import '../models/timer_session.dart';
import 'notification_manager.dart';
import '../services/advanced_timer_service.dart';
import 'session_recovery_service.dart';

class BackgroundTaskHandler {
  static const String _timerTaskName = 'timer_background_task';
  static const String _heartbeatTaskName = 'timer_heartbeat_task';
  static const String _recoveryTaskName = 'timer_recovery_task';

  static final BackgroundTaskHandler _instance =
      BackgroundTaskHandler._internal();
  factory BackgroundTaskHandler() => _instance;
  BackgroundTaskHandler._internal();

  bool _initialized = false;
  SendPort? _backgroundSendPort;
  ReceivePort? _backgroundReceivePort;

  Future<void> initialize() async {
    if (_initialized) return;

    await Workmanager().initialize(
      _backgroundTaskEntryPoint,
      isInDebugMode: false, // Set to true for debugging
    );

    await _initializeIsolateChannel();
    _initialized = true;
  }

  /// Schedule background timer completion task
  Future<void> scheduleTimerTask(
      TimerSession session, DateTime completionTime) async {
    if (!_initialized) await initialize();

    final delay = completionTime.difference(DateTime.now());

    await Workmanager().registerOneOffTask(
      '${_timerTaskName}_${session.id}',
      _timerTaskName,
      initialDelay: delay,
      inputData: {
        'sessionId': session.id,
        'sessionType': session.type.name,
        'completionTime': completionTime.toIso8601String(),
        'plannedDuration': session.plannedDuration,
      },
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Schedule heartbeat task for session monitoring
  Future<void> scheduleHeartbeatTask() async {
    if (!_initialized) await initialize();

    await Workmanager().registerPeriodicTask(
      _heartbeatTaskName,
      _heartbeatTaskName,
      frequency: const Duration(minutes: 15), // Minimum allowed by Android
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Schedule recovery check task
  Future<void> scheduleRecoveryTask() async {
    if (!_initialized) await initialize();

    await Workmanager().registerOneOffTask(
      _recoveryTaskName,
      _recoveryTaskName,
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  /// Cancel background tasks for session
  Future<void> cancelTimerTask(String sessionId) async {
    if (!_initialized) return;

    await Workmanager().cancelByUniqueName('${_timerTaskName}_$sessionId');
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    if (!_initialized) return;

    await Workmanager().cancelAll();
  }

  /// Send message to background isolate
  Future<void> sendToBackground(Map<String, dynamic> message) async {
    _backgroundSendPort?.send(message);
  }

  /// Create communication channel with background isolate
  Future<void> _initializeIsolateChannel() async {
    _backgroundReceivePort = ReceivePort();

    await Isolate.spawn(
      _backgroundIsolateEntryPoint,
      _backgroundReceivePort!.sendPort,
    );

    _backgroundSendPort = await _backgroundReceivePort!.first as SendPort;

    _backgroundReceivePort!.listen((message) {
      _handleBackgroundMessage(message);
    });
  }

  /// Handle messages from background isolate
  void _handleBackgroundMessage(dynamic message) {
    if (message is Map<String, dynamic>) {
      switch (message['type']) {
        case 'timer_complete':
          _handleTimerComplete(message);
          break;
        case 'heartbeat':
          _handleHeartbeat(message);
          break;
        case 'error':
          _handleBackgroundError(message);
          break;
      }
    }
  }

  void _handleTimerComplete(Map<String, dynamic> message) {
    // Handle timer completion from background
    final sessionId = message['sessionId'] as String?;
    if (sessionId != null) {
      // Trigger notification and update app state
      NotificationManager().showSessionCompletedNotification(
        TimerSession.fromJson(message['session']),
      );
    }
  }

  void _handleHeartbeat(Map<String, dynamic> message) {
    // Handle heartbeat from background
    final timestamp = message['timestamp'] as String?;
    if (timestamp != null) {
      // Update heartbeat timestamp
    }
  }

  void _handleBackgroundError(Map<String, dynamic> message) {
    // Handle error from background isolate
    final error = message['error'] as String?;
    if (error != null) {
      NotificationManager()
          .showErrorNotification('Background task error: $error');
    }
  }

  void dispose() {
    _backgroundReceivePort?.close();
    cancelAllTasks();
  }
}

/// Background isolate entry point
void _backgroundIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  Timer? heartbeatTimer;

  receivePort.listen((message) {
    if (message is Map<String, dynamic>) {
      switch (message['action']) {
        case 'start_heartbeat':
          heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
            mainSendPort.send({
              'type': 'heartbeat',
              'timestamp': DateTime.now().toIso8601String(),
            });
          });
          break;

        case 'stop_heartbeat':
          heartbeatTimer?.cancel();
          break;

        case 'timer_complete':
          mainSendPort.send({
            'type': 'timer_complete',
            'sessionId': message['sessionId'],
            'session': message['session'],
          });
          break;
      }
    }
  });
}

/// Workmanager background task entry point
@pragma('vm:entry-point')
void _backgroundTaskEntryPoint() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case BackgroundTaskHandler._timerTaskName:
          return await _executeTimerTask(inputData);

        case BackgroundTaskHandler._heartbeatTaskName:
          return await _executeHeartbeatTask(inputData);

        case BackgroundTaskHandler._recoveryTaskName:
          return await _executeRecoveryTask(inputData);

        default:
          return Future.value(true);
      }
    } catch (e) {
      // Log error and show notification
      await NotificationManager()
          .showErrorNotification('Background task failed: $e');
      return Future.value(false);
    }
  });
}

/// Execute timer completion task
Future<bool> _executeTimerTask(Map<String, dynamic>? inputData) async {
  if (inputData == null) return false;

  try {
    final sessionId = inputData['sessionId'] as String?;
    final sessionType = inputData['sessionType'] as String?;
    final completionTimeString = inputData['completionTime'] as String?;
    final plannedDuration = inputData['plannedDuration'] as int?;

    if (sessionId == null ||
        sessionType == null ||
        completionTimeString == null) {
      return false;
    }

    final completionTime = DateTime.parse(completionTimeString);
    final now = DateTime.now();

    // Check if we're close to the expected completion time (within 1 minute)
    final timeDifference = now.difference(completionTime).abs();
    if (timeDifference.inMinutes <= 1) {
      // Create session object for notification
      final session = TimerSession(
        id: sessionId,
        type: TimerType.values.firstWhere((t) => t.name == sessionType),
        plannedDuration: plannedDuration ?? 0,
        startTime: completionTime
            .subtract(Duration(milliseconds: plannedDuration ?? 0)),
        endTime: now,
        completed: true,
      );

      // Show completion notification
      await NotificationManager().showSessionCompletedNotification(session);

      return true;
    }

    return false;
  } catch (e) {
    return false;
  }
}

/// Execute heartbeat monitoring task
Future<bool> _executeHeartbeatTask(Map<String, dynamic>? inputData) async {
  try {
    // Check for stale sessions and recovery needs
    final recoveryService = SessionRecoveryService();
    await recoveryService.initialize();

    final needsRecovery = await recoveryService.detectCrashRecovery();
    if (needsRecovery) {
      final pendingSession = await recoveryService.getPendingSession();
      if (pendingSession != null) {
        await NotificationManager()
            .showSessionRecoveryNotification(pendingSession);
      }
    }

    return true;
  } catch (e) {
    return false;
  }
}

/// Execute recovery check task
Future<bool> _executeRecoveryTask(Map<String, dynamic>? inputData) async {
  try {
    // Perform recovery checks
    final recoveryService = SessionRecoveryService();
    await recoveryService.initialize();

    final needsRecovery = await recoveryService.detectCrashRecovery();
    if (needsRecovery) {
      // Show recovery notification
      final pendingSession = await recoveryService.getPendingSession();
      if (pendingSession != null) {
        await NotificationManager()
            .showSessionRecoveryNotification(pendingSession);
      }
    }

    return true;
  } catch (e) {
    return false;
  }
}
