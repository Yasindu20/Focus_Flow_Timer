import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/optimized_storage_service.dart';
import '../services/free_ml_service.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  final OptimizedStorageService _storage = OptimizedStorageService();
  final FreeMlService _mlService = FreeMlService();
  
  String? _currentTaskId;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get incompleteTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  
  String? get currentTaskId => _currentTaskId;
  Task? get currentTask => _currentTaskId != null ? getTaskById(_currentTaskId!) : null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Task Statistics
  int get totalTasks => _tasks.length;
  int get completedTasksCount => completedTasks.length;
  int get pendingTasksCount => incompleteTasks.length;
  double get completionRate => totalTasks > 0 ? completedTasksCount / totalTasks : 0.0;

  // Productivity Metrics
  int get totalPomodorosCompleted => _tasks.fold(0, (sum, task) => sum + (task.completedPomodoros ?? 0));
  int get totalMinutesWorked => _tasks.fold(0, (sum, task) => sum + (task.actualMinutes ?? 0));
  double get averageTaskDuration => completedTasks.isNotEmpty 
      ? completedTasks.fold(0, (sum, task) => sum + (task.actualMinutes ?? 0)) / completedTasks.length 
      : 0.0;

  // Priority-based getters
  List<Task> get highPriorityTasks => incompleteTasks.where((task) => 
      task.priority?.toLowerCase() == 'high' || task.priority?.toLowerCase() == 'critical').toList();
  List<Task> get todayTasks => incompleteTasks.where((task) => 
      task.createdAt.day == DateTime.now().day).toList();

  Future<void> initialize() async {
    try {
      _setLoading(true);
      await _storage.initialize();
      await _mlService.initialize();
      await _loadTasks();
      _setError(null);
    } catch (e) {
      _setError('Failed to initialize: $e');
      debugPrint('TaskProvider initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadTasks() async {
    try {
      final storedTasks = await _storage.getTasks();
      _tasks.clear();
      
      for (final taskData in storedTasks) {
        final task = Task.fromMap(taskData);
        _tasks.add(task);
      }
      
      _sortTasks();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    }
  }

  Future<Task> addTask({
    required String title,
    String description = '',
    String? category,
    String? priority,
    int? estimatedMinutes,
    List<String>? tags,
  }) async {
    try {
      _setLoading(true);
      
      String finalCategory = category ?? 'general';
      String finalPriority = priority ?? 'medium';
      int finalEstimatedMinutes = estimatedMinutes ?? 25;
      List<String> finalTags = tags ?? [];

      // Use ML service for basic categorization if available
      if (category == null || priority == null) {
        try {
          final analysis = await _mlService.analyzeTaskText('$title $description');
          if (analysis.isNotEmpty) {
            finalCategory = category ?? analysis['category'] ?? 'general';
            finalPriority = priority ?? analysis['priority'] ?? 'medium';
          }
        } catch (mlError) {
          debugPrint('ML analysis failed, using defaults: $mlError');
        }
      }

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        category: finalCategory,
        priority: finalPriority,
        estimatedMinutes: finalEstimatedMinutes,
        tags: finalTags,
        createdAt: DateTime.now(),
        isCompleted: false,
      );

      _tasks.add(task);
      await _storage.saveTask(task.toMap());
      
      _sortTasks();
      notifyListeners();
      
      return task;
    } catch (e) {
      _setError('Failed to add task: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTask(Task updatedTask) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        await _storage.updateTask(updatedTask.id, updatedTask.toMap());
        
        _sortTasks();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update task: $e');
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      final task = getTaskById(taskId);
      if (task != null && !task.isCompleted) {
        final completedTask = task.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
          actualMinutes: task.actualMinutes ?? task.estimatedMinutes,
        );
        
        await updateTask(completedTask);
      }
    } catch (e) {
      _setError('Failed to complete task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks.removeAt(index);
        await _storage.deleteTask(taskId);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete task: $e');
    }
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  void setCurrentTask(String? taskId) {
    _currentTaskId = taskId;
    notifyListeners();
  }

  Future<void> updateTaskProgress(String taskId, {
    int? completedPomodoros,
    int? actualMinutes,
  }) async {
    try {
      final task = getTaskById(taskId);
      if (task != null) {
        final updatedTask = task.copyWith(
          completedPomodoros: completedPomodoros ?? (task.completedPomodoros ?? 0),
          actualMinutes: actualMinutes ?? task.actualMinutes,
        );
        await updateTask(updatedTask);
      }
    } catch (e) {
      _setError('Failed to update task progress: $e');
    }
  }

  List<Task> getTasksByCategory(String category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  List<Task> getTasksByPriority(String priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  List<Task> getTasksByDateRange(DateTime start, DateTime end) {
    return _tasks.where((task) => 
        task.createdAt.isAfter(start) && task.createdAt.isBefore(end)).toList();
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;
    
    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) =>
        task.title.toLowerCase().contains(lowercaseQuery) ||
        task.description.toLowerCase().contains(lowercaseQuery) ||
        (task.tags?.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ?? false)
    ).toList();
  }

  Future<Map<String, dynamic>> getProductivityInsights() async {
    try {
      return {
        'totalTasks': totalTasks,
        'completionRate': completionRate,
        'averageDuration': averageTaskDuration,
        'totalPomodoros': totalPomodorosCompleted,
        'categoryBreakdown': _getCategoryBreakdown(),
        'priorityBreakdown': _getPriorityBreakdown(),
      };
    } catch (e) {
      debugPrint('Error generating insights: $e');
      return {
        'totalTasks': totalTasks,
        'completionRate': completionRate,
        'averageDuration': averageTaskDuration,
        'totalPomodoros': totalPomodorosCompleted,
      };
    }
  }

  Map<String, dynamic> exportData() {
    return {
      'tasks': _tasks.map((task) => task.toMap()).toList(),
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'totalTasks': totalTasks,
        'completedTasks': completedTasksCount,
        'version': '1.0.0',
      }
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      final tasksData = data['tasks'] as List;
      
      for (final taskData in tasksData) {
        final task = Task.fromMap(taskData);
        if (!_tasks.any((existing) => existing.id == task.id)) {
          _tasks.add(task);
          await _storage.saveTask(task.toMap());
        }
      }
      
      _sortTasks();
      notifyListeners();
    } catch (e) {
      _setError('Failed to import data: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      // First by completion status
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Then by priority (high, medium, low)
      final aPriority = _getPriorityValue(a.priority);
      final bPriority = _getPriorityValue(b.priority);
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }
      // Finally by creation date
      return b.createdAt.compareTo(a.createdAt);
    });
  }
  
  int _getPriorityValue(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical': return 4;
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 2;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Map<String, int> _getCategoryBreakdown() {
    final breakdown = <String, int>{};
    for (final task in _tasks) {
      final category = task.category ?? 'general';
      breakdown[category] = (breakdown[category] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, int> _getPriorityBreakdown() {
    final breakdown = <String, int>{};
    for (final task in _tasks) {
      final priority = task.priority ?? 'medium';
      breakdown[priority] = (breakdown[priority] ?? 0) + 1;
    }
    return breakdown;
  }

  @override
  void dispose() {
    _tasks.clear();
    super.dispose();
  }
}