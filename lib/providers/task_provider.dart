import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;
  List<Task> get incompleteTasks =>
      _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();

  TaskProvider() {
    _loadTasks();
  }

  void _loadTasks() {
    _tasks = StorageService.tasks;
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    String description = '',
    int estimatedPomodoros = 1,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      estimatedPomodoros: estimatedPomodoros,
      priority: priority,
    );

    await StorageService.addTask(task);
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await StorageService.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    await StorageService.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  Future<void> completeTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      task.isCompleted = true;
      task.completedAt = DateTime.now();

      await StorageService.updateTask(task);
      await AnalyticsService.recordTaskCompletion();

      notifyListeners();
    }
  }

  Future<void> incrementTaskPomodoro(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      task.completedPomodoros++;

      await StorageService.updateTask(task);
      notifyListeners();
    }
  }

  Task? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }
}
