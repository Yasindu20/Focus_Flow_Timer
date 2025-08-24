// Timer enums for the free version of Focus Flow Timer

enum TimerState {
  idle,
  running,
  paused,
  completed,
  cancelled,
}

enum TimerType {
  pomodoro,
  shortBreak,
  longBreak,
  custom,
}

enum TimerPrecision {
  seconds,
  tenthSeconds,
  hundredthSeconds,
}

extension TimerStateExtension on TimerState {
  bool get isRunning => this == TimerState.running;
  bool get isPaused => this == TimerState.paused;
  bool get isIdle => this == TimerState.idle;
  bool get isCompleted => this == TimerState.completed;
  bool get isCancelled => this == TimerState.cancelled;
  bool get canStart => this == TimerState.idle || this == TimerState.paused;
  bool get canPause => this == TimerState.running;
  bool get canStop => this == TimerState.running || this == TimerState.paused;
  bool get canReset => this != TimerState.idle;
}

extension TimerTypeExtension on TimerType {
  String get displayName {
    switch (this) {
      case TimerType.pomodoro:
        return 'Pomodoro';
      case TimerType.shortBreak:
        return 'Short Break';
      case TimerType.longBreak:
        return 'Long Break';
      case TimerType.custom:
        return 'Custom';
    }
  }

  Duration get defaultDuration {
    switch (this) {
      case TimerType.pomodoro:
        return const Duration(minutes: 25);
      case TimerType.shortBreak:
        return const Duration(minutes: 5);
      case TimerType.longBreak:
        return const Duration(minutes: 15);
      case TimerType.custom:
        return const Duration(minutes: 30);
    }
  }

  bool get isBreak {
    return this == TimerType.shortBreak || this == TimerType.longBreak;
  }
}

extension TimerPrecisionExtension on TimerPrecision {
  String formatDuration(Duration duration) {
    switch (this) {
      case TimerPrecision.seconds:
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      case TimerPrecision.tenthSeconds:
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        final tenths = (duration.inMilliseconds % 1000) ~/ 100;
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${tenths}';
      case TimerPrecision.hundredthSeconds:
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        final hundredths = (duration.inMilliseconds % 1000) ~/ 10;
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
    }
  }
}