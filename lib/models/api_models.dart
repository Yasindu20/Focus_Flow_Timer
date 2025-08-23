// API Integration Models
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
  List<dynamic> pulledTasks = [];
  List<dynamic> pushedTasks = [];
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
