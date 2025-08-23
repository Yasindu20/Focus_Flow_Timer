import 'package:flutter/foundation.dart';
import '../models/enhanced_task.dart';
import '../models/enhanced_task.dart' as enhanced;
import '../models/task.dart';
import '../models/ai_insights.dart';
import '../services/task_analytics_engine.dart';
import '../core/ai/task_intelligence_engine.dart';
import '../services/api_integration_service.dart';
import '../services/storage_service.dart';
import '../models/task_analytics.dart';

class SmartTaskProvider extends ChangeNotifier {
  final TaskIntelligenceEngine _aiEngine = TaskIntelligenceEngine();
  final TaskAnalyticsEngine _analyticsEngine = TaskAnalyticsEngine();
  final ApiIntegrationService _apiService = ApiIntegrationService();
  // State
  List<EnhancedTask> _tasks = [];
  UserAnalytics? _currentUserAnalytics;
  ProductivityInsights? _currentInsights;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _currentUserId;
  // Getters
  List<EnhancedTask> get tasks => _tasks;
  List<EnhancedTask> get activeTasks => _tasks
      .where((task) => !task.isCompleted && task.status != TaskStatus.archived)
      .toList();
  List<EnhancedTask> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  UserAnalytics? get userAnalytics => _currentUserAnalytics;
  ProductivityInsights? get productivityInsights => _currentInsights;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  // Smart getters
  List<EnhancedTask> get prioritizedTasks {
    final sorted = activeTasks.toList();
    sorted.sort((a, b) {
      // Sort by urgency first, then by AI complexity score
      final urgencyCompare = b.urgency.index.compareTo(a.urgency.index);
      if (urgencyCompare != 0) return urgencyCompare;

      return b.aiData.complexityScore.compareTo(a.aiData.complexityScore);
    });
    return sorted;
  }

  List<EnhancedTask> get recommendedTasks {
    final now = DateTime.now();
    final hour = now.hour;

    return activeTasks
        .where((task) {
          // Recommend tasks based on current time and user patterns
          if (_currentUserAnalytics?.preferredWorkingHours.contains(hour) ==
              true) {
            return task.priority.index >= TaskPriority.medium.index;
          }
          return task.priority.index >= TaskPriority.high.index;
        })
        .take(5)
        .toList();
  }

  /// Initialize the smart task system
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;
    try {
      _isLoading = true;
      _currentUserId = userId ?? 'default_user';

      // Initialize AI and analytics engines
      await _aiEngine.initialize();
      await _analyticsEngine.initialize();
      await _apiService.initialize();
      // Load tasks from storage
      await _loadTasks();
      // Load user analytics
      await _loadUserAnalytics();
      _isInitialized = true;
      debugPrint('SmartTaskProvider initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize SmartTaskProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new task with AI assistance
  Future<EnhancedTask> createTaskWithAI({
    required String title,
    required String description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String>? tags,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      // Use AI to analyze and enhance the task
      final categorization = await _aiEngine.categorizeTask(
        title: title,
        description: description,
        metadata: {
          'user_id': _currentUserId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      final estimation = await _aiEngine.estimateTaskDuration(
        title: title,
        description: description,
        category: categorization.suggestedCategory,
        priority: categorization.suggestedPriority,
        userId: _currentUserId,
        context: {
          'hour': DateTime.now().hour,
          'current_tasks': activeTasks.length,
        },
      );
      // Create enhanced task with AI data
      final task = EnhancedTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        category: category ?? categorization.suggestedCategory,
        priority: priority ?? categorization.suggestedPriority,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        estimatedMinutes: estimation.estimatedMinutes,
        tags: tags ?? categorization.smartTags,
        subtasks: estimation.suggestedBreakdown
            .map((breakdown) => enhanced.TaskSubtask(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: breakdown.title,
                  description: breakdown.description,
                  createdAt: DateTime.now(),
                  estimatedMinutes: breakdown.estimatedMinutes,
                ))
            .toList(),
        aiData: TaskAIData(
          complexityScore: estimation.complexityScore,
          confidenceLevel: estimation.confidenceLevel,
          suggestedTags: categorization.smartTags,
          relatedTaskIds: categorization.relatedTaskIds,
          categoryProbabilities: {
            categorization.suggestedCategory.name:
                categorization.categoryConfidence
          },
          optimizationTips: estimation.tips,
          lastAnalyzed: DateTime.now(),
        ),
      );
      // Add to tasks list
      _tasks.add(task);

      // Save to storage
      await StorageService.addTask(Task.fromEnhancedTask(task));

      notifyListeners();
      return task;
    } catch (e) {
      debugPrint('Error creating task with AI: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update task with AI re-analysis
  Future<void> updateTaskWithAI(EnhancedTask task) async {
    try {
      _isLoading = true;
      notifyListeners();
      // Re-analyze task with current data
      final categorization = await _aiEngine.categorizeTask(
        title: task.title,
        description: task.description,
        metadata: task.metadata,
      );
      final estimation = await _aiEngine.estimateTaskDuration(
        title: task.title,
        description: task.description,
        category: task.category,
        priority: task.priority,
        userId: _currentUserId,
        context: {
          'hour': DateTime.now().hour,
          'current_tasks': activeTasks.length,
          'completion_percentage': task.completionPercentage,
        },
      );
      // Update AI data
      final updatedTask = task.copyWith(
        estimatedMinutes: estimation.estimatedMinutes,
        aiData: task.aiData.copyWith(
          complexityScore: estimation.complexityScore,
          confidenceLevel: estimation.confidenceLevel,
          optimizationTips: estimation.tips,
          lastAnalyzed: DateTime.now(),
        ),
      );
      // Update in list
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        await StorageService.updateTask(Task.fromEnhancedTask(updatedTask));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating task with AI: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Complete a task and learn from it
  Future<void> completeTask(
    String taskId, {
    int? actualMinutes,
    double? difficultyRating,
    int? interruptions,
  }) async {
    try {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;
      final task = _tasks[taskIndex];

      // Update task completion data
      final completedTask = task.copyWith(
        actualMinutes: actualMinutes,
        difficultyRating: difficultyRating,
      );

      completedTask.complete();
      // Create completion data for AI learning
      final completionData = TaskCompletionData(
        taskId: taskId,
        userId: _currentUserId!,
        title: task.title,
        description: task.description,
        category: task.category,
        priority: task.priority,
        estimatedDuration: Duration(minutes: task.estimatedMinutes),
        timeSpent: Duration(minutes: actualMinutes ?? task.estimatedMinutes),
        startTime: task.timeEntries.isNotEmpty
            ? task.timeEntries.first.startTime
            : task.createdAt,
        completedAt: DateTime.now(),
        completed: true,
        difficultyRating: difficultyRating ?? 0.5,
        interruptions: interruptions,
        complexityScore: task.aiData.complexityScore,
        context: {
          'hour': DateTime.now().hour,
          'day_of_week': DateTime.now().weekday,
          'session_count': task.timeEntries.length,
        },
      );
      // Let AI learn from this completion
      await _aiEngine.learnFromCompletion(completionData);

      // Record for analytics
      await _analyticsEngine.recordTaskCompletion(completionData);
      // Update task in list and storage
      _tasks[taskIndex] = completedTask;
      await StorageService.updateTask(Task.fromEnhancedTask(completedTask));
      // Refresh analytics
      await _refreshAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing task: $e');
    }
  }

  /// Get AI-powered schedule recommendations
  Future<List<ScheduledTaskRecommendation>> getScheduleRecommendations({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? taskIds,
  }) async {
    try {
      final tasksToSchedule = taskIds != null
          ? _tasks.where((t) => taskIds.contains(t.id)).toList()
          : activeTasks;
      final recommendation = await _aiEngine.recommendSchedule(
        tasks: tasksToSchedule,
        startDate: startDate,
        endDate: endDate,
        constraints: {
          'userId': _currentUserId,
          'workingHours': _currentUserAnalytics?.preferredWorkingHours ??
              [9, 10, 11, 14, 15, 16],
          'maxTasksPerDay': 8,
          'preferredBreakLength': 15,
        },
      );
      return recommendation.recommendedSchedule
          .map((scheduled) => ScheduledTaskRecommendation(
                task: _tasks.firstWhere((t) => t.id == scheduled.taskId),
                scheduledStart: scheduled.startTime,
                scheduledEnd: scheduled.endTime,
                confidence: scheduled.confidence,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting schedule recommendations: $e');
      return [];
    }
  }

  /// Get productivity insights
  Future<ProductivityInsights> getProductivityInsights({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final insights = await _analyticsEngine.getProductivityInsights(
        userId: _currentUserId!,
        startDate:
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
      _currentInsights = insights;
      notifyListeners();

      return insights;
    } catch (e) {
      debugPrint('Error getting productivity insights: $e');
      return ProductivityInsights.empty();
    }
  }

  /// Sync with external services
  Future<bool> syncWithExternalService(String provider) async {
    try {
      _isLoading = true;
      notifyListeners();
      final syncResult = await _apiService.syncTasks(
        provider: provider,
        localTasks: _tasks,
        bidirectional: true,
      );
      if (syncResult.success) {
        // Update local tasks with synced data
        for (final pulledTask in syncResult.pulledTasks) {
          final existingIndex = _tasks.indexWhere((t) => t.id == pulledTask.id);
          if (existingIndex == -1) {
            _tasks.add(pulledTask);
          } else {
            _tasks[existingIndex] = pulledTask;
          }
        }

        await _saveTasks();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error syncing with $provider: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export analytics data
  Future<Map<String, dynamic>> exportAnalytics({
    required DateTime startDate,
    required DateTime endDate,
    required List<String> metrics,
  }) async {
    try {
      return await _analyticsEngine.exportAnalyticsData(
        userId: _currentUserId!,
        startDate: startDate,
        endDate: endDate,
        metrics: metrics,
      );
    } catch (e) {
      debugPrint('Error exporting analytics: $e');
      return {};
    }
  }

  /// Get AI insights
  Future<AIInsights> getAIInsights({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _aiEngine.generateInsights(
        userId: _currentUserId!,
        startDate:
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting AI insights: $e');
      return AIInsights.empty(_currentUserId ?? 'default');
    }
  }

  /// Search tasks with smart filtering
  List<EnhancedTask> searchTasks({
    String? query,
    List<TaskCategory>? categories,
    List<TaskPriority>? priorities,
    TaskStatus? status,
    DateRange? dateRange,
    List<String>? tags,
  }) {
    var filteredTasks = _tasks;
    // Text search
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filteredTasks = filteredTasks
          .where((task) =>
              task.title.toLowerCase().contains(lowerQuery) ||
              task.description.toLowerCase().contains(lowerQuery) ||
              task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();
    }
    // Category filter
    if (categories != null && categories.isNotEmpty) {
      filteredTasks = filteredTasks
          .where((task) => categories.contains(task.category))
          .toList();
    }
    // Priority filter
    if (priorities != null && priorities.isNotEmpty) {
      filteredTasks = filteredTasks
          .where((task) => priorities.contains(task.priority))
          .toList();
    }
    // Status filter
    if (status != null) {
      filteredTasks =
          filteredTasks.where((task) => task.status == status).toList();
    }
    // Date range filter
    if (dateRange != null) {
      filteredTasks = filteredTasks.where((task) {
        final taskDate = task.dueDate ?? task.createdAt;
        return taskDate.isAfter(dateRange.start) &&
            taskDate.isBefore(dateRange.end);
      }).toList();
    }
    // Tags filter
    if (tags != null && tags.isNotEmpty) {
      filteredTasks = filteredTasks
          .where((task) => tags.any((tag) => task.tags.contains(tag)))
          .toList();
    }
    return filteredTasks;
  }

  // CRUD Operations
  Future<void> addTask(EnhancedTask task) async {
    _tasks.add(task);
    await StorageService.addTask(Task.fromEnhancedTask(task));
    notifyListeners();
  }

  Future<void> updateTask(EnhancedTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await StorageService.updateTask(Task.fromEnhancedTask(task));
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await StorageService.deleteTask(taskId);
    notifyListeners();
  }

  EnhancedTask? getTask(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // Private Methods
  Future<void> _loadTasks() async {
    try {
      final storedTasks = StorageService.tasks;
      _tasks = storedTasks.map((task) => task.toEnhancedTask()).toList();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _tasks = [];
    }
  }

  Future<void> _saveTasks() async {
    try {
      for (final task in _tasks) {
        await StorageService.updateTask(Task.fromEnhancedTask(task));
      }
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  Future<void> _loadUserAnalytics() async {
    try {
      _currentUserAnalytics =
          await _analyticsEngine.getUserAnalytics(_currentUserId!);
    } catch (e) {
      debugPrint('Error loading user analytics: $e');
    }
  }

  Future<void> _refreshAnalytics() async {
    try {
      _currentUserAnalytics =
          await _analyticsEngine.getUserAnalytics(_currentUserId!);
    } catch (e) {
      debugPrint('Error refreshing analytics: $e');
    }
  }
}

// Supporting Classes
class ScheduledTaskRecommendation {
  final EnhancedTask task;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final double confidence;
  ScheduledTaskRecommendation({
    required this.task,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.confidence,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);
}
