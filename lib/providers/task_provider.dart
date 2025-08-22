import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/enhanced_task.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../core/ai/task_intelligence_engine.dart';

/// Enterprise-level Task Provider with AI integration and analytics
class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  final List<EnhancedTask> _enhancedTasks = [];
  final StorageService _storage = StorageService();
  final AnalyticsService _analytics = AnalyticsService();
  final TaskIntelligenceEngine _aiEngine = TaskIntelligenceEngine();
  
  String? _currentTaskId;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get incompleteTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  List<EnhancedTask> get enhancedTasks => List.unmodifiable(_enhancedTasks);
  
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
  int get totalPomodorosCompleted => _tasks.fold(0, (sum, task) => sum + task.completedPomodoros);
  int get totalMinutesWorked => _tasks.fold(0, (sum, task) => sum + (task.actualMinutes ?? 0));
  double get averageTaskDuration => completedTasks.isNotEmpty 
      ? completedTasks.fold(0, (sum, task) => sum + (task.actualMinutes ?? 0)) / completedTasks.length 
      : 0.0;

  // Priority-based getters
  List<Task> get highPriorityTasks => incompleteTasks.where((task) => 
      task.priority == TaskPriority.high || task.priority == TaskPriority.critical).toList();
  List<Task> get todayTasks => incompleteTasks.where((task) => 
      task.createdAt.day == DateTime.now().day).toList();

  /// Initialize the task provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      await StorageService.initialize();
      await _aiEngine.initialize();
      await _loadTasks();
      _setError(null);
    } catch (e) {
      _setError('Failed to initialize: $e');
      debugPrint('TaskProvider initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load tasks from storage
  Future<void> _loadTasks() async {
    try {
      final storedTasks = StorageService.tasks;
      _tasks.clear();
      _enhancedTasks.clear();
      
      for (final task in storedTasks) {
        _tasks.add(task);
        _enhancedTasks.add(task.toEnhancedTask());
      }
      
      // Sort by priority and creation date
      _sortTasks();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    }
  }

  /// Add a new task with AI assistance
  Future<Task> addTask({
    required String title,
    String description = '',
    TaskCategory? category,
    TaskPriority? priority,
    int? estimatedMinutes,
    List<String>? tags,
  }) async {
    try {
      _setLoading(true);
      
      // Use AI to enhance task creation if parameters are not provided
      TaskCategory finalCategory = category ?? TaskCategory.general;
      TaskPriority finalPriority = priority ?? TaskPriority.medium;
      int finalEstimatedMinutes = estimatedMinutes ?? 25;
      List<String> finalTags = tags ?? [];

      // AI-powered task analysis and enhancement
      if (category == null || priority == null || estimatedMinutes == null) {
        try {
          final categorization = await _aiEngine.categorizeTask(
            title: title,
            description: description,
            metadata: {'userHistory': _getUserTaskHistory()},
          );
          
          final estimation = await _aiEngine.estimateTaskDuration(
            title: title,
            description: description,
            category: categorization.suggestedCategory,
            priority: categorization.suggestedPriority,
          );

          finalCategory = category ?? categorization.suggestedCategory;
          finalPriority = priority ?? categorization.suggestedPriority;
          finalEstimatedMinutes = estimatedMinutes ?? estimation.estimatedMinutes;
          finalTags = tags ?? categorization.smartTags;
        } catch (aiError) {
          debugPrint('AI enhancement failed, using defaults: $aiError');
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
      );

      _tasks.add(task);
      _enhancedTasks.add(task.toEnhancedTask());
      await StorageService.addTask(task);
      
      _sortTasks();
      notifyListeners();

      // Track analytics
      await _analytics.trackTaskCreated(task.toEnhancedTask());
      
      return task;
    } catch (e) {
      _setError('Failed to add task: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task updatedTask) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        _enhancedTasks[index] = updatedTask.toEnhancedTask();
        await StorageService.updateTask(updatedTask);
        
        _sortTasks();
        notifyListeners();
        
        await _analytics.trackTaskUpdated(updatedTask.toEnhancedTask());
      }
    } catch (e) {
      _setError('Failed to update task: $e');
    }
  }

  /// Complete a task and record analytics
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
        await _analytics.trackTaskCompleted(completedTask.toEnhancedTask());
        
        // Learn from completion for AI improvement
        await _aiEngine.recordTaskCompletion(completedTask.toEnhancedTask());
      }
    } catch (e) {
      _setError('Failed to complete task: $e');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        _tasks.removeAt(index);
        _enhancedTasks.removeAt(index);
        
        await StorageService.deleteTask(taskId);
        notifyListeners();
        
        await _analytics.trackTaskDeleted(task.toEnhancedTask());
      }
    } catch (e) {
      _setError('Failed to delete task: $e');
    }
  }

  /// Get task by ID
  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Set current active task
  void setCurrentTask(String? taskId) {
    _currentTaskId = taskId;
    notifyListeners();
  }

  /// Update task progress (for Pomodoro completion)
  Future<void> updateTaskProgress(String taskId, {
    int? completedPomodoros,
    int? actualMinutes,
  }) async {
    try {
      final task = getTaskById(taskId);
      if (task != null) {
        final updatedTask = task.copyWith(
          completedPomodoros: completedPomodoros ?? task.completedPomodoros,
          actualMinutes: actualMinutes ?? task.actualMinutes,
        );
        await updateTask(updatedTask);
      }
    } catch (e) {
      _setError('Failed to update task progress: $e');
    }
  }

  /// Get tasks by category
  List<Task> getTasksByCategory(TaskCategory category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  /// Get tasks by priority
  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  /// Get tasks by date range
  List<Task> getTasksByDateRange(DateTime start, DateTime end) {
    return _tasks.where((task) => 
        task.createdAt.isAfter(start) && task.createdAt.isBefore(end)).toList();
  }

  /// Search tasks by title or description
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;
    
    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) =>
        task.title.toLowerCase().contains(lowercaseQuery) ||
        task.description.toLowerCase().contains(lowercaseQuery) ||
        task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Get AI-powered productivity insights
  Future<Map<String, dynamic>> getProductivityInsights() async {
    try {
      final insights = await _analytics.generateProductivityReport(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        userId: 'current_user',
      );
      
      return {
        'totalTasks': totalTasks,
        'completionRate': completionRate,
        'averageDuration': averageTaskDuration,
        'totalPomodoros': totalPomodorosCompleted,
        'aiInsights': insights,
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

  /// Export tasks data
  Map<String, dynamic> exportData() {
    return {
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'totalTasks': totalTasks,
        'completedTasks': completedTasksCount,
        'version': '1.0.0',
      }
    };
  }

  /// Import tasks data
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      final tasksData = data['tasks'] as List;
      
      for (final taskData in tasksData) {
        final task = Task.fromJson(taskData);
        if (!_tasks.any((existing) => existing.id == task.id)) {
          _tasks.add(task);
          _enhancedTasks.add(task.toEnhancedTask());
          await StorageService.addTask(task);
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

  // Private helper methods
  void _sortTasks() {
    _tasks.sort((a, b) {
      // First by completion status
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Then by priority
      if (a.priority.index != b.priority.index) {
        return b.priority.index.compareTo(a.priority.index);
      }
      // Finally by creation date
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Map<String, dynamic> _getUserTaskHistory() {
    return {
      'totalTasks': totalTasks,
      'completionRate': completionRate,
      'averageDuration': averageTaskDuration,
      'categoryBreakdown': _getCategoryBreakdown(),
      'priorityBreakdown': _getPriorityBreakdown(),
    };
  }

  Map<String, int> _getCategoryBreakdown() {
    final breakdown = <String, int>{};
    for (final category in TaskCategory.values) {
      breakdown[category.name] = getTasksByCategory(category).length;
    }
    return breakdown;
  }

  Map<String, int> _getPriorityBreakdown() {
    final breakdown = <String, int>{};
    for (final priority in TaskPriority.values) {
      breakdown[priority.name] = getTasksByPriority(priority).length;
    }
    return breakdown;
  }

  @override
  void dispose() {
    _tasks.clear();
    _enhancedTasks.clear();
    super.dispose();
  }
}