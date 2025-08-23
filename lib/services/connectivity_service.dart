import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Network connectivity monitoring and management service
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isOnline = true;
  bool _isInitialized = false;
  Timer? _connectivityTimer;
  final StreamController<bool> _connectivityController = StreamController.broadcast();

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Current connectivity status
  bool get isOnline => _isOnline;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initial connectivity check
    await _checkConnectivity();
    
    // Start periodic connectivity monitoring
    _startPeriodicChecks();
    
    _isInitialized = true;
    debugPrint('ConnectivityService initialized - Online: $_isOnline');
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isOnline;
  }

  /// Execute operation with connectivity check
  Future<T> executeWithConnectivity<T>(
    Future<T> Function() operation, {
    String? operationName,
    T? fallback,
  }) async {
    if (!_isOnline) {
      final message = 'No internet connection${operationName != null ? ' for $operationName' : ''}';
      
      if (fallback != null) {
        debugPrint('$message - using fallback');
        return fallback;
      } else {
        throw NoConnectivityException(message);
      }
    }

    try {
      return await operation();
    } catch (e) {
      // Re-check connectivity on operation failure
      await _checkConnectivity();
      
      if (!_isOnline && fallback != null) {
        debugPrint('Operation failed due to connectivity - using fallback');
        return fallback;
      }
      
      rethrow;
    }
  }

  /// Wait for connectivity to be restored
  Future<void> waitForConnectivity({Duration timeout = const Duration(seconds: 30)}) async {
    if (_isOnline) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;
    Timer? timeoutTimer;

    subscription = connectivityStream.listen((isOnline) {
      if (isOnline) {
        subscription.cancel();
        timeoutTimer?.cancel();
        completer.complete();
      }
    });

    timeoutTimer = Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Connectivity timeout', timeout));
      }
    });

    // Trigger immediate check
    _checkConnectivity();

    return completer.future;
  }

  /// Private methods

  Future<void> _checkConnectivity() async {
    bool isOnline = false;
    
    try {
      // Try multiple connectivity checks
      final checks = [
        _checkHttpConnectivity(),
        _checkDnsConnectivity(),
      ];
      
      final results = await Future.wait(checks, eagerError: false);
      isOnline = results.any((result) => result == true);
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      isOnline = false;
    }

    if (isOnline != _isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(_isOnline);
      debugPrint('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
    }
  }

  Future<bool> _checkHttpConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkDnsConnectivity() async {
    try {
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _startPeriodicChecks() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
    _isInitialized = false;
  }
}

/// Exception thrown when operation requires connectivity but device is offline
class NoConnectivityException implements Exception {
  final String message;
  NoConnectivityException(this.message);
  
  @override
  String toString() => 'NoConnectivityException: $message';
}

/// Connectivity-aware HTTP client wrapper
class ConnectivityAwareHttpClient {
  final ConnectivityService _connectivity = ConnectivityService();
  final HttpClient _httpClient = HttpClient();

  Future<HttpClientRequest> getUrl(Uri url) async {
    await _connectivity.executeWithConnectivity(
      () async {},
      operationName: 'HTTP GET ${url.host}',
    );
    return _httpClient.getUrl(url);
  }

  Future<HttpClientRequest> postUrl(Uri url) async {
    await _connectivity.executeWithConnectivity(
      () async {},
      operationName: 'HTTP POST ${url.host}',
    );
    return _httpClient.postUrl(url);
  }

  void close({bool force = false}) {
    _httpClient.close(force: force);
  }
}

/// Extension for Future operations with connectivity awareness
extension ConnectivityAware<T> on Future<T> {
  Future<T> requiresConnectivity({
    String? operationName,
    T? fallback,
  }) async {
    return ConnectivityService().executeWithConnectivity(
      () => this,
      operationName: operationName,
      fallback: fallback,
    );
  }
}