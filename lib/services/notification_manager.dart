import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/timer_session.dart';
import 'advanced_timer_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialized = false;

  // Notification IDs
  static const int _sessionCompleteId = 1000;
  static const int _milestoneBaseId = 2000;
  static const int _recoveryId = 3000;
  static const int _errorId = 4000;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_launcher');

    // iOS settings - Fixed: Removed criticalAlert parameter
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // Request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // Request notification permissions
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Request critical alert permission for iOS - Fixed: Use proper method
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Schedule session completion notification
  Future<void> scheduleSessionCompleteNotification(
    TimerSession session,
    DateTime scheduledTime,
  ) async {
    if (!_initialized) await initialize();

    final title = _getSessionCompleteTitle(session.type);
    final body = _getSessionCompleteBody(session.type);

    await _notificationsPlugin.zonedSchedule(
      _sessionCompleteId,
      title,
      body,
      _toTZDateTime(scheduledTime),
      _getHighPriorityNotificationDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'session_complete:${session.id}',
    );
  }

  /// Schedule milestone notification (e.g., 5 minutes remaining)
  Future<void> scheduleMilestoneNotification(
    int minutesRemaining,
    DateTime scheduledTime,
  ) async {
    if (!_initialized) await initialize();

    final id = _milestoneBaseId + minutesRemaining;

    await _notificationsPlugin.zonedSchedule(
      id,
      'Focus Timer',
      '$minutesRemaining minutes remaining in your session',
      _toTZDateTime(scheduledTime),
      _getMilestoneNotificationDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'milestone:$minutesRemaining',
    );
  }

  /// Show immediate notification for timer events
  Future<void> showTimerStartedNotification(TimerSession session) async {
    if (!_initialized) await initialize();

    final title = _getSessionStartTitle(session.type);
    final body = _getSessionStartBody(session.type);

    await _notificationsPlugin.show(
      _generateNotificationId(),
      title,
      body,
      _getLowPriorityNotificationDetails(),
      payload: 'timer_started:${session.id}',
    );
  }

  /// Show session completed notification
  Future<void> showSessionCompletedNotification(TimerSession session) async {
    if (!_initialized) await initialize();

    final title = _getSessionCompleteTitle(session.type);
    final body = _getSessionCompleteBody(session.type);

    await _notificationsPlugin.show(
      _sessionCompleteId,
      title,
      body,
      _getHighPriorityNotificationDetails(),
      payload: 'session_completed:${session.id}',
    );
  }

  /// Show milestone notification
  Future<void> showMilestoneNotification(int minutes) async {
    if (!_initialized) await initialize();

    await _notificationsPlugin.show(
      _milestoneBaseId + minutes,
      'Focus Timer',
      '$minutes minutes remaining',
      _getMilestoneNotificationDetails(),
      payload: 'milestone:$minutes',
    );
  }

  /// Show session recovery notification
  Future<void> showSessionRecoveryNotification(TimerSession session) async {
    if (!_initialized) await initialize();

    await _notificationsPlugin.show(
      _recoveryId,
      'Resume Timer Session',
      'You have an unfinished ${_getTimerTypeName(session.type)} session. Would you like to resume?',
      _getRecoveryNotificationDetails(),
      payload: 'recovery:${session.id}',
    );
  }

  /// Show error notification
  Future<void> showErrorNotification(String message) async {
    if (!_initialized) await initialize();

    await _notificationsPlugin.show(
      _errorId,
      'Timer Error',
      message,
      _getErrorNotificationDetails(),
      payload: 'error',
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelScheduledNotifications() async {
    if (!_initialized) return;
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    await _notificationsPlugin.cancel(id);
  }

  // Private helper methods

  NotificationDetails _getHighPriorityNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_critical',
        'Timer Critical',
        channelDescription: 'Critical timer notifications',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        enableVibration: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('timer_complete'),
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableLights: true,
        ledColor: const Color(0xFF00FF00),
        ledOnMs: 1000,
        ledOffMs: 500,
        fullScreenIntent: true,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'start_break',
            'Start Break',
            icon: DrawableResourceAndroidBitmap('ic_play'),
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'start_work',
            'Start Work',
            icon: DrawableResourceAndroidBitmap('ic_work'),
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'timer_complete.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'timer_complete',
      ),
    );
  }

  NotificationDetails _getMilestoneNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_milestone',
        'Timer Milestones',
        channelDescription: 'Timer milestone notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('milestone'),
        vibrationPattern: Int64List.fromList([0, 500]),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        sound: 'milestone.wav',
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  NotificationDetails _getLowPriorityNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_info',
        'Timer Information',
        channelDescription: 'Timer information notifications',
        importance: Importance.low,
        priority: Priority.low,
        enableVibration: false,
        playSound: false,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );
  }

  NotificationDetails _getRecoveryNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_recovery',
        'Timer Recovery',
        channelDescription: 'Timer session recovery notifications',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        playSound: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'resume_session',
            'Resume',
            icon: DrawableResourceAndroidBitmap('ic_play'),
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'cancel_session',
            'Cancel',
            icon: DrawableResourceAndroidBitmap('ic_cancel'),
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: 'timer_recovery',
      ),
    );
  }

  NotificationDetails _getErrorNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_error',
        'Timer Errors',
        channelDescription: 'Timer error notifications',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.error,
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  String _getSessionCompleteTitle(TimerType type) {
    switch (type) {
      case TimerType.work:
        return 'Work Session Complete! 🎉';
      case TimerType.shortBreak:
        return 'Short Break Complete! ⚡';
      case TimerType.longBreak:
        return 'Long Break Complete! 🌟';
      case TimerType.custom:
        return 'Custom Session Complete! ✅';
    }
  }

  String _getSessionCompleteBody(TimerType type) {
    switch (type) {
      case TimerType.work:
        return 'Great focus! Time for a well-deserved break.';
      case TimerType.shortBreak:
        return 'Refreshed and ready? Let\'s get back to work!';
      case TimerType.longBreak:
        return 'You\'ve earned this longer break. Ready for the next cycle?';
      case TimerType.custom:
        return 'Your custom session is complete!';
    }
  }

  String _getSessionStartTitle(TimerType type) {
    switch (type) {
      case TimerType.work:
        return 'Focus Time Started! 💪';
      case TimerType.shortBreak:
        return 'Short Break Started! 😌';
      case TimerType.longBreak:
        return 'Long Break Started! 🛌';
      case TimerType.custom:
        return 'Custom Session Started! ⏱️';
    }
  }

  String _getSessionStartBody(TimerType type) {
    switch (type) {
      case TimerType.work:
        return 'Stay focused and minimize distractions.';
      case TimerType.shortBreak:
        return 'Take a moment to relax and recharge.';
      case TimerType.longBreak:
        return 'Enjoy this extended break!';
      case TimerType.custom:
        return 'Your custom timer is now running.';
    }
  }

  String _getTimerTypeName(TimerType type) {
    switch (type) {
      case TimerType.work:
        return 'work';
      case TimerType.shortBreak:
        return 'short break';
      case TimerType.longBreak:
        return 'long break';
      case TimerType.custom:
        return 'custom';
    }
  }

  tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    final location = tz.getLocation('UTC');
    return tz.TZDateTime.from(dateTime, location);
  }

  int _generateNotificationId() {
    return Random().nextInt(999999) + 10000;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationAction(payload, response.actionId);
    }
  }

  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle background notification action
      _handleBackgroundNotificationAction(payload, response.actionId);
    }
  }

  void _handleNotificationAction(String payload, String? actionId) {
    final parts = payload.split(':');
    if (parts.length < 2) return;

    final action = parts[0];
    // Fixed: Removed unused variable 'data'

    switch (action) {
      case 'session_complete':
      case 'session_completed':
        if (actionId == 'start_break') {
          // Start break session
          // AdvancedTimerService().startTimer(type: TimerType.shortBreak);
        } else if (actionId == 'start_work') {
          // Start work session
          // AdvancedTimerService().startTimer(type: TimerType.work);
        }
        break;
      case 'recovery':
        if (actionId == 'resume_session') {
          // Resume the session
          // AdvancedTimerService().resumeTimer();
        } else if (actionId == 'cancel_session') {
          // Cancel the session
          // AdvancedTimerService().stopTimer();
        }
        break;
      case 'milestone':
        // Handle milestone notification tap
        break;
    }
  }

  static void _handleBackgroundNotificationAction(
      String payload, String? actionId) {
    // Handle background notification actions
    // This runs in background, so limited functionality
  }

  void dispose() {
    cancelScheduledNotifications();
  }
}
