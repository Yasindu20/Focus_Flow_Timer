import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/enhanced_task.dart';
import '../models/task.dart';
import '../models/ai_insights.dart';
import '../models/task_analytics.dart';
import '../services/firebase_service.dart';
import '../services/task_analytics_engine.dart';
import '../core/ai/task_intelligence_engine.dart';

/// Firebase-powered Smart Task Provider for enterprise features
/// Integrates AI task intelligence, real-time analytics, and cloud synchronization
class FirebaseSmartTaskProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final TaskIntelligenceEngine _aiEngine = TaskIntelligenceEngine();
  final TaskAnalyticsEngine _analyticsEngine = TaskAnalyticsEngine();
  
  // State management
  List<EnhancedTask> _tasks = [];
  UserAnalytics? _currentUserAnalytics;
  ProductivityInsights? _currentInsights;
  List<EnhancedTask> _recommendedTasks = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  
  // Real-time subscriptions
  StreamSubscription<List<EnhancedTask>>? _tasksSubscription;
  Timer? _analyticsRefreshTimer;

  FirebaseSmartTaskProvider({required FirebaseService firebaseService})
      : _firebaseService = firebaseService {
    _initializeProvider();
  }

  // Getters
  List<EnhancedTask> get tasks => _tasks;
  List<EnhancedTask> get activeTasks => _tasks
      .where((task) => !task.isCompleted && task.status != TaskStatus.archived)
      .toList();
  List<EnhancedTask> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  List<EnhancedTask> get recommendedTasks => _recommendedTasks;
  UserAnalytics? get userAnalytics => _currentUserAnalytics;
  ProductivityInsights? get productivityInsights => _currentInsights;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Advanced getters with AI sorting
  List<EnhancedTask> get prioritizedTasks {
    final sorted = activeTasks.toList();
    sorted.sort((a, b) {
      // Multi-factor sorting: urgency, priority, AI complexity, deadline
      final urgencyCompare = b.urgency.index.compareTo(a.urgency.index);
      if (urgencyCompare != 0) return urgencyCompare;

      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;

      final complexityCompare = b.aiData.complexityScore.compareTo(a.aiData.complexityScore);
      if (complexityCompare != 0) return complexityCompare;

      // Consider deadlines
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      return 0;
    });
    return sorted;
  }

  List<EnhancedTask> get todaysTasks {
    final today = DateTime.now();
    return activeTasks.where((task) {
      if (task.dueDate != null) {
        return task.dueDate!.day == today.day &&
               task.dueDate!.month == today.month &&
               task.dueDate!.year == today.year;
      }
      return false;
    }).toList();
  }

  List<EnhancedTask> get overdueTasks {
    final now = DateTime.now();
    return activeTasks.where((task) {
      return task.dueDate != null && task.dueDate!.isBefore(now);
    }).toList();
  }

  Map<TaskCategory, List<EnhancedTask>> get tasksByCategory {
    final Map<TaskCategory, List<EnhancedTask>> categorized = {};
    for (final task in activeTasks) {
      categorized[task.category] ??= [];
      categorized[task.category]!.add(task);
    }
    return categorized;
  }

  /// Initialize the provider with Firebase integration
  Future<void> _initializeProvider() async {
    _firebaseService.addListener(_onFirebaseServiceChanged);
    
    if (_firebaseService.isAuthenticated) {
      await _initializeUserData();
    }
  }

  /// Handle Firebase service state changes (login/logout)
  void _onFirebaseServiceChanged() {
    if (_firebaseService.isAuthenticated && !_isInitialized) {
      _initializeUserData();
    } else if (!_firebaseService.isAuthenticated) {
      _handleUserLogout();
    }
  }

  /// Initialize user-specific data and services
  Future<void> _initializeUserData() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      _clearError();

      // Initialize AI and analytics engines
      await _aiEngine.initialize();
      await _analyticsEngine.initialize();

      // Set up real-time task subscription
      await _setupRealTimeSync();

      // Load user analytics
      await _loadUserAnalytics();

      // Generate initial recommendations
      await _updateRecommendations();

      // Set up periodic analytics refresh
      _setupAnalyticsRefresh();

      _isInitialized = true;
      debugPrint('✅ Firebase Smart Task Provider initialized');
      
    } catch (e, stack) {
      _setError('Failed to initialize: ${e.toString()}');
      debugPrint('❌ Provider initialization failed: $e');
      debugPrint('Stack trace: $stack');
    } finally {
      _setLoading(false);
    }
  }

  /// Set up real-time task synchronization
  Future<void> _setupRealTimeSync() async {
    _tasksSubscription?.cancel();
    
    _tasksSubscription = _firebaseService.getUserTasks().listen(
      (tasks) {
        _tasks = tasks;
        _updateRecommendations();
        notifyListeners();
      },
      onError: (error) {
        _setError('Real-time sync error: ${error.toString()}');
      },
    );
  }

  /// Create a new task with AI enhancement
  Future<EnhancedTask> createTaskWithAI({
    required String title,
    required String description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String>? tags,
  }) async {
    if (!_firebaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      _setLoading(true);
      _clearError();

      // Create enhanced task with AI processing
      final task = EnhancedTask.create(
        title: title,
        description: description,
        category: category ?? TaskCategory.general,
        priority: priority ?? TaskPriority.medium,
        dueDate: dueDate,
        tags: tags ?? [],
      );

      // Process with local AI if available
      EnhancedTask enhancedTask = task;
      try {
        enhancedTask = await _aiEngine.enhanceTask(task, userAnalytics: _currentUserAnalytics);
      } catch (aiError) {
        debugPrint('⚠️ Local AI processing failed, using cloud AI: $aiError');
      }

      // Save to Firebase (which will trigger cloud AI processing)
      final taskId = await _firebaseService.createEnhancedTask(enhancedTask);
      
      // Update analytics
      await _updateTaskAnalytics('task_created', enhancedTask);

      // Refresh recommendations
      await _updateRecommendations();

      debugPrint('✅ Task created with AI: ${enhancedTask.title}');
      return enhancedTask.copyWith(id: taskId);
      
    } catch (e, stack) {
      _setError('Failed to create task: ${e.toString()}');
      debugPrint('❌ Task creation failed: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing task
  Future<void> updateTask(EnhancedTask task) async {
    if (!_firebaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      await _firebaseService.updateTask(task);
      await _updateTaskAnalytics('task_updated', task);
      await _updateRecommendations();
      
      debugPrint('✅ Task updated: ${task.title}');
      
    } catch (e) {
      _setError('Failed to update task: ${e.toString()}');
      rethrow;
    }
  }

  /// Complete a task
  Future<void> completeTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final completedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      status: TaskStatus.completed,
    );

    await updateTask(completedTask);
    await _updateTaskAnalytics('task_completed', completedTask);
    
    // Update user analytics immediately
    await _loadUserAnalytics();
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    if (!_firebaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      await _firebaseService.deleteTask(taskId);
      await _updateTaskAnalytics('task_deleted', null);
      
      debugPrint('✅ Task deleted: $taskId');
      
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
      rethrow;
    }
  }

  /// Archive a task
  Future<void> archiveTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final archivedTask = task.copyWith(status: TaskStatus.archived);
    await updateTask(archivedTask);
  }

  /// Start a task (mark as in progress)
  Future<void> startTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final startedTask = task.copyWith(
      status: TaskStatus.inProgress,
      lastWorkedAt: DateTime.now(),
    );
    await updateTask(startedTask);
  }

  /// Add a work session to a task
  Future<void> addWorkSession(String taskId, Duration duration, {int interruptions = 0}) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(
      actualDuration: task.actualDuration + duration,
      completedPomodoros: task.completedPomodoros + 1,
      lastWorkedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
    
    // Update analytics
    await _updateTaskAnalytics('work_session_completed', updatedTask);
  }

  /// Get AI-powered task recommendations
  Future<List<EnhancedTask>> getAIRecommendations() async {
    if (!_firebaseService.isAuthenticated) return [];

    try {
      final recommendations = await _firebaseService.getTaskRecommendations();
      return recommendations;
    } catch (e) {
      debugPrint('❌ Failed to get AI recommendations: $e');
      return _generateLocalRecommendations();
    }
  }

  /// Generate local recommendations based on available data
  List<EnhancedTask> _generateLocalRecommendations() {
    final now = DateTime.now();
    final hour = now.hour;

    return activeTasks
        .where((task) {
          // Recommend based on current time and patterns
          if (_currentUserAnalytics?.preferredWorkingHours.contains(hour) == true) {
            return task.priority.index >= TaskPriority.medium.index;
          }
          return task.priority.index >= TaskPriority.high.index;
        })
        .take(5)
        .toList();
  }

  /// Update task recommendations
  Future<void> _updateRecommendations() async {
    try {
      _recommendedTasks = await getAIRecommendations();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to update recommendations: $e');
    }
  }

  /// Load user analytics from Firebase
  Future<void> _loadUserAnalytics() async {
    if (!_firebaseService.isAuthenticated) return;

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      
      _currentUserAnalytics = await _firebaseService.getUserAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      _currentInsights = await _firebaseService.getProductivityInsights();
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load user analytics: $e');
    }
  }

  /// Update task-related analytics
  Future<void> _updateTaskAnalytics(String eventType, EnhancedTask? task) async {
    try {
      // This would be handled by Firebase Functions in a real implementation
      // For now, we'll just log the event
      debugPrint('📊 Analytics event: $eventType for task: ${task?.title ?? 'N/A'}');
    } catch (e) {
      debugPrint('❌ Failed to update analytics: $e');
    }
  }

  /// Set up periodic analytics refresh
  void _setupAnalyticsRefresh() {
    _analyticsRefreshTimer?.cancel();
    _analyticsRefreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _loadUserAnalytics(),
    );
  }

  /// Sync with external services (Jira, Asana, etc.)
  Future<Map<String, dynamic>> syncWithExternalService({
    required String provider,
    required Map<String, dynamic> credentials,
    bool bidirectional = true,
  }) async {
    if (!_firebaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      _setLoading(true);
      
      final result = await _firebaseService.syncWithExternalService(
        provider: provider,
        credentials: credentials,
        bidirectional: bidirectional,
      );

      // Refresh tasks after sync
      await _setupRealTimeSync();
      
      return result;
      
    } catch (e) {
      _setError('External sync failed: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Export user data
  Future<String> exportData({
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_firebaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    return await _firebaseService.exportUserData(
      format: format,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Search tasks with advanced filtering
  List<EnhancedTask> searchTasks({
    String? query,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    DateTime? dueBefore,
    DateTime? dueAfter,
  }) {
    return _tasks.where((task) {
      // Query search
      if (query != null && query.isNotEmpty) {
        final searchQuery = query.toLowerCase();
        if (!task.title.toLowerCase().contains(searchQuery) &&
            !task.description.toLowerCase().contains(searchQuery)) {
          return false;
        }
      }

      // Category filter
      if (category != null && task.category != category) {
        return false;
      }

      // Priority filter
      if (priority != null && task.priority != priority) {
        return false;
      }

      // Status filter
      if (status != null && task.status != status) {
        return false;
      }

      // Tags filter
      if (tags != null && tags.isNotEmpty) {
        if (!tags.every((tag) => task.tags.contains(tag))) {
          return false;
        }
      }

      // Date filters
      if (dueBefore != null && task.dueDate != null) {
        if (task.dueDate!.isAfter(dueBefore)) {
          return false;
        }
      }

      if (dueAfter != null && task.dueDate != null) {
        if (task.dueDate!.isBefore(dueAfter)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Get task statistics
  Map<String, dynamic> getTaskStatistics() {
    final total = _tasks.length;
    final completed = completedTasks.length;
    final active = activeTasks.length;
    final overdue = overdueTasks.length;

    final completionRate = total > 0 ? completed / total : 0.0;
    
    final priorityDistribution = <TaskPriority, int>{};
    final categoryDistribution = <TaskCategory, int>{};
    
    for (final task in _tasks) {
      priorityDistribution[task.priority] = 
          (priorityDistribution[task.priority] ?? 0) + 1;
      categoryDistribution[task.category] = 
          (categoryDistribution[task.category] ?? 0) + 1;
    }

    return {
      'total': total,
      'completed': completed,
      'active': active,
      'overdue': overdue,
      'completionRate': completionRate,
      'priorityDistribution': priorityDistribution,
      'categoryDistribution': categoryDistribution,
    };
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Handle user logout
  void _handleUserLogout() {
    _tasks.clear();
    _recommendedTasks.clear();
    _currentUserAnalytics = null;
    _currentInsights = null;
    _isInitialized = false;
    _tasksSubscription?.cancel();
    _analyticsRefreshTimer?.cancel();
    notifyListeners();
  }

  /// Clean up resources
  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _analyticsRefreshTimer?.cancel();
    _firebaseService.removeListener(_onFirebaseServiceChanged);
    super.dispose();
  }
}