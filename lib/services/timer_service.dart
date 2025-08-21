import 'dart:async';
import 'package:flutter/material.dart';

enum TimerState { stopped, running, paused }

enum TimerType { work, shortBreak, longBreak }

class TimerService extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  TimerState _state = TimerState.stopped;
  TimerType _currentType = TimerType.work;
  int _sessionCount = 0;

  // Getters
  int get remainingSeconds => _remainingSeconds;
  TimerState get state => _state;
  TimerType get currentType => _currentType;
  int get sessionCount => _sessionCount;

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    final totalSeconds = _getCurrentDuration() * 60;
    return totalSeconds > 0 ? (_remainingSeconds / totalSeconds) : 0.0;
  }

  bool get isWork => _currentType == TimerType.work;
  bool get isBreak => _currentType != TimerType.work;

  // Timer controls
  void startTimer() {
    if (_state == TimerState.stopped) {
      _remainingSeconds = _getCurrentDuration() * 60;
    }

    _state = TimerState.running;
    _startCountdown();
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  void resumeTimer() {
    _state = TimerState.running;
    _startCountdown();
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _state = TimerState.stopped;
    _remainingSeconds = 0;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _state = TimerState.stopped;
    _remainingSeconds = _getCurrentDuration() * 60;
    notifyListeners();
  }

  void skipSession() {
    _timer?.cancel();
    _completeSession();
  }

  // Private methods
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeSession();
      }
    });
  }

  void _completeSession() {
    _timer?.cancel();
    _state = TimerState.stopped;

    if (_currentType == TimerType.work) {
      _sessionCount++;
      if (_sessionCount % 4 == 0) {
        _currentType = TimerType.longBreak;
      } else {
        _currentType = TimerType.shortBreak;
      }
    } else {
      _currentType = TimerType.work;
    }

    _remainingSeconds = _getCurrentDuration() * 60;
    notifyListeners();

    // Trigger completion callback if needed
    onSessionComplete?.call();
  }

  int _getCurrentDuration() {
    switch (_currentType) {
      case TimerType.work:
        return 25; // 25 minutes
      case TimerType.shortBreak:
        return 5; // 5 minutes
      case TimerType.longBreak:
        return 15; // 15 minutes
    }
  }

  // Callback for when session completes
  VoidCallback? onSessionComplete;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
