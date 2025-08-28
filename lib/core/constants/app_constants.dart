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

  // Legal and Privacy URLs
  static const String privacyPolicyUrl = 'https://focusflow.app/privacy-policy';
  static const String termsOfServiceUrl =
      'https://focusflow.app/terms-of-service';
  static const String supportEmail = 'support@focusflow.app';
  static const String appWebsiteUrl = 'https://focusflow.app';

  // App Information
  static const String appName = 'Focus Flow Timer';
  static const String appVersion = '1.0.0';
  static const String developerName = 'Focus Flow Team';
  static const String copyrightYear = '2025';

  // GDPR and Data Protection
  static const String dataProtectionOfficerEmail = 'dpo@focusflow.app';
  static const List<String> supportedLanguages = ['en'];
  static const String defaultLanguage = 'en';

  // Contact Information
  static const String businessAddress = '''
Focus Flow Timer
123 Productivity Lane
Focus City, FC 12345
United States
''';

  // Data Collection Categories for Privacy Policy
  static const Map<String, String> dataCollectionPurposes = {
    'Account Management':
        'Email address for account creation and authentication',
    'App Functionality':
        'Timer sessions, task data, and productivity analytics',
    'Performance Analytics': 'App usage statistics and crash reports',
    'User Preferences': 'Settings and customization preferences',
  };
}
