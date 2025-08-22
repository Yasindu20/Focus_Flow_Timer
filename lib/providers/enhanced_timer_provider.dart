import 'package:flutter/material.dart';
import '../services/advanced_timer_service.dart';
import '../services/audio_service.dart';
import '../services/analytics_service.dart';
import '../models/pomodoro_session.dart';
import 'package:uuid/uuid.dart';

class TimerProvider extends ChangeNotifier {
  final TimerService _timerService = TimerService();
  final AudioService _audioService = AudioService();

  String? _currentTaskId;
  PomodoroSession? _currentSession;

  // Getters
  TimerService get timerService => _timerService;
  AudioService get audioService => _audioService;
  String? get currentTaskId => _currentTaskId;
  PomodoroSession? get currentSession => _currentSession;

  TimerProvider() {
    _timerService.addListener(() {
      notifyListeners();
    });

    _timerService.onSessionComplete = _onSessionComplete;
  }

  void setCurrentTask(String? taskId) {
    _currentTaskId = taskId;
    notifyListeners();
  }

  void startTimer({String? taskId}) {
    _currentTaskId = taskId;

    // Create new session
    _currentSession = PomodoroSession(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      duration: _timerService.currentType == TimerType.work
          ? 25
          : _timerService.currentType == TimerType.shortBreak
              ? 5
              : 15,
      type: _mapTimerTypeToSessionType(_timerService.currentType),
      completed: false,
      taskId: taskId,
    );

    _timerService.startTimer();
    notifyListeners();
  }

  void pauseTimer() {
    _timerService.pauseTimer();
    notifyListeners();
  }

  void resumeTimer() {
    _timerService.resumeTimer();
    notifyListeners();
  }

  void stopTimer() {
    _finalizeCurrentSession(false);
    _timerService.stopTimer();
    notifyListeners();
  }

  void resetTimer() {
    _finalizeCurrentSession(false);
    _timerService.resetTimer();
    notifyListeners();
  }

  void skipSession() {
    _finalizeCurrentSession(true);
    _timerService.skipSession();
    notifyListeners();
  }

  void _onSessionComplete() {
    _finalizeCurrentSession(true);
    notifyListeners();
  }

  void _finalizeCurrentSession(bool completed) {
    if (_currentSession != null) {
      final session = PomodoroSession(
        id: _currentSession!.id,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        duration: _currentSession!.duration,
        type: _currentSession!.type,
        completed: completed,
        taskId: _currentSession!.taskId,
      );

      AnalyticsService.recordSession(session);
      _currentSession = null;
    }
  }

  SessionType _mapTimerTypeToSessionType(TimerType type) {
    switch (type) {
      case TimerType.work:
        return SessionType.work;
      case TimerType.shortBreak:
        return SessionType.shortBreak;
      case TimerType.longBreak:
        return SessionType.longBreak;
    }
  }

  @override
  void dispose() {
    _timerService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
