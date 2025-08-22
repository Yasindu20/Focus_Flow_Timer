import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/enhanced_task.dart';
import '../models/api_models.dart';

class ApiIntegrationService {
  static final ApiIntegrationService _instance =
      ApiIntegrationService._internal();
  factory ApiIntegrationService() => _instance;
  ApiIntegrationService._internal();
  // Configuration
  String? _baseUrl;
  String? _apiKey;
  Map<String, String> _headers = {};
  bool _isInitialized = false;
  // Supported integrations
  final Map<String, IntegrationConfig> _integrations = {};
  // Rate limiting
  final Map<String, List<DateTime>> _rateLimitHistory = {};
  final int _maxRequestsPerMinute = 60;

  /// Initialize the API service
  Future<void> initialize({
    String? baseUrl,
    String? apiKey,
    Map<String, String>? headers,
  }) async {
    _baseUrl = baseUrl ?? 'https://api.focusflow.com/v1';
    _apiKey = apiKey;
    _headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      ...?headers,
    };
    await _loadIntegrationConfigs();
    _isInitialized = true;
    debugPrint('ApiIntegrationService initialized');
  }

  /// Configure third-party integration
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

  /// Sync tasks with external system
  Future<TaskSyncResult> syncTasks({
    required String provider,
    List<EnhancedTask>? localTasks,
    bool bidirectional = true,
  }) async {
    try {
      if (!_isIntegrationEnabled(provider)) {
        throw ApiException('Integration not enabled: $provider');
      }
      final config = _integrations[provider]!;
      final syncResult = TaskSyncResult();
      switch (provider.toLowerCase()) {
        case 'jira':
          return await _syncWithJira(config, localTasks, bidirectional);
        case 'asana':
          return await _syncWithAsana(config, localTasks, bidirectional);
        case 'trello':
          return await _syncWithTrello(config, localTasks, bidirectional);
        case 'notion':
          return await _syncWithNotion(config, localTasks, bidirectional);
        case 'todoist':
          return await _syncWithTodoist(config, localTasks, bidirectional);
        case 'github':
          return await _syncWithGitHub(config, localTasks, bidirectional);
        default:
          throw ApiException('Unsupported provider: $provider');
      }
    } catch (e) {
      debugPrint('Error syncing tasks with $provider: $e');
      rethrow;
    }
  }

  /// Push task to external system
  Future<ExternalTaskRef> pushTask({
    required String provider,
    required EnhancedTask task,
    Map<String, dynamic>? options,
  }) async {
    if (!_isIntegrationEnabled(provider)) {
      throw ApiException('Integration not enabled: $provider');
    }
    final config = _integrations[provider]!;
    switch (provider.toLowerCase()) {
      case 'jira':
        return await _pushToJira(config, task, options);
      case 'asana':
        return await _pushToAsana(config, task, options);
      case 'trello':
        return await _pushToTrello(config, task, options);
      case 'notion':
        return await _pushToNotion(config, task, options);
      case 'todoist':
        return await _pushToTodoist(config, task, options);
      case 'github':
        return await _pushToGitHub(config, task, options);
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
    final config = _integrations[provider]!;
    switch (provider.toLowerCase()) {
      case 'jira':
        return await _pullFromJira(config, filters);
      case 'asana':
        return await _pullFromAsana(config, filters);
      case 'trello':
        return await _pullFromTrello(config, filters);
      case 'notion':
        return await _pullFromNotion(config, filters);
      case 'todoist':
        return await _pullFromTodoist(config, filters);
      case 'github':
        return await _pullFromGitHub(config, filters);
      default:
        throw ApiException('Unsupported provider: $provider');
    }
  }

  /// Export analytics data
  Future<AnalyticsExport> exportAnalytics({
    required String provider,
    required DateTime startDate,
    required DateTime endDate,
    required String format, // 'json', 'csv', 'xlsx'
    Map<String, dynamic>? options,
  }) async {
    try {
      final endpoint = '$_baseUrl/analytics/export';
      final body = {
        'provider': provider,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'format': format,
        'options': options ?? {},
      };
      final response = await _makeRequest('POST', endpoint, body: body);
      return AnalyticsExport.fromJson(response);
    } catch (e) {
      debugPrint('Error exporting analytics: $e');
      rethrow;
    }
  }

  /// Webhook management
  Future<WebhookResponse> createWebhook({
    required String provider,
    required String url,
    required List<String> events,
    Map<String, String>? headers,
  }) async {
    try {
      final endpoint = '$_baseUrl/webhooks';
      final body = {
        'provider': provider,
        'url': url,
        'events': events,
        'headers': headers ?? {},
      };
      final response = await _makeRequest('POST', endpoint, body: body);
      return WebhookResponse.fromJson(response);
    } catch (e) {
      debugPrint('Error creating webhook: $e');
      rethrow;
    }
  }

  /// Real-time notifications
  Stream<ApiNotification> getNotificationStream(String provider) {
    final controller = StreamController<ApiNotification>.broadcast();

    // WebSocket or SSE implementation would go here
    // For now, return empty stream

    return controller.stream;
  }

  // Private Methods
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    if (!await _checkRateLimit()) {
      throw ApiException('Rate limit exceeded');
    }
    try {
      final uri = Uri.parse(url);
      final finalUri =
          queryParams != null ? uri.replace(queryParameters: queryParams) : uri;
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(finalUri, headers: _headers);
          break;
        case 'POST':
          response = await http.post(
            finalUri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            finalUri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(finalUri, headers: _headers);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Network error: No internet connection');
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed: $e');
    }
  }

  Future<bool> _checkRateLimit() async {
    final now = DateTime.now();
    const key = 'global';

    _rateLimitHistory[key] ??= [];

    // Remove requests older than 1 minute
    _rateLimitHistory[key]!.removeWhere(
      (time) => now.difference(time).inMinutes >= 1,
    );

    if (_rateLimitHistory[key]!.length >= _maxRequestsPerMinute) {
      return false;
    }

    _rateLimitHistory[key]!.add(now);
    return true;
  }

  bool _isIntegrationEnabled(String provider) {
    return _integrations.containsKey(provider) &&
        _integrations[provider]!.isEnabled;
  }

  Future<void> _loadIntegrationConfigs() async {
    // Load saved integration configurations
    // Implementation would load from SharedPreferences or secure storage
  }
  Future<void> _saveIntegrationConfig(String provider) async {
    // Save integration configuration
    // Implementation would save to SharedPreferences or secure storage
  }
  // Provider-specific implementations
  Future<TaskSyncResult> _syncWithJira(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    final syncResult = TaskSyncResult();

    try {
      // Pull from Jira
      final jiraIssues = await _getJiraIssues(config);
      final pulledTasks = _convertJiraIssuesToTasks(jiraIssues);
      syncResult.pulledTasks = pulledTasks;
      // Push to Jira (if bidirectional)
      if (bidirectional && localTasks != null) {
        for (final task in localTasks) {
          if (!_hasExternalRef(task, 'jira')) {
            final jiraIssue = await _createJiraIssue(config, task);
            syncResult.pushedTasks.add(task);
          }
        }
      }
      syncResult.success = true;
      syncResult.message = 'Successfully synced with Jira';
    } catch (e) {
      syncResult.success = false;
      syncResult.message = 'Jira sync failed: $e';
    }
    return syncResult;
  }

  Future<List<Map<String, dynamic>>> _getJiraIssues(
      IntegrationConfig config) async {
    final endpoint = '${config.baseUrl}/rest/api/2/search';
    final auth = base64Encode(
        utf8.encode('${config.config['username']}:${config.apiKey}'));

    final headers = {
      'Authorization': 'Basic $auth',
      'Accept': 'application/json',
    };
    final queryParams = {
      'jql':
          config.config['jql'] ?? 'assignee = currentUser() AND status != Done',
      'fields': 'summary,description,status,priority,assignee,created,updated',
    };
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['issues'] ?? []);
    } else {
      throw ApiException('Failed to fetch Jira issues: ${response.body}');
    }
  }

  List<EnhancedTask> _convertJiraIssuesToTasks(
      List<Map<String, dynamic>> issues) {
    return issues.map((issue) {
      final fields = issue['fields'] as Map<String, dynamic>;

      return EnhancedTask(
        id: 'jira_${issue['key']}',
        title: fields['summary'] ?? '',
        description: fields['description'] ?? '',
        createdAt: DateTime.parse(fields['created']),
        category: _mapJiraTypeToCategory(fields['issuetype']?['name']),
        priority: _mapJiraPriorityToPriority(fields['priority']?['name']),
        metadata: {
          'external_provider': 'jira',
          'external_id': issue['key'],
          'external_url': issue['self'],
        },
      );
    }).toList();
  }

  TaskCategory _mapJiraTypeToCategory(String? type) {
    switch (type?.toLowerCase()) {
      case 'bug':
        return TaskCategory.testing;
      case 'story':
      case 'task':
        return TaskCategory.coding;
      case 'epic':
        return TaskCategory.planning;
      default:
        return TaskCategory.general;
    }
  }

  TaskPriority _mapJiraPriorityToPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'highest':
      case 'blocker':
        return TaskPriority.critical;
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
      case 'lowest':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  Future<Map<String, dynamic>> _createJiraIssue(
    IntegrationConfig config,
    EnhancedTask task,
  ) async {
    final endpoint = '${config.baseUrl}/rest/api/2/issue';
    final auth = base64Encode(
        utf8.encode('${config.config['username']}:${config.apiKey}'));

    final headers = {
      'Authorization': 'Basic $auth',
      'Content-Type': 'application/json',
    };
    final body = {
      'fields': {
        'project': {'key': config.config['project_key']},
        'summary': task.title,
        'description': task.description,
        'issuetype': {'name': config.config['default_issue_type'] ?? 'Task'},
        'priority': {'name': _mapPriorityToJira(task.priority)},
      }
    };
    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Failed to create Jira issue: ${response.body}');
    }
  }

  String _mapPriorityToJira(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return 'Highest';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  bool _hasExternalRef(EnhancedTask task, String provider) {
    return task.metadata['external_provider'] == provider &&
        task.metadata['external_id'] != null;
  }

  // Similar implementations for other providers...
  Future<TaskSyncResult> _syncWithAsana(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    // Asana implementation
    return TaskSyncResult()
      ..success = true
      ..message = 'Asana sync not implemented';
  }

  Future<TaskSyncResult> _syncWithTrello(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    // Trello implementation
    return TaskSyncResult()
      ..success = true
      ..message = 'Trello sync not implemented';
  }

  Future<TaskSyncResult> _syncWithNotion(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    // Notion implementation
    return TaskSyncResult()
      ..success = true
      ..message = 'Notion sync not implemented';
  }

  Future<TaskSyncResult> _syncWithTodoist(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    // Todoist implementation
    return TaskSyncResult()
      ..success = true
      ..message = 'Todoist sync not implemented';
  }

  Future<TaskSyncResult> _syncWithGitHub(
    IntegrationConfig config,
    List<EnhancedTask>? localTasks,
    bool bidirectional,
  ) async {
    // GitHub implementation
    return TaskSyncResult()
      ..success = true
      ..message = 'GitHub sync not implemented';
  }

  // Push implementations
  Future<ExternalTaskRef> _pushToJira(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    final jiraIssue = await _createJiraIssue(config, task);
    return ExternalTaskRef(
      provider: 'jira',
      externalId: jiraIssue['key'],
      url: jiraIssue['self'],
    );
  }

  Future<ExternalTaskRef> _pushToAsana(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    throw UnimplementedError('Asana push not implemented');
  }

  Future<ExternalTaskRef> _pushToTrello(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    throw UnimplementedError('Trello push not implemented');
  }

  Future<ExternalTaskRef> _pushToNotion(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    throw UnimplementedError('Notion push not implemented');
  }

  Future<ExternalTaskRef> _pushToTodoist(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    throw UnimplementedError('Todoist push not implemented');
  }

  Future<ExternalTaskRef> _pushToGitHub(
    IntegrationConfig config,
    EnhancedTask task,
    Map<String, dynamic>? options,
  ) async {
    throw UnimplementedError('GitHub push not implemented');
  }

  // Pull implementations
  Future<List<EnhancedTask>> _pullFromJira(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    final issues = await _getJiraIssues(config);
    return _convertJiraIssuesToTasks(issues);
  }

  Future<List<EnhancedTask>> _pullFromAsana(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    return [];
  }

  Future<List<EnhancedTask>> _pullFromTrello(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    return [];
  }

  Future<List<EnhancedTask>> _pullFromNotion(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    return [];
  }

  Future<List<EnhancedTask>> _pullFromTodoist(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    return [];
  }

  Future<List<EnhancedTask>> _pullFromGitHub(
    IntegrationConfig config,
    Map<String, dynamic>? filters,
  ) async {
    return [];
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

class AnalyticsExport {
  final String id;
  final String format;
  final String downloadUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;
  AnalyticsExport({
    required this.id,
    required this.format,
    required this.downloadUrl,
    required this.createdAt,
    this.expiresAt,
  });
  factory AnalyticsExport.fromJson(Map<String, dynamic> json) {
    return AnalyticsExport(
      id: json['id'],
      format: json['format'],
      downloadUrl: json['download_url'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }
}

class WebhookResponse {
  final String id;
  final String url;
  final List<String> events;
  final bool isActive;
  WebhookResponse({
    required this.id,
    required this.url,
    required this.events,
    required this.isActive,
  });
  factory WebhookResponse.fromJson(Map<String, dynamic> json) {
    return WebhookResponse(
      id: json['id'],
      url: json['url'],
      events: List<String>.from(json['events'] ?? []),
      isActive: json['is_active'] ?? false,
    );
  }
}

class ApiNotification {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  ApiNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });
  factory ApiNotification.fromJson(Map<String, dynamic> json) {
    return ApiNotification(
      id: json['id'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException: $message';
}
