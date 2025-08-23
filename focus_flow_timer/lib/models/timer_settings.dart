import 'dart:convert';

class TimerSettings {
  // Core timer durations (in minutes)
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int customWorkDuration;
  final int longBreakInterval; // After how many work sessions

  // Precision and performance
  final bool useHighPrecisionTiming;
  final bool enableMillisecondDisplay;
  final bool compensateForDrift;

  // Auto-start settings
  final bool autoStartWork;
  final bool autoStartBreaks;
  final int autoStartDelaySeconds;

  // Interruption handling
  final bool autoResumeAfterInterruption;
  final int autoResumeDelaySeconds;
  final bool enableInterruptionDetection;

  // Notification settings
  final bool enableNotifications;
  final bool enableCriticalAlerts;
  final bool milestoneNotifications;
  final bool enableVibration;
  final bool enableLEDIndicator;

  // Audio settings
  final bool enableCompletionSounds;
  final bool enableAmbientSounds;
  final String selectedAmbientSound;
  final double ambientSoundVolume;
  final String completionSoundSet;

  // Background operation
  final bool enableBackgroundOperation;
  final bool enableWakeLock;
  final bool enableBatteryOptimization;
  final int backgroundTaskPriority;

  // Advanced features
  final bool enableSessionRecovery;
  final bool enablePerformanceMonitoring;
  final bool enableDiagnostics;
  final bool enableAnalytics;

  // Customization
  final Map<String, int> customSessionDurations;
  final Map<String, String> soundProfiles;
  final Map<String, bool> featureFlags;

  const TimerSettings({
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.customWorkDuration = 25,
    this.longBreakInterval = 4,
    this.useHighPrecisionTiming = true,
    this.enableMillisecondDisplay = false,
    this.compensateForDrift = true,
    this.autoStartWork = false,
    this.autoStartBreaks = false,
    this.autoStartDelaySeconds = 3,
    this.autoResumeAfterInterruption = true,
    this.autoResumeDelaySeconds = 5,
    this.enableInterruptionDetection = true,
    this.enableNotifications = true,
    this.enableCriticalAlerts = true,
    this.milestoneNotifications = true,
    this.enableVibration = true,
    this.enableLEDIndicator = true,
    this.enableCompletionSounds = true,
    this.enableAmbientSounds = false,
    this.selectedAmbientSound = 'Forest Rain',
    this.ambientSoundVolume = 0.5,
    this.completionSoundSet = 'default',
    this.enableBackgroundOperation = true,
    this.enableWakeLock = true,
    this.enableBatteryOptimization = false,
    this.backgroundTaskPriority = 1,
    this.enableSessionRecovery = true,
    this.enablePerformanceMonitoring = true,
    this.enableDiagnostics = false,
    this.enableAnalytics = true,
    this.customSessionDurations = const {},
    this.soundProfiles = const {},
    this.featureFlags = const {},
  });

  factory TimerSettings.defaultSettings() => const TimerSettings();

  factory TimerSettings.enterpriseSettings() => const TimerSettings(
        useHighPrecisionTiming: true,
        enableMillisecondDisplay: true,
        compensateForDrift: true,
        enableCriticalAlerts: true,
        enableBackgroundOperation: true,
        enableWakeLock: true,
        backgroundTaskPriority: 2,
        enableSessionRecovery: true,
        enablePerformanceMonitoring: true,
        enableDiagnostics: true,
        autoResumeAfterInterruption: true,
        enableInterruptionDetection: true,
      );

  TimerSettings copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? customWorkDuration,
    int? longBreakInterval,
    bool? useHighPrecisionTiming,
    bool? enableMillisecondDisplay,
    bool? compensateForDrift,
    bool? autoStartWork,
    bool? autoStartBreaks,
    int? autoStartDelaySeconds,
    bool? autoResumeAfterInterruption,
    int? autoResumeDelaySeconds,
    bool? enableInterruptionDetection,
    bool? enableNotifications,
    bool? enableCriticalAlerts,
    bool? milestoneNotifications,
    bool? enableVibration,
    bool? enableLEDIndicator,
    bool? enableCompletionSounds,
    bool? enableAmbientSounds,
    String? selectedAmbientSound,
    double? ambientSoundVolume,
    String? completionSoundSet,
    bool? enableBackgroundOperation,
    bool? enableWakeLock,
    bool? enableBatteryOptimization,
    int? backgroundTaskPriority,
    bool? enableSessionRecovery,
    bool? enablePerformanceMonitoring,
    bool? enableDiagnostics,
    bool? enableAnalytics,
    Map<String, int>? customSessionDurations,
    Map<String, String>? soundProfiles,
    Map<String, bool>? featureFlags,
  }) {
    return TimerSettings(
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      customWorkDuration: customWorkDuration ?? this.customWorkDuration,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      useHighPrecisionTiming:
          useHighPrecisionTiming ?? this.useHighPrecisionTiming,
      enableMillisecondDisplay:
          enableMillisecondDisplay ?? this.enableMillisecondDisplay,
      compensateForDrift: compensateForDrift ?? this.compensateForDrift,
      autoStartWork: autoStartWork ?? this.autoStartWork,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartDelaySeconds:
          autoStartDelaySeconds ?? this.autoStartDelaySeconds,
      autoResumeAfterInterruption:
          autoResumeAfterInterruption ?? this.autoResumeAfterInterruption,
      autoResumeDelaySeconds:
          autoResumeDelaySeconds ?? this.autoResumeDelaySeconds,
      enableInterruptionDetection:
          enableInterruptionDetection ?? this.enableInterruptionDetection,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableCriticalAlerts: enableCriticalAlerts ?? this.enableCriticalAlerts,
      milestoneNotifications:
          milestoneNotifications ?? this.milestoneNotifications,
      enableVibration: enableVibration ?? this.enableVibration,
      enableLEDIndicator: enableLEDIndicator ?? this.enableLEDIndicator,
      enableCompletionSounds:
          enableCompletionSounds ?? this.enableCompletionSounds,
      enableAmbientSounds: enableAmbientSounds ?? this.enableAmbientSounds,
      selectedAmbientSound: selectedAmbientSound ?? this.selectedAmbientSound,
      ambientSoundVolume: ambientSoundVolume ?? this.ambientSoundVolume,
      completionSoundSet: completionSoundSet ?? this.completionSoundSet,
      enableBackgroundOperation:
          enableBackgroundOperation ?? this.enableBackgroundOperation,
      enableWakeLock: enableWakeLock ?? this.enableWakeLock,
      enableBatteryOptimization:
          enableBatteryOptimization ?? this.enableBatteryOptimization,
      backgroundTaskPriority:
          backgroundTaskPriority ?? this.backgroundTaskPriority,
      enableSessionRecovery:
          enableSessionRecovery ?? this.enableSessionRecovery,
      enablePerformanceMonitoring:
          enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      enableDiagnostics: enableDiagnostics ?? this.enableDiagnostics,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      customSessionDurations:
          customSessionDurations ?? this.customSessionDurations,
      soundProfiles: soundProfiles ?? this.soundProfiles,
      featureFlags: featureFlags ?? this.featureFlags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workDuration': workDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'customWorkDuration': customWorkDuration,
      'longBreakInterval': longBreakInterval,
      'useHighPrecisionTiming': useHighPrecisionTiming,
      'enableMillisecondDisplay': enableMillisecondDisplay,
      'compensateForDrift': compensateForDrift,
      'autoStartWork': autoStartWork,
      'autoStartBreaks': autoStartBreaks,
      'autoStartDelaySeconds': autoStartDelaySeconds,
      'autoResumeAfterInterruption': autoResumeAfterInterruption,
      'autoResumeDelaySeconds': autoResumeDelaySeconds,
      'enableInterruptionDetection': enableInterruptionDetection,
      'enableNotifications': enableNotifications,
      'enableCriticalAlerts': enableCriticalAlerts,
      'milestoneNotifications': milestoneNotifications,
      'enableVibration': enableVibration,
      'enableLEDIndicator': enableLEDIndicator,
      'enableCompletionSounds': enableCompletionSounds,
      'enableAmbientSounds': enableAmbientSounds,
      'selectedAmbientSound': selectedAmbientSound,
      'ambientSoundVolume': ambientSoundVolume,
      'completionSoundSet': completionSoundSet,
      'enableBackgroundOperation': enableBackgroundOperation,
      'enableWakeLock': enableWakeLock,
      'enableBatteryOptimization': enableBatteryOptimization,
      'backgroundTaskPriority': backgroundTaskPriority,
      'enableSessionRecovery': enableSessionRecovery,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableDiagnostics': enableDiagnostics,
      'enableAnalytics': enableAnalytics,
      'customSessionDurations': customSessionDurations,
      'soundProfiles': soundProfiles,
      'featureFlags': featureFlags,
    };
  }

  factory TimerSettings.fromMap(Map<String, dynamic> map) {
    return TimerSettings(
      workDuration: map['workDuration'] ?? 25,
      shortBreakDuration: map['shortBreakDuration'] ?? 5,
      longBreakDuration: map['longBreakDuration'] ?? 15,
      customWorkDuration: map['customWorkDuration'] ?? 25,
      longBreakInterval: map['longBreakInterval'] ?? 4,
      useHighPrecisionTiming: map['useHighPrecisionTiming'] ?? true,
      enableMillisecondDisplay: map['enableMillisecondDisplay'] ?? false,
      compensateForDrift: map['compensateForDrift'] ?? true,
      autoStartWork: map['autoStartWork'] ?? false,
      autoStartBreaks: map['autoStartBreaks'] ?? false,
      autoStartDelaySeconds: map['autoStartDelaySeconds'] ?? 3,
      autoResumeAfterInterruption: map['autoResumeAfterInterruption'] ?? true,
      autoResumeDelaySeconds: map['autoResumeDelaySeconds'] ?? 5,
      enableInterruptionDetection: map['enableInterruptionDetection'] ?? true,
      enableNotifications: map['enableNotifications'] ?? true,
      enableCriticalAlerts: map['enableCriticalAlerts'] ?? true,
      milestoneNotifications: map['milestoneNotifications'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
      enableLEDIndicator: map['enableLEDIndicator'] ?? true,
      enableCompletionSounds: map['enableCompletionSounds'] ?? true,
      enableAmbientSounds: map['enableAmbientSounds'] ?? false,
      selectedAmbientSound: map['selectedAmbientSound'] ?? 'Forest Rain',
      ambientSoundVolume: map['ambientSoundVolume'] ?? 0.5,
      completionSoundSet: map['completionSoundSet'] ?? 'default',
      enableBackgroundOperation: map['enableBackgroundOperation'] ?? true,
      enableWakeLock: map['enableWakeLock'] ?? true,
      enableBatteryOptimization: map['enableBatteryOptimization'] ?? false,
      backgroundTaskPriority: map['backgroundTaskPriority'] ?? 1,
      enableSessionRecovery: map['enableSessionRecovery'] ?? true,
      enablePerformanceMonitoring: map['enablePerformanceMonitoring'] ?? true,
      enableDiagnostics: map['enableDiagnostics'] ?? false,
      enableAnalytics: map['enableAnalytics'] ?? true,
      customSessionDurations:
          Map<String, int>.from(map['customSessionDurations'] ?? {}),
      soundProfiles: Map<String, String>.from(map['soundProfiles'] ?? {}),
      featureFlags: Map<String, bool>.from(map['featureFlags'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory TimerSettings.fromJson(String source) =>
      TimerSettings.fromMap(json.decode(source));

  @override
  String toString() {
    return 'TimerSettings(workDuration: $workDuration, shortBreakDuration: $shortBreakDuration, longBreakDuration: $longBreakDuration, useHighPrecisionTiming: $useHighPrecisionTiming, enableBackgroundOperation: $enableBackgroundOperation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimerSettings &&
        other.workDuration == workDuration &&
        other.shortBreakDuration == shortBreakDuration &&
        other.longBreakDuration == longBreakDuration &&
        other.useHighPrecisionTiming == useHighPrecisionTiming &&
        other.enableBackgroundOperation == enableBackgroundOperation;
  }

  @override
  int get hashCode {
    return workDuration.hashCode ^
        shortBreakDuration.hashCode ^
        longBreakDuration.hashCode ^
        useHighPrecisionTiming.hashCode ^
        enableBackgroundOperation.hashCode;
  }
}
