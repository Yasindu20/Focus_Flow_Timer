class AppConstants {
  // Timer durations in minutes
  static const int defaultWorkDuration = 25;
  static const int defaultShortBreak = 5;
  static const int defaultLongBreak = 15;
  static const int sessionsUntilLongBreak = 4;

  // Storage keys
  static const String themeKey = 'theme_mode';
  static const String tasksKey = 'tasks';
  static const String analyticsKey = 'analytics';
  static const String settingsKey = 'settings';

  // Audio files
  static const Map<String, String> soundTracks = {
    'Forest Rain': 'assets/sounds/forest_rain.mp3',
    'Ocean Waves': 'assets/sounds/ocean_waves.mp3',
    'White Noise': 'assets/sounds/white_noise.mp3',
  };
}
