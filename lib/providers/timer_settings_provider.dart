import 'package:flutter/foundation.dart';
import '../models/timer_settings.dart';
import '../services/optimized_storage_service.dart';
import '../core/enums/timer_enums.dart';

class TimerSettingsProvider extends ChangeNotifier {
  final OptimizedStorageService _storage = OptimizedStorageService();
  TimerSettings _settings = TimerSettings.defaultSettings();
  bool _isInitialized = false;

  TimerSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  // Quick access getters for durations
  int get workDuration => _settings.workDuration;
  int get shortBreakDuration => _settings.shortBreakDuration;
  int get longBreakDuration => _settings.longBreakDuration;
  int get customWorkDuration => _settings.customWorkDuration;

  TimerSettingsProvider();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _storage.initialize();
      await _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize TimerSettingsProvider: $e');
      // Use default settings if initialization fails
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final storedSettings = await _storage.getCachedData('timer_settings_v2');
      if (storedSettings != null) {
        _settings = TimerSettings.fromMap(storedSettings);
      }
    } catch (e) {
      debugPrint('Error loading timer settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.cacheData('timer_settings_v2', _settings.toMap());
    } catch (e) {
      debugPrint('Error saving timer settings: $e');
    }
  }

  Future<void> updateWorkDuration(int minutes) async {
    if (minutes > 0 && minutes <= 999 && minutes != _settings.workDuration) {
      _settings = _settings.copyWith(workDuration: minutes);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateShortBreakDuration(int minutes) async {
    if (minutes > 0 && minutes <= 999 && minutes != _settings.shortBreakDuration) {
      _settings = _settings.copyWith(shortBreakDuration: minutes);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateLongBreakDuration(int minutes) async {
    if (minutes > 0 && minutes <= 999 && minutes != _settings.longBreakDuration) {
      _settings = _settings.copyWith(longBreakDuration: minutes);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateCustomWorkDuration(int minutes) async {
    if (minutes > 0 && minutes <= 999 && minutes != _settings.customWorkDuration) {
      _settings = _settings.copyWith(customWorkDuration: minutes);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateLongBreakInterval(int sessions) async {
    if (sessions > 0 && sessions <= 10 && sessions != _settings.longBreakInterval) {
      _settings = _settings.copyWith(longBreakInterval: sessions);
      await _saveSettings();
      notifyListeners();
    }
  }

  int getDurationForType(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return _settings.workDuration;
      case TimerType.shortBreak:
        return _settings.shortBreakDuration;
      case TimerType.longBreak:
        return _settings.longBreakDuration;
      case TimerType.custom:
        return _settings.customWorkDuration;
    }
  }

  Future<void> setDurationForType(TimerType type, int minutes) async {
    switch (type) {
      case TimerType.pomodoro:
        await updateWorkDuration(minutes);
        break;
      case TimerType.shortBreak:
        await updateShortBreakDuration(minutes);
        break;
      case TimerType.longBreak:
        await updateLongBreakDuration(minutes);
        break;
      case TimerType.custom:
        await updateCustomWorkDuration(minutes);
        break;
    }
  }

  // Preset management for quick customization
  List<int> getPresetsForType(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return [15, 20, 25, 30, 35, 40, 45, 50, 60, 90];
      case TimerType.shortBreak:
        return [3, 5, 8, 10, 15];
      case TimerType.longBreak:
        return [10, 15, 20, 25, 30];
      case TimerType.custom:
        return [10, 15, 20, 25, 30, 35, 40, 45, 60, 90, 120];
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _settings = TimerSettings.defaultSettings();
    await _saveSettings();
    notifyListeners();
  }

  // Validation helpers
  bool isValidDuration(int minutes) {
    return minutes > 0 && minutes <= 999;
  }

  String? validateDuration(int? minutes) {
    if (minutes == null) return 'Duration is required';
    if (minutes <= 0) return 'Duration must be greater than 0';
    if (minutes > 999) return 'Duration must be less than 1000 minutes';
    return null;
  }

  // Statistics and insights
  Map<String, dynamic> getSettingsStats() {
    return {
      'workDuration': _settings.workDuration,
      'shortBreakDuration': _settings.shortBreakDuration,
      'longBreakDuration': _settings.longBreakDuration,
      'customWorkDuration': _settings.customWorkDuration,
      'longBreakInterval': _settings.longBreakInterval,
      'totalPossibleFocusTime': _settings.workDuration * _settings.longBreakInterval,
      'breakToWorkRatio': {
        'short': (_settings.shortBreakDuration / _settings.workDuration * 100).round(),
        'long': (_settings.longBreakDuration / _settings.workDuration * 100).round(),
      },
    };
  }

  // Import/Export settings
  String exportSettings() {
    return _settings.toJson();
  }

  Future<bool> importSettings(String jsonString) async {
    try {
      final importedSettings = TimerSettings.fromJson(jsonString);
      _settings = importedSettings;
      await _saveSettings();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error importing settings: $e');
      return false;
    }
  }
}