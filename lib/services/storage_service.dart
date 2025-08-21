import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/pomodoro_session.dart';
import '../models/daily_stats.dart';
import 'dart:convert';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box<Task> _tasksBox;
  static late Box<PomodoroSession> _sessionsBox;
  static late Box<DailyStats> _statsBox;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(PomodoroSessionAdapter());
    Hive.registerAdapter(SessionTypeAdapter());
    Hive.registerAdapter(DailyStatsAdapter());

    // Open boxes
    _tasksBox = await Hive.openBox<Task>('tasks');
    _sessionsBox = await Hive.openBox<PomodoroSession>('sessions');
    _statsBox = await Hive.openBox<DailyStats>('stats');
  }

  // Theme settings
  static bool get isDarkMode => _prefs.getBool('isDarkMode') ?? false;
  static Future<void> setDarkMode(bool value) =>
      _prefs.setBool('isDarkMode', value);

  // Sound settings
  static String get selectedSound =>
      _prefs.getString('selectedSound') ?? 'Forest Rain';
  static Future<void> setSelectedSound(String sound) =>
      _prefs.setString('selectedSound', sound);

  static double get soundVolume => _prefs.getDouble('soundVolume') ?? 0.5;
  static Future<void> setSoundVolume(double volume) =>
      _prefs.setDouble('soundVolume', volume);

  // Tasks
  static List<Task> get tasks => _tasksBox.values.toList();

  static Future<void> addTask(Task task) async {
    await _tasksBox.put(task.id, task);
  }

  static Future<void> updateTask(Task task) async {
    await _tasksBox.put(task.id, task);
  }

  static Future<void> deleteTask(String taskId) async {
    await _tasksBox.delete(taskId);
  }

  // Sessions
  static List<PomodoroSession> get sessions => _sessionsBox.values.toList();

  static Future<void> addSession(PomodoroSession session) async {
    await _sessionsBox.put(session.id, session);
  }

  // Daily Stats
  static DailyStats? getStatsForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return _statsBox.get(dateKey);
  }

  static Future<void> updateDailyStats(DailyStats stats) async {
    final dateKey = '${stats.date.year}-${stats.date.month}-${stats.date.day}';
    await _statsBox.put(dateKey, stats);
  }

  static List<DailyStats> getStatsForRange(DateTime start, DateTime end) {
    final stats = <DailyStats>[];
    for (
      var date = start;
      date.isBefore(end) || date.isAtSameMomentAs(end);
      date = date.add(const Duration(days: 1))
    ) {
      final dayStats = getStatsForDate(date);
      if (dayStats != null) {
        stats.add(dayStats);
      }
    }
    return stats;
  }
}
