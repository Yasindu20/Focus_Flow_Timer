import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Focus Mode Manager for deep focus enhancement
/// Blocks notifications and distracting apps during focus sessions
class FocusModeManager {
  static final FocusModeManager _instance = FocusModeManager._internal();
  factory FocusModeManager() => _instance;
  FocusModeManager._internal();

  static const String _focusModeKey = 'focus_mode_enabled';
  static const String _autoDoNotDisturbKey = 'auto_dnd_enabled';
  static const String _blockingLevelKey = 'blocking_level';
  static const String _allowEmergencyKey = 'allow_emergency_calls';

  // Platform channels for native functionality
  static const MethodChannel _androidChannel = MethodChannel('focus_mode/android');
  static const MethodChannel _iosChannel = MethodChannel('focus_mode/ios');

  // State tracking
  bool _isInFocusMode = false;
  bool _autoDoNotDisturb = true;
  FocusBlockingLevel _blockingLevel = FocusBlockingLevel.moderate;
  bool _allowEmergencyCalls = true;

  // Listeners and controllers
  final StreamController<FocusModeState> _focusModeController = 
      StreamController<FocusModeState>.broadcast();
  final StreamController<FocusDistraction> _distractionController = 
      StreamController<FocusDistraction>.broadcast();

  // Getters
  bool get isInFocusMode => _isInFocusMode;
  bool get autoDoNotDisturb => _autoDoNotDisturb;
  FocusBlockingLevel get blockingLevel => _blockingLevel;
  bool get allowEmergencyCalls => _allowEmergencyCalls;

  Stream<FocusModeState> get focusModeStream => _focusModeController.stream;
  Stream<FocusDistraction> get distractionStream => _distractionController.stream;

  /// Initialize the focus mode manager
  Future<void> initialize() async {
    await _loadSettings();
    await _checkPermissions();
    await _setupNativeChannels();
    
    if (kDebugMode) {
      print('🎯 Focus Mode Manager initialized');
      print('   Auto DND: $_autoDoNotDisturb');
      print('   Blocking Level: $_blockingLevel');
      print('   Emergency Calls: $_allowEmergencyCalls');
    }
  }

  /// Start enhanced focus mode
  Future<bool> startFocusMode({
    Duration? duration,
    List<String>? allowedApps,
    Map<String, dynamic>? customSettings,
  }) async {
    try {
      if (_isInFocusMode) {
        if (kDebugMode) print('⚠️ Focus mode already active');
        return true;
      }

      // Request permissions if needed
      final hasPermissions = await _requestNecessaryPermissions();
      if (!hasPermissions) {
        _emitState(FocusModeState.permissionDenied);
        return false;
      }

      _isInFocusMode = true;
      _emitState(FocusModeState.starting);

      // Enable Do Not Disturb
      if (_autoDoNotDisturb) {
        await _enableDoNotDisturb();
      }

      // Configure app blocking based on level
      await _configureAppBlocking(allowedApps ?? []);

      // Setup focus session monitoring
      await _startFocusMonitoring(duration);

      // Setup distraction detection
      _startDistractionDetection();

      _emitState(FocusModeState.active);
      await _saveSettings();

      if (kDebugMode) print('🎯 Focus mode activated successfully');
      return true;

    } catch (e) {
      if (kDebugMode) print('❌ Failed to start focus mode: $e');
      _isInFocusMode = false;
      _emitState(FocusModeState.error, message: e.toString());
      return false;
    }
  }

  /// Stop focus mode and restore normal state
  Future<bool> stopFocusMode({bool force = false}) async {
    try {
      if (!_isInFocusMode && !force) {
        if (kDebugMode) print('⚠️ Focus mode not active');
        return true;
      }

      _emitState(FocusModeState.stopping);

      // Disable Do Not Disturb
      if (_autoDoNotDisturb) {
        await _disableDoNotDisturb();
      }

      // Remove app blocking
      await _removeAppBlocking();

      // Stop monitoring
      await _stopFocusMonitoring();
      _stopDistractionDetection();

      _isInFocusMode = false;
      _emitState(FocusModeState.inactive);
      await _saveSettings();

      if (kDebugMode) print('🎯 Focus mode deactivated successfully');
      return true;

    } catch (e) {
      if (kDebugMode) print('❌ Failed to stop focus mode: $e');
      _emitState(FocusModeState.error, message: e.toString());
      return false;
    }
  }

  /// Configure focus mode settings
  Future<void> updateSettings({
    bool? autoDoNotDisturb,
    FocusBlockingLevel? blockingLevel,
    bool? allowEmergencyCalls,
  }) async {
    if (autoDoNotDisturb != null) _autoDoNotDisturb = autoDoNotDisturb;
    if (blockingLevel != null) _blockingLevel = blockingLevel;
    if (allowEmergencyCalls != null) _allowEmergencyCalls = allowEmergencyCalls;
    
    await _saveSettings();

    // If in focus mode, apply changes immediately
    if (_isInFocusMode) {
      if (autoDoNotDisturb != null) {
        autoDoNotDisturb ? await _enableDoNotDisturb() : await _disableDoNotDisturb();
      }
      if (blockingLevel != null) {
        await _configureAppBlocking([]);
      }
    }
  }

  /// Check if app blocking permissions are available
  Future<bool> canBlockApps() async {
    if (Platform.isAndroid) {
      try {
        return await _androidChannel.invokeMethod('canBlockApps') ?? false;
      } catch (e) {
        return false;
      }
    } else if (Platform.isIOS) {
      // iOS has limited app blocking capabilities
      return false;
    }
    return false;
  }

  /// Get list of installed apps that can be blocked
  Future<List<AppInfo>> getBlockableApps() async {
    try {
      if (Platform.isAndroid) {
        final result = await _androidChannel.invokeMethod('getInstalledApps');
        if (result != null) {
          return (result as List).map((app) => AppInfo.fromMap(app)).toList();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('❌ Failed to get blockable apps: $e');
      return [];
    }
  }

  // Private methods

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoDoNotDisturb = prefs.getBool(_autoDoNotDisturbKey) ?? true;
    _allowEmergencyCalls = prefs.getBool(_allowEmergencyKey) ?? true;
    _blockingLevel = FocusBlockingLevel.values[
        prefs.getInt(_blockingLevelKey) ?? FocusBlockingLevel.moderate.index];
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusModeKey, _isInFocusMode);
    await prefs.setBool(_autoDoNotDisturbKey, _autoDoNotDisturb);
    await prefs.setBool(_allowEmergencyKey, _allowEmergencyCalls);
    await prefs.setInt(_blockingLevelKey, _blockingLevel.index);
  }

  Future<void> _checkPermissions() async {
    // Check current permissions status
    final permissions = [
      Permission.notification,
      Permission.systemAlertWindow,
      Permission.accessNotificationPolicy,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (kDebugMode) {
        print('🔒 Permission ${permission.toString()}: $status');
      }
    }
  }

  Future<bool> _requestNecessaryPermissions() async {
    final List<Permission> requiredPermissions = [];

    // Notification permission
    if (!await Permission.notification.isGranted) {
      requiredPermissions.add(Permission.notification);
    }

    // Do Not Disturb permission (Android)
    if (Platform.isAndroid && !await Permission.accessNotificationPolicy.isGranted) {
      requiredPermissions.add(Permission.accessNotificationPolicy);
    }

    // System overlay permission for app blocking
    if (_blockingLevel != FocusBlockingLevel.none && 
        !await Permission.systemAlertWindow.isGranted) {
      requiredPermissions.add(Permission.systemAlertWindow);
    }

    if (requiredPermissions.isNotEmpty) {
      final results = await requiredPermissions.request();
      return results.values.every((status) => status.isGranted);
    }

    return true;
  }

  Future<void> _setupNativeChannels() async {
    if (Platform.isAndroid) {
      _androidChannel.setMethodCallHandler(_handleAndroidCallbacks);
    } else if (Platform.isIOS) {
      _iosChannel.setMethodCallHandler(_handleIOSCallbacks);
    }
  }

  Future<dynamic> _handleAndroidCallbacks(MethodCall call) async {
    switch (call.method) {
      case 'onDistractionDetected':
        _handleDistractionDetected(call.arguments);
        break;
      case 'onAppBlocked':
        _handleAppBlocked(call.arguments);
        break;
    }
  }

  Future<dynamic> _handleIOSCallbacks(MethodCall call) async {
    switch (call.method) {
      case 'onFocusInterrupted':
        _handleFocusInterrupted(call.arguments);
        break;
    }
  }

  Future<void> _enableDoNotDisturb() async {
    try {
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('enableDoNotDisturb', {
          'allowEmergency': _allowEmergencyCalls,
          'level': _blockingLevel.index,
        });
      } else if (Platform.isIOS) {
        await _iosChannel.invokeMethod('enableFocusMode', {
          'allowCritical': _allowEmergencyCalls,
        });
      }
      if (kDebugMode) print('🔕 Do Not Disturb enabled');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to enable DND: $e');
    }
  }

  Future<void> _disableDoNotDisturb() async {
    try {
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('disableDoNotDisturb');
      } else if (Platform.isIOS) {
        await _iosChannel.invokeMethod('disableFocusMode');
      }
      if (kDebugMode) print('🔔 Do Not Disturb disabled');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to disable DND: $e');
    }
  }

  Future<void> _configureAppBlocking(List<String> allowedApps) async {
    if (_blockingLevel == FocusBlockingLevel.none) return;

    try {
      if (Platform.isAndroid) {
        // Get common distracting apps
        final distractingApps = _getDistractingApps();
        
        await _androidChannel.invokeMethod('configureAppBlocking', {
          'blockingLevel': _blockingLevel.index,
          'distractingApps': distractingApps,
          'allowedApps': allowedApps,
          'gentleMode': _blockingLevel == FocusBlockingLevel.gentle,
        });
      }
      if (kDebugMode) print('🚫 App blocking configured');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to configure app blocking: $e');
    }
  }

  Future<void> _removeAppBlocking() async {
    try {
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('removeAppBlocking');
      }
      if (kDebugMode) print('✅ App blocking removed');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to remove app blocking: $e');
    }
  }

  Future<void> _startFocusMonitoring(Duration? duration) async {
    try {
      final durationMs = duration?.inMilliseconds ?? 0;
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('startFocusMonitoring', {
          'durationMs': durationMs,
          'monitoringLevel': _blockingLevel.index,
        });
      } else if (Platform.isIOS) {
        await _iosChannel.invokeMethod('startFocusTracking', {
          'durationMs': durationMs,
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Failed to start focus monitoring: $e');
    }
  }

  Future<void> _stopFocusMonitoring() async {
    try {
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('stopFocusMonitoring');
      } else if (Platform.isIOS) {
        await _iosChannel.invokeMethod('stopFocusTracking');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Failed to stop focus monitoring: $e');
    }
  }

  void _startDistractionDetection() {
    // Start listening for app switches and focus breaks
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isInFocusMode) {
        timer.cancel();
        return;
      }
      _checkForDistractions();
    });
  }

  void _stopDistractionDetection() {
    // Distraction detection stops when periodic timers are cancelled
  }

  Future<void> _checkForDistractions() async {
    // This would be implemented with native platform code
    // For now, we'll use app state detection
  }

  List<String> _getDistractingApps() {
    // Common distracting apps based on research
    return [
      'com.instagram.android',
      'com.twitter.android',
      'com.facebook.katana',
      'com.snapchat.android',
      'com.zhiliaoapp.musically', // TikTok
      'com.reddit.frontpage',
      'com.pinterest',
      'com.discord',
      'com.telegram.messenger',
      'com.whatsapp',
      'com.google.android.youtube',
      'com.netflix.mediaclient',
      'com.spotify.music',
      // Games
      'com.king.candycrushsaga',
      'com.supercell.clashofclans',
      'com.mojang.minecraftpe',
      // Shopping
      'com.amazon.mShop.android.shopping',
      'com.ebay.mobile',
    ];
  }

  void _handleDistractionDetected(Map<String, dynamic> data) {
    final distraction = FocusDistraction(
      type: DistractionType.appSwitch,
      appPackage: data['package'],
      appName: data['appName'],
      timestamp: DateTime.now(),
      severity: _calculateSeverity(data),
    );
    _distractionController.add(distraction);
  }

  void _handleAppBlocked(Map<String, dynamic> data) {
    final distraction = FocusDistraction(
      type: DistractionType.appBlocked,
      appPackage: data['package'],
      appName: data['appName'],
      timestamp: DateTime.now(),
      severity: 1.0,
    );
    _distractionController.add(distraction);
  }

  void _handleFocusInterrupted(Map<String, dynamic> data) {
    final distraction = FocusDistraction(
      type: DistractionType.focusInterrupted,
      appPackage: data['source'],
      timestamp: DateTime.now(),
      severity: 0.8,
    );
    _distractionController.add(distraction);
  }

  double _calculateSeverity(Map<String, dynamic> data) {
    final String package = data['package'] ?? '';
    final distractingApps = _getDistractingApps();
    
    if (distractingApps.contains(package)) {
      return 1.0; // High severity
    } else if (package.contains('game') || package.contains('social')) {
      return 0.8; // Medium-high severity
    } else if (package.contains('messaging') || package.contains('communication')) {
      return 0.6; // Medium severity
    } else {
      return 0.3; // Low severity
    }
  }

  void _emitState(FocusModeState state, {String? message}) {
    _focusModeController.add(FocusModeState.active);
  }

  /// Dispose resources
  void dispose() {
    _focusModeController.close();
    _distractionController.close();
  }
}

/// Focus blocking levels
enum FocusBlockingLevel {
  none,     // No app blocking
  gentle,   // Gentle reminders and redirects
  moderate, // Block distracting apps with override option
  strict,   // Strong blocking with difficulty override
}

/// Focus mode states
enum FocusModeState {
  inactive,
  starting,
  active,
  stopping,
  paused,
  error,
  permissionDenied,
}

/// Types of distractions
enum DistractionType {
  appSwitch,
  appBlocked,
  notificationReceived,
  focusInterrupted,
  phoneUnlocked,
}

/// Distraction event data
class FocusDistraction {
  final DistractionType type;
  final String? appPackage;
  final String? appName;
  final DateTime timestamp;
  final double severity; // 0.0 to 1.0

  FocusDistraction({
    required this.type,
    this.appPackage,
    this.appName,
    required this.timestamp,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'appPackage': appPackage,
      'appName': appName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'severity': severity,
    };
  }

  factory FocusDistraction.fromMap(Map<String, dynamic> map) {
    return FocusDistraction(
      type: DistractionType.values[map['type'] ?? 0],
      appPackage: map['appPackage'],
      appName: map['appName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      severity: map['severity']?.toDouble() ?? 0.0,
    );
  }
}

/// App information
class AppInfo {
  final String packageName;
  final String displayName;
  final String? iconPath;
  final bool isSystemApp;

  AppInfo({
    required this.packageName,
    required this.displayName,
    this.iconPath,
    this.isSystemApp = false,
  });

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] ?? '',
      displayName: map['displayName'] ?? '',
      iconPath: map['iconPath'],
      isSystemApp: map['isSystemApp'] ?? false,
    );
  }
}