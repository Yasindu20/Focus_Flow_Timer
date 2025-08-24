import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enhanced_task.dart';

class FreeApiIntegrationService {
  static final FreeApiIntegrationService _instance =
      FreeApiIntegrationService._internal();
  factory FreeApiIntegrationService() => _instance;
  FreeApiIntegrationService._internal();

  Map<String, IntegrationConfig> _integrations = {};
  bool _isInitialized = false;
  final Map<String, List<DateTime>> _rateLimitHistory = {};

  /// Initialize the service with free API configurations
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadIntegrationConfigs();
    _isInitialized = true;
    debugPrint('FreeApiIntegrationService initialized');
  }

  /// Configure free tier integration
  Future<void> configureIntegration({
    required String provider,
    required String apiKey,
    String? baseUrl,
    Map<String, dynamic>? config,
  }) async {
    _integrations[provider] = IntegrationConfig(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      config: config ?? {},
      isEnabled: true,
    );
    await _saveIntegrationConfig(provider);
  }

  /// Sync tasks with free tier external systems
  Future<TaskSyncResult> syncTasks({
    required String provider,
    List<EnhancedTask>? localTasks,
    bool bidirectional = true,
  }) async {
    try {
      if (!_isIntegrationEnabled(provider)) {
        throw ApiException('Integration not enabled: $provider');
      }

      if (!await _checkRateLimit(provider)) {
        throw ApiException('Rate limit exceeded for $provider');
      }

      final config = _integrations[provider]!;

      switch (provider.toLowerCase()) {
        case 'todoist':
          return await _syncWithTodoist(config, localTasks, bidirectional);
        case 'github':
          return await _syncWithGitHub(config, localTasks, bidirectional);
        case 'clickup':
          return await _syncWithClickUp(config, localTasks, bidirectional);
        case 'local':
          return await _syncWithLocal(config, localTasks, bidirectional);
        default:
          throw ApiException('Unsupported provider: $provider');
      }
    } catch (e) {
      debugPrint('Error syncing tasks with $provider: $e');
      return TaskSyncResult()
        ..success = false
        ..message = 'Sync failed: $e';
    }
  }

  /// Push task to external system with free tier limits
  Future<ExternalTaskRef?> pushTask({
    required String provider,
    required EnhancedTask task,
    Map<String, dynamic>? options,
  }) async {
    if (!_isIntegrationEnabled(provider)) {
      throw ApiException('Integration not enabled: $provider');
    }

    if (!await _checkRateLimit(provider)) {
      debugPrint('Rate limit exceeded for $provider, queuing for later');
      return null; // Will be retried later
    }

    final config = _integrations[provider]!;

    switch (provider.toLowerCase()) {
      case 'todoist':
        return await _pushToTodoist(config, task, options);
      case 'github':
        return await _pushToGitHub(config, task, options);
      case 'clickup':
        return await _pushToClickUp(config, task, options);
      case 'local':
        return await _pushToLocal(config, task, options);
      default:
        throw ApiException('Unsupported provider: $provider');
    }
  }

  /// Pull tasks from external system
  Future<List<EnhancedTask>> pullTasks({
    required String provider,
    Map<String, dynamic>? filters,
  }) async {
    if (!_isIntegrationEnabled(provider)) {
      throw ApiException('Integration not enabled: $provider');
    }

    if (!await _checkRateLimit(provider)) {
      debugPrint('Rate limit exceeded for $provider, returning cached data');
      return await _getCachedTasks(provider);
    }

    final config = _integrations[provider]!;

    switch (provider.toLowerCase()) {
      case 'todoist':
        return await _pullFromTodoist(config, filters);
      case 'github':
        return await _pullFromGitHub(config, filters);
      case 'clickup':
        return await _pullFromClickUp(config, filters);
      case 'local':
        return await _pullFromLocal(config, filters);
      default:
        throw ApiException('Unsupported provider: $provider');
    }
  }

  // Todoist Free Tier Integration (Free: 5 projects, 150 tasks per project)
  Future<TaskSyncResult> _syncWithTodoist(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    final syncResult = TaskSyncResult();

    try {
      // Pull from Todoist
      final todoistTasks = await _getTodoistTasks(config);
      final pulledTasks = _convertTodoistTasksToEnhanced(todoistTasks);
      syncResult.pulledTasks = pulledTasks;

      // Cache for offline access
      await _cacheTasks('todoist', pulledTasks);

      // Push to Todoist (if bidirectional and within limits)
      if (bidirectional && localTasks != null) {
        for (final task in localTasks.take(10)) {
          // Limit to avoid hitting API limits
          if (!_hasExternalRef(task, 'todoist')) {
            final todoistTask = await _createTodoistTask(config, task);
            if (todoistTask != null) {
              syncResult.pushedTasks.add(task);
            }
          }
        }
      }

      syncResult.success = true;
      syncResult.message = 'Successfully synced with Todoist';
    } catch (e) {
      syncResult.success = false;
      syncResult.message = 'Todoist sync failed: $e';
    }

    return syncResult;
  }

  // GitHub Free Tier Integration (Free: Unlimited public repos)
  Future<TaskSyncResult> _syncWithGitHub(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    final syncResult = TaskSyncResult();

    try {
      // Pull from GitHub Issues
      final issues = await _getGitHubIssues(config);
      final pulledTasks = _convertGitHubIssuesToTasks(issues);
      syncResult.pulledTasks = pulledTasks;

      await _cacheTasks('github', pulledTasks);

      // Push to GitHub (if bidirectional)
      if (bidirectional && localTasks != null) {
        for (final task in localTasks.take(5)) {
          // Be conservative with GitHub API
          if (!_hasExternalRef(task, 'github')) {
            final issue = await _createGitHubIssue(config, task);
            if (issue != null) {
              syncResult.pushedTasks.add(task);
            }
          }
        }
      }

      syncResult.success = true;
      syncResult.message = 'Successfully synced with GitHub';
    } catch (e) {
      syncResult.success = false;
      syncResult.message = 'GitHub sync failed: $e';
    }

    return syncResult;
  }

  // ClickUp Free Tier Integration (Free: 100MB storage, unlimited tasks)
  Future<TaskSyncResult> _syncWithClickUp(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    final syncResult = TaskSyncResult();

    try {
      final clickupTasks = await _getClickUpTasks(config);
      final pulledTasks = _convertClickUpTasksToEnhanced(clickupTasks);
      syncResult.pulledTasks = pulledTasks;

      await _cacheTasks('clickup', pulledTasks);

      if (bidirectional && localTasks != null) {
        for (final task in localTasks.take(15)) {
          // ClickUp has generous limits
          if (!_hasExternalRef(task, 'clickup')) {
            final clickupTask = await _createClickUpTask(config, task);
            if (clickupTask != null) {
              syncResult.pushedTasks.add(task);
            }
          }
        }
      }

      syncResult.success = true;
      syncResult.message = 'Successfully synced with ClickUp';
    } catch (e) {
      syncResult.success = false;
      syncResult.message = 'ClickUp sync failed: $e';
    }

    return syncResult;
  }

  // Local offline sync
  Future<TaskSyncResult> _syncWithLocal(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    final syncResult = TaskSyncResult();

    try {
      // This handles offline sync and local backup
      if (localTasks != null) {
        await _cacheTasksLocally(localTasks);
        syncResult.pushedTasks = localTasks;
      }

      final cachedTasks = await _getCachedTasks('local');
      syncResult.pulledTasks = cachedTasks;

      syncResult.success = true;
      syncResult.message = 'Local sync completed';
    } catch (e) {
      syncResult.success = false;
      syncResult.message = 'Local sync failed: $e';
    }

    return syncResult;
  }

  // API Implementation Methods
  Future<List<Map<String, dynamic>>> _getTodoistTasks(
      IntegrationConfig config) async {
    final response = await http.get(
      Uri.parse('https://api.todoist.com/rest/v2/tasks'),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to fetch Todoist tasks: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> _getGitHubIssues(
      IntegrationConfig config) async {
    final repo = config.config['repository'] ?? 'user/repo';
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$repo/issues'),
      headers: {
        'Authorization': 'token ${config.apiKey}',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to fetch GitHub issues: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> _getClickUpTasks(
      IntegrationConfig config) async {
    final listId = config.config['list_id'] ?? '';
    final response = await http.get(
      Uri.parse('https://api.clickup.com/api/v2/list/$listId/task'),
      headers: {
        'Authorization': config.apiKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['tasks'] ?? []);
    } else {
      throw ApiException('Failed to fetch ClickUp tasks: ${response.body}');
    }
  }

  // Convert external tasks to EnhancedTask
  List<EnhancedTask> _convertTodoistTasksToEnhanced(
      List<Map<String, dynamic>> tasks) {
    return tasks.map((task) {
      return EnhancedTask(
        id: 'todoist_${task['id']}',
        title: task['content'] ?? '',
        description: task['description'] ?? '',
        createdAt: DateTime.parse(task['created_at']),
        category: _mapTodoistProject(task['project_id']),
        priority: _mapTodoistPriority(task['priority']),
        metadata: {
          'external_provider': 'todoist',
          'external_id': task['id'].toString(),
          'external_url': task['url'],
        },
      );
    }).toList();
  }

  List<EnhancedTask> _convertGitHubIssuesToTasks(
      List<Map<String, dynamic>> issues) {
    return issues.map((issue) {
      return EnhancedTask(
        id: 'github_${issue['number']}',
        title: issue['title'] ?? '',
        description: issue['body'] ?? '',
        createdAt: DateTime.parse(issue['created_at']),
        category: _mapGitHubLabels(issue['labels']),
        priority: _mapGitHubPriority(issue['labels']),
        metadata: {
          'external_provider': 'github',
          'external_id': issue['number'].toString(),
          'external_url': issue['html_url'],
        },
      );
    }).toList();
  }

  List<EnhancedTask> _convertClickUpTasksToEnhanced(
      List<Map<String, dynamic>> tasks) {
    return tasks.map((task) {
      return EnhancedTask(
        id: 'clickup_${task['id']}',
        title: task['name'] ?? '',
        description: task['description'] ?? '',
        createdAt: DateTime.parse(task['date_created']),
        category: _mapClickUpStatus(task['status']),
        priority: _mapClickUpPriority(task['priority']),
        metadata: {
          'external_provider': 'clickup',
          'external_id': task['id'].toString(),
          'external_url': task['url'],
        },
      );
    }).toList();
  }

  // Create external tasks
  Future<Map<String, dynamic>?> _createTodoistTask(
    IntegrationConfig config,
    EnhancedTask task,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.todoist.com/rest/v2/tasks'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': task.title,
          'description': task.description,
          'priority': _mapPriorityToTodoist(task.priority),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error creating Todoist task: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _createGitHubIssue(
    IntegrationConfig config,
    EnhancedTask task,
  ) async {
    try {
      final repo = config.config['repository'] ?? 'user/repo';
      final response = await http.post(
        Uri.parse('https://api.github.com/repos/$repo/issues'),
        headers: {
          'Authorization': 'token ${config.apiKey}',
          'Accept': 'application/vnd.github.v3+json',
        },
        body: jsonEncode({
          'title': task.title,
          'body': task.description,
          'labels': _mapCategoryToGitHubLabels(task.category),
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error creating GitHub issue: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _createClickUpTask(
    IntegrationConfig config,
    EnhancedTask task,
  ) async {
    try {
      final listId = config.config['list_id'] ?? '';
      final response = await http.post(
        Uri.parse('https://api.clickup.com/api/v2/list/$listId/task'),
        headers: {
          'Authorization': config.apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': task.title,
          'description': task.description,
          'priority': _mapPriorityToClickUp(task.priority),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error creating ClickUp task: $e');
    }
    return null;
  }

  // Push methods
  Future<ExternalTaskRef> _pushToTodoist(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    final todoistTask = await _createTodoistTask(config, task);
    if (todoistTask != null) {
      return ExternalTaskRef(
        provider: 'todoist',
        externalId: todoistTask['id'].toString(),
        url: todoistTask['url'],
      );
    }
    throw ApiException('Failed to create Todoist task');
  }

  Future<ExternalTaskRef> _pushToGitHub(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    final issue = await _createGitHubIssue(config, task);
    if (issue != null) {
      return ExternalTaskRef(
        provider: 'github',
        externalId: issue['number'].toString(),
        url: issue['html_url'],
      );
    }
    throw ApiException('Failed to create GitHub issue');
  }

  Future<ExternalTaskRef> _pushToClickUp(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    final clickupTask = await _createClickUpTask(config, task);
    if (clickupTask != null) {
      return ExternalTaskRef(
        provider: 'clickup',
        externalId: clickupTask['id'].toString(),
        url: clickupTask['url'],
      );
    }
    throw ApiException('Failed to create ClickUp task');
  }

  Future<ExternalTaskRef> _pushToLocal(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    // Store in local cache
    await _cacheTask('local', task);
    return ExternalTaskRef(
      provider: 'local',
      externalId: task.id,
      url: null,
    );
  }

  // Pull methods
  Future<List<EnhancedTask>> _pullFromTodoist(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    final tasks = await _getTodoistTasks(config);
    final enhancedTasks = _convertTodoistTasksToEnhanced(tasks);
    await _cacheTasks('todoist', enhancedTasks);
    return enhancedTasks;
  }

  Future<List<EnhancedTask>> _pullFromGitHub(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    final issues = await _getGitHubIssues(config);
    final enhancedTasks = _convertGitHubIssuesToTasks(issues);
    await _cacheTasks('github', enhancedTasks);
    return enhancedTasks;
  }

  Future<List<EnhancedTask>> _pullFromClickUp(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    final tasks = await _getClickUpTasks(config);
    final enhancedTasks = _convertClickUpTasksToEnhanced(tasks);
    await _cacheTasks('clickup', enhancedTasks);
    return enhancedTasks;
  }

  Future<List<EnhancedTask>> _pullFromLocal(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    return await _getCachedTasks('local');
  }

  // Helper methods for caching and rate limiting
  Future<bool> _checkRateLimit(String provider) async {
    final now = DateTime.now();
    _rateLimitHistory[provider] ??= [];

    // Different rate limits for different providers
    final limits = {
      'todoist': {'requests': 450, 'window': 15}, // 450 requests per 15 minutes
      'github': {'requests': 5000, 'window': 60}, // 5000 requests per hour
      'clickup': {'requests': 100, 'window': 1}, // 100 requests per minute
      'local': {'requests': 1000000, 'window': 1}, // No limit for local
    };

    final limit = limits[provider] ?? {'requests': 60, 'window': 1};
    final windowMinutes = limit['window'] as int;
    final maxRequests = limit['requests'] as int;

    // Remove old requests
    _rateLimitHistory[provider]!.removeWhere(
      (time) => now.difference(time).inMinutes >= windowMinutes,
    );

    if (_rateLimitHistory[provider]!.length >= maxRequests) {
      return false;
    }

    _rateLimitHistory[provider]!.add(now);
    return true;
  }

  Future<void> _cacheTasks(String provider, List<EnhancedTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => task.toJson()).toList();
    await prefs.setString('cached_tasks_$provider', jsonEncode(tasksJson));
  }

  Future<void> _cacheTask(String provider, EnhancedTask task) async {
    final cachedTasks = await _getCachedTasks(provider);
    cachedTasks.add(task);
    await _cacheTasks(provider, cachedTasks);
  }

  Future<List<EnhancedTask>> _getCachedTasks(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString('cached_tasks_$provider') ?? '[]';
      final tasksList = jsonDecode(tasksJson) as List;
      return tasksList.map((json) => EnhancedTask.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading cached tasks for $provider: $e');
      return [];
    }
  }

  Future<void> _cacheTasksLocally(List<EnhancedTask> tasks) async {
    await _cacheTasks('local', tasks);
  }

  bool _isIntegrationEnabled(String provider) {
    return _integrations.containsKey(provider) &&
        _integrations[provider]!.isEnabled;
  }

  bool _hasExternalRef(EnhancedTask task, String provider) {
    return task.metadata['external_provider'] == provider &&
        task.metadata['external_id'] != null;
  }

  Future<void> _loadIntegrationConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString('integration_configs') ?? '{}';
    final configs = jsonDecode(configsJson) as Map<String, dynamic>;

    _integrations = configs
        .map((key, value) => MapEntry(key, IntegrationConfig.fromJson(value)));
  }

  Future<void> _saveIntegrationConfig(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    final configs =
        _integrations.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString('integration_configs', jsonEncode(configs));
  }

  // Mapping methods
  TaskCategory _mapTodoistProject(String? projectId) {
    // Map Todoist projects to categories
    return TaskCategory.general;
  }

  TaskPriority _mapTodoistPriority(int? priority) {
    switch (priority) {
      case 4:
        return TaskPriority.critical;
      case 3:
        return TaskPriority.high;
      case 2:
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  TaskCategory _mapGitHubLabels(List? labels) {
    if (labels == null) return TaskCategory.general;
    for (final label in labels) {
      final name = label['name']?.toString().toLowerCase();
      if (name?.contains('bug') == true) return TaskCategory.testing;
      if (name?.contains('feature') == true) return TaskCategory.coding;
      if (name?.contains('documentation') == true)
        return TaskCategory.documentation;
    }
    return TaskCategory.general;
  }

  TaskPriority _mapGitHubPriority(List? labels) {
    if (labels == null) return TaskPriority.medium;
    for (final label in labels) {
      final name = label['name']?.toString().toLowerCase();
      if (name?.contains('critical') == true) return TaskPriority.critical;
      if (name?.contains('high') == true) return TaskPriority.high;
      if (name?.contains('low') == true) return TaskPriority.low;
    }
    return TaskPriority.medium;
  }

  TaskCategory _mapClickUpStatus(Map<String, dynamic>? status) {
    if (status == null) return TaskCategory.general;
    final statusName = status['status']?.toString().toLowerCase();
    if (statusName?.contains('progress') == true) return TaskCategory.coding;
    if (statusName?.contains('review') == true) return TaskCategory.review;
    return TaskCategory.general;
  }

  TaskPriority _mapClickUpPriority(Map<String, dynamic>? priority) {
    if (priority == null) return TaskPriority.medium;
    final priorityValue = priority['priority']?.toString();
    switch (priorityValue) {
      case '1':
        return TaskPriority.critical;
      case '2':
        return TaskPriority.high;
      case '3':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  int _mapPriorityToTodoist(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return 4;
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }

  List<String> _mapCategoryToGitHubLabels(TaskCategory category) {
    switch (category) {
      case TaskCategory.coding:
        return ['feature'];
      case TaskCategory.testing:
        return ['bug'];
      case TaskCategory.documentation:
        return ['documentation'];
      case TaskCategory.review:
        return ['review'];
      default:
        return ['task'];
    }
  }

  int _mapPriorityToClickUp(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return 1;
      case TaskPriority.high:
        return 2;
      case TaskPriority.medium:
        return 3;
      case TaskPriority.low:
        return 4;
    }
  }
}

// Supporting Classes
class IntegrationConfig {
  final String provider;
  final String apiKey;
  final String? baseUrl;
  final Map<String, dynamic> config;
  final bool isEnabled;

  IntegrationConfig({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    required this.config,
    required this.isEnabled,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'config': config,
        'isEnabled': isEnabled,
      };

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) {
    return IntegrationConfig(
      provider: json['provider'],
      apiKey: json['apiKey'],
      baseUrl: json['baseUrl'],
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}

class TaskSyncResult {
  bool success = false;
  String message = '';
  List<EnhancedTask> pulledTasks = [];
  List<EnhancedTask> pushedTasks = [];
  List<String> errors = [];
  DateTime timestamp = DateTime.now();
}

class ExternalTaskRef {
  final String provider;
  final String externalId;
  final String? url;
  final Map<String, dynamic> metadata;

  ExternalTaskRef({
    required this.provider,
    required this.externalId,
    this.url,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}
