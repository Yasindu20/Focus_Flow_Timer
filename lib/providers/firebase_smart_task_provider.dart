import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/enhanced_task.dart';

class FirebaseSmartTaskProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<EnhancedTask> _tasks = [];
  List<EnhancedTask> _recommendations = [];
  final Map<String, dynamic> _aiProcessingCache = {};
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  StreamSubscription<List<EnhancedTask>>? _tasksSubscription;

  // Getters
  List<EnhancedTask> get tasks => _tasks;
  List<EnhancedTask> get recommendations => _recommendations;
  List<EnhancedTask> get incompleteTasks =>
      _tasks.where((task) => !task.isCompleted).toList();
  List<EnhancedTask> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  List<EnhancedTask> get todayTasks =>
      _tasks.where((task) => _isToday(task.createdAt)).toList();
  List<EnhancedTask> get overdueTasks =>
      _tasks.where((task) => task.isOverdue).toList();
  List<EnhancedTask> get dueSoonTasks =>
      _tasks.where((task) => task.isDueSoon).toList();

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  int get totalTasks => _tasks.length;
  int get completedTasksCount => completedTasks.length;
  double get completionRate =>
      _tasks.isEmpty ? 0.0 : completedTasksCount / totalTasks;

  // Initialize the provider
  Future<void> initialize() async {
    if (!_firebaseService.isAuthenticated) return;

    try {
      _setLoading(true);
      await _subscribeToTasks();
      await loadRecommendations();
    } catch (e) {
      _setError('Failed to initialize tasks: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Subscribe to real-time task updates
  Future<void> _subscribeToTasks() async {
    _tasksSubscription?.cancel();

    _tasksSubscription = _firebaseService.getTasksStream().listen(
      (tasks) {
        _tasks = tasks;
        _sortTasks();
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load tasks: ${error.toString()}');
      },
    );
  }

  // Create a new task with AI enhancement
  Future<EnhancedTask?> createTask({
    required String title,
    String description = '',
    TaskCategory category = TaskCategory.general,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    int estimatedMinutes = 25,
    List<String>? tags,
    bool enhanceWithAI = true,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Create basic task
      final task = EnhancedTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        category: category,
        priority: priority,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        estimatedMinutes: estimatedMinutes,
        tags: tags ?? [],
      );

      // Enhance with AI if enabled
      if (enhanceWithAI) {
        final aiEnhancements = await _getAIEnhancements(task);
        if (aiEnhancements != null) {
          // Update task with AI data
          task.aiData = TaskAIData(
            complexityScore:
                aiEnhancements['complexityScore']?.toDouble() ?? 0.5,
            confidenceLevel: aiEnhancements['confidence']?.toDouble() ?? 0.7,
            suggestedTags: List<String>.from(aiEnhancements['tags'] ?? []),
            optimizationTips:
                List<String>.from(aiEnhancements['optimizationTips'] ?? []),
            lastAnalyzed: DateTime.now(),
          );

          // Update estimated duration from AI
          if (aiEnhancements['estimatedDuration'] != null) {
            task.estimatedMinutes = aiEnhancements['estimatedDuration'];
          }

          // Add AI-suggested tags
          final aiTags = List<String>.from(aiEnhancements['tags'] ?? []);
          task.tags = <dynamic>{...task.tags, ...aiTags}.toList();
        }
      }

      // Save to Firebase
      await _firebaseService.saveTask(task);

      debugPrint('Task created successfully: ${task.title}');
      return task;
    } catch (e) {
      _setError('Failed to create task: ${e.toString()}');
      debugPrint('Create task error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing task
  Future<bool> updateTask(EnhancedTask task) async {
    try {
      _setLoading(true);
      _clearError();

      await _firebaseService.saveTask(task);

      debugPrint('Task updated successfully: ${task.title}');
      return true;
    } catch (e) {
      _setError('Failed to update task: ${e.toString()}');
      debugPrint('Update task error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firebaseService.deleteTask(taskId);

      debugPrint('Task deleted successfully: $taskId');
      return true;
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
      debugPrint('Delete task error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete a task
  Future<bool> completeTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.complete();
    return await updateTask(task);
  }

  // Start a task
  Future<bool> startTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.start();
    return await updateTask(task);
  }

  // Pause a task
  Future<bool> pauseTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.pause();
    return await updateTask(task);
  }

  // Resume a task
  Future<bool> resumeTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.resume();
    return await updateTask(task);
  }

  // Add subtask
  Future<bool> addSubtask(String taskId, String subtaskTitle,
      {String description = ''}) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subtask = TaskSubtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: subtaskTitle,
      description: description,
      createdAt: DateTime.now(),
    );
    task.addSubtask(subtask);
    return await updateTask(task);
  }

  // Complete subtask
  Future<bool> completeSubtask(String taskId, String subtaskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.completeSubtask(subtaskId);
    return await updateTask(task);
  }

  // Add comment to task
  Future<bool> addComment(String taskId, String content,
      {String authorId = 'current_user'}) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final comment = TaskComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      authorId: authorId,
      createdAt: DateTime.now(),
    );
    task.addComment(comment);
    return await updateTask(task);
  }

  // Add time entry to task
  Future<bool> addTimeEntry(
    String taskId,
    DateTime startTime, {
    DateTime? endTime,
    String description = '',
    bool isPomodoroSession = false,
  }) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final timeEntry = TaskTimeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: startTime,
      endTime: endTime,
      description: description,
      isPomodoroSession: isPomodoroSession,
    );
    task.addTimeEntry(timeEntry);
    return await updateTask(task);
  }

  // Load AI-powered task recommendations
  Future<void> loadRecommendations() async {
    try {
      final recommendations = await _firebaseService.getTaskRecommendations();
      _recommendations = recommendations;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recommendations: $e');
    }
  }

  // Get tasks by category
  List<EnhancedTask> getTasksByCategory(TaskCategory category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  // Get tasks by priority
  List<EnhancedTask> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  // Get tasks by status
  List<EnhancedTask> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Search tasks
  List<EnhancedTask> searchTasks(String query) {
    if (query.isEmpty) return _tasks;

    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Filter tasks by date range
  List<EnhancedTask> getTasksByDateRange(DateTime start, DateTime end) {
    return _tasks.where((task) {
      return task.createdAt.isAfter(start) && task.createdAt.isBefore(end);
    }).toList();
  }

  // Get productivity metrics
  Map<String, dynamic> getProductivityMetrics() {
    final totalTasks = _tasks.length;
    final completed = completedTasksCount;
    final inProgress =
        _tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final overdue = overdueTasks.length;

    return {
      'totalTasks': totalTasks,
      'completedTasks': completed,
      'inProgressTasks': inProgress,
      'overdueTasks': overdue,
      'completionRate': completionRate,
      'averageTimeSpent': _calculateAverageTimeSpent(),
    };
  }

  // Get tasks for today's focus
  List<EnhancedTask> getTodaysFocusTasks({int limit = 5}) {
    final today = DateTime.now();
    final focusTasks = _tasks.where((task) {
      return !task.isCompleted &&
          (task.dueDate?.day == today.day ||
              task.status == TaskStatus.inProgress ||
              task.priority == TaskPriority.high ||
              task.priority == TaskPriority.critical);
    }).toList();

    // Sort by urgency and priority
    focusTasks.sort((a, b) {
      final aUrgency = _getUrgencyScore(a);
      final bUrgency = _getUrgencyScore(b);
      return bUrgency.compareTo(aUrgency);
    });

    return focusTasks.take(limit).toList();
  }

  // Bulk operations
  Future<bool> bulkUpdateTasks(
      List<String> taskIds, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);

      for (final taskId in taskIds) {
        final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex != -1) {
          // Apply updates to task
          // This would need more sophisticated update logic based on the updates map
          await updateTask(_tasks[taskIndex]);
        }
      }

      return true;
    } catch (e) {
      _setError('Bulk update failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Archive completed tasks older than specified days
  Future<int> archiveOldCompletedTasks({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final tasksToArchive = completedTasks.where((task) {
      return task.completedAt != null && task.completedAt!.isBefore(cutoffDate);
    }).toList();

    int archivedCount = 0;
    for (final task in tasksToArchive) {
      task.archive();
      if (await updateTask(task)) {
        archivedCount++;
      }
    }

    return archivedCount;
  }

  // Export tasks to various formats
  Future<Map<String, dynamic>?> exportTasks({
    required String format,
    List<String>? taskIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _firebaseService.exportUserData(
        format: format,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError('Export failed: ${e.toString()}');
      return null;
    }
  }

  // Sync with external services
  Future<bool> syncWithExternal({
    required String provider,
    required Map<String, dynamic> credentials,
    bool bidirectional = true,
  }) async {
    try {
      _setSyncing(true);
      _clearError();

      final result = await _firebaseService.syncExternalTasks(
        provider: provider,
        credentials: credentials,
        bidirectional: bidirectional,
      );

      return result['success'] ?? false;
    } catch (e) {
      _setError('Sync failed: ${e.toString()}');
      return false;
    } finally {
      _setSyncing(false);
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>?> _getAIEnhancements(EnhancedTask task) async {
    // Check cache first
    final cacheKey = '${task.title}_${task.description}'.hashCode.toString();
    if (_aiProcessingCache.containsKey(cacheKey)) {
      return _aiProcessingCache[cacheKey];
    }

    try {
      final result = await _firebaseService.processTaskWithAI(
        title: task.title,
        description: task.description,
        category: task.category.name,
        priority: task.priority.name,
      );

      // Cache the result
      _aiProcessingCache[cacheKey] = result;

      // Limit cache size
      if (_aiProcessingCache.length > 50) {
        _aiProcessingCache.clear();
      }

      return result;
    } catch (e) {
      debugPrint('AI enhancement failed: $e');
      return null;
    }
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      // Sort by completion status first
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // Then by urgency
      final aUrgency = _getUrgencyScore(a);
      final bUrgency = _getUrgencyScore(b);
      if (aUrgency != bUrgency) {
        return bUrgency.compareTo(aUrgency);
      }

      // Finally by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  int _getUrgencyScore(EnhancedTask task) {
    int score = 0;

    // Priority score
    switch (task.priority) {
      case TaskPriority.critical:
        score += 4;
        break;
      case TaskPriority.high:
        score += 3;
        break;
      case TaskPriority.medium:
        score += 2;
        break;
      case TaskPriority.low:
        score += 1;
        break;
    }

    // Due date score
    if (task.isOverdue) {
      score += 5;
    } else if (task.isDueSoon) {
      score += 3;
    }

    // Status score
    if (task.status == TaskStatus.inProgress) {
      score += 2;
    }

    return score;
  }

  double _calculateAverageTimeSpent() {
    final completedWithTime =
        completedTasks.where((task) => task.actualMinutes != null);
    if (completedWithTime.isEmpty) return 0.0;

    final totalMinutes =
        completedWithTime.fold(0, (sum, task) => sum + task.actualMinutes!);
    return totalMinutes / completedWithTime.length;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
