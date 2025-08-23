import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Comprehensive error handling and resilience service
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  final List<AppError> _errorHistory = [];
  final StreamController<AppError> _errorStreamController = StreamController.broadcast();
  
  bool _isInitialized = false;
  int _maxErrorHistory = 100;
  
  /// Stream of errors for UI feedback
  Stream<AppError> get errorStream => _errorStreamController.stream;
  
  /// Get recent error history
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  /// Initialize error handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handle platform errors
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _handlePlatformError(error, stackTrace);
      return true;
    };

    _isInitialized = true;
    debugPrint('ErrorHandlerService initialized');
  }

  /// Handle and categorize errors
  Future<void> handleError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
    bool reportToCrashlytics = true,
  }) async {
    final appError = AppError(
      error: error,
      stackTrace: stackTrace,
      context: context,
      severity: severity,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      errorType: _categorizeError(error),
    );

    _addToHistory(appError);
    _errorStreamController.add(appError);

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('Error handled: ${appError.toString()}');
    }

    // Report to Firebase Crashlytics
    if (reportToCrashlytics && !kDebugMode) {
      await _reportToCrashlytics(appError);
    }

    // Handle specific error types
    await _handleSpecificError(appError);
  }

  /// Handle network-related errors with retry logic
  Future<T> handleWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
    String? context,
  }) async {
    int attempts = 0;
    Duration delay = baseDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;
        
        if (!_shouldRetry(error) || attempts >= maxRetries) {
          await handleError(
            error,
            stackTrace,
            context: context,
            metadata: {'attempts': attempts, 'maxRetries': maxRetries},
          );
          rethrow;
        }

        // Exponential backoff
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());

        debugPrint('Retrying operation (attempt $attempts/$maxRetries) after error: $error');
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Handle Firebase operations with specific error handling
  Future<T> handleFirebaseOperation<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      final errorType = _categorizeFirebaseError(error);
      
      await handleError(
        error,
        stackTrace,
        context: context ?? 'Firebase Operation',
        severity: _getFirebaseErrorSeverity(errorType),
        metadata: {'firebaseErrorType': errorType.toString()},
      );

      // Return appropriate fallback or rethrow
      if (_isRecoverableFirebaseError(errorType)) {
        throw RecoverableError(error.toString(), originalError: error);
      } else {
        rethrow;
      }
    }
  }

  /// Handle API calls with network-specific handling
  Future<T> handleApiCall<T>(
    Future<T> Function() apiCall, {
    String? endpoint,
    int maxRetries = 2,
  }) async {
    return handleWithRetry(
      apiCall,
      maxRetries: maxRetries,
      context: 'API Call${endpoint != null ? ' to $endpoint' : ''}',
    );
  }

  /// Handle local storage operations
  Future<T> handleStorageOperation<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallback,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      await handleError(
        error,
        stackTrace,
        context: context ?? 'Storage Operation',
        severity: ErrorSeverity.high,
      );

      if (fallback != null) {
        return fallback;
      } else {
        throw StorageError(error.toString(), originalError: error);
      }
    }
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Get error statistics
  ErrorStatistics getErrorStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    final recent24h = _errorHistory.where((e) => e.timestamp.isAfter(last24Hours)).toList();
    final recent7d = _errorHistory.where((e) => e.timestamp.isAfter(last7Days)).toList();

    final typeGroups = <ErrorType, int>{};
    final severityGroups = <ErrorSeverity, int>{};

    for (final error in _errorHistory) {
      typeGroups[error.errorType] = (typeGroups[error.errorType] ?? 0) + 1;
      severityGroups[error.severity] = (severityGroups[error.severity] ?? 0) + 1;
    }

    return ErrorStatistics(
      totalErrors: _errorHistory.length,
      errorsLast24Hours: recent24h.length,
      errorsLast7Days: recent7d.length,
      errorsByType: typeGroups,
      errorsBySeverity: severityGroups,
      mostCommonErrorType: typeGroups.entries
          .fold<MapEntry<ErrorType, int>?>(null, (prev, entry) {
        return prev == null || entry.value > prev.value ? entry : prev;
      })?.key,
    );
  }

  /// Private methods

  void _handleFlutterError(FlutterErrorDetails details) {
    handleError(
      details.exception,
      details.stack,
      context: 'Flutter Framework',
      severity: ErrorSeverity.high,
      metadata: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  }

  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    handleError(
      error,
      stackTrace,
      context: 'Platform',
      severity: ErrorSeverity.critical,
    );
    return true;
  }

  ErrorType _categorizeError(dynamic error) {
    if (error is SocketException || error is HttpException) {
      return ErrorType.network;
    } else if (error is FormatException || error is TypeError) {
      return ErrorType.parsing;
    } else if (error.toString().contains('firebase') || error.toString().contains('Firebase')) {
      return ErrorType.firebase;
    } else if (error.toString().contains('permission') || error.toString().contains('Permission')) {
      return ErrorType.permission;
    } else if (error is StorageError) {
      return ErrorType.storage;
    } else if (error is AuthenticationError) {
      return ErrorType.authentication;
    } else {
      return ErrorType.unknown;
    }
  }

  FirebaseErrorType _categorizeFirebaseError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('offline')) {
      return FirebaseErrorType.network;
    } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
      return FirebaseErrorType.permission;
    } else if (errorString.contains('quota') || errorString.contains('limit')) {
      return FirebaseErrorType.quota;
    } else if (errorString.contains('auth')) {
      return FirebaseErrorType.authentication;
    } else {
      return FirebaseErrorType.unknown;
    }
  }

  ErrorSeverity _getFirebaseErrorSeverity(FirebaseErrorType errorType) {
    switch (errorType) {
      case FirebaseErrorType.network:
        return ErrorSeverity.medium;
      case FirebaseErrorType.permission:
      case FirebaseErrorType.authentication:
        return ErrorSeverity.high;
      case FirebaseErrorType.quota:
        return ErrorSeverity.critical;
      default:
        return ErrorSeverity.medium;
    }
  }

  bool _isRecoverableFirebaseError(FirebaseErrorType errorType) {
    return errorType == FirebaseErrorType.network || errorType == FirebaseErrorType.quota;
  }

  bool _shouldRetry(dynamic error) {
    if (error is SocketException || error is HttpException) {
      return true;
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('unavailable');
  }

  Future<void> _handleSpecificError(AppError appError) async {
    switch (appError.errorType) {
      case ErrorType.network:
        await _handleNetworkError(appError);
        break;
      case ErrorType.authentication:
        await _handleAuthenticationError(appError);
        break;
      case ErrorType.storage:
        await _handleStorageError(appError);
        break;
      default:
        break;
    }
  }

  Future<void> _handleNetworkError(AppError error) async {
    // Could implement network recovery strategies here
    debugPrint('Handling network error: ${error.error}');
  }

  Future<void> _handleAuthenticationError(AppError error) async {
    // Could implement auth recovery strategies here
    debugPrint('Handling authentication error: ${error.error}');
  }

  Future<void> _handleStorageError(AppError error) async {
    // Could implement storage recovery strategies here
    debugPrint('Handling storage error: ${error.error}');
  }

  void _addToHistory(AppError error) {
    _errorHistory.add(error);
    
    // Keep history size manageable
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeRange(0, _errorHistory.length - _maxErrorHistory);
    }
  }

  Future<void> _reportToCrashlytics(AppError appError) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        appError.error,
        appError.stackTrace,
        reason: appError.context,
        information: [
          'Error Type: ${appError.errorType}',
          'Severity: ${appError.severity}',
          'Timestamp: ${appError.timestamp}',
          ...appError.metadata.entries.map((e) => '${e.key}: ${e.value}'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to report error to Crashlytics: $e');
    }
  }

  void dispose() {
    _errorStreamController.close();
  }
}

/// Custom error types
class RecoverableError extends Error {
  final String message;
  final dynamic originalError;

  RecoverableError(this.message, {this.originalError});

  @override
  String toString() => 'RecoverableError: $message';
}

class StorageError extends Error {
  final String message;
  final dynamic originalError;

  StorageError(this.message, {this.originalError});

  @override
  String toString() => 'StorageError: $message';
}

class AuthenticationError extends Error {
  final String message;
  final dynamic originalError;

  AuthenticationError(this.message, {this.originalError});

  @override
  String toString() => 'AuthenticationError: $message';
}

/// Error data classes
class AppError {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final ErrorType errorType;

  AppError({
    required this.error,
    this.stackTrace,
    this.context,
    required this.severity,
    required this.timestamp,
    required this.metadata,
    required this.errorType,
  });

  @override
  String toString() {
    return 'AppError(type: $errorType, severity: $severity, context: $context, error: $error)';
  }
}

class ErrorStatistics {
  final int totalErrors;
  final int errorsLast24Hours;
  final int errorsLast7Days;
  final Map<ErrorType, int> errorsByType;
  final Map<ErrorSeverity, int> errorsBySeverity;
  final ErrorType? mostCommonErrorType;

  ErrorStatistics({
    required this.totalErrors,
    required this.errorsLast24Hours,
    required this.errorsLast7Days,
    required this.errorsByType,
    required this.errorsBySeverity,
    this.mostCommonErrorType,
  });
}

/// Enums
enum ErrorType {
  network,
  firebase,
  storage,
  authentication,
  permission,
  parsing,
  validation,
  unknown,
}

enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

enum FirebaseErrorType {
  network,
  permission,
  authentication,
  quota,
  unknown,
}

/// Extension methods for better error handling
extension SafeAsync<T> on Future<T> {
  Future<T?> handleError({
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      await ErrorHandlerService().handleError(
        error,
        stackTrace,
        context: context,
        severity: severity,
      );
      return null;
    }
  }
}

extension SafeAsyncWithFallback<T> on Future<T> {
  Future<T> handleErrorWithFallback(
    T fallback, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      await ErrorHandlerService().handleError(
        error,
        stackTrace,
        context: context,
        severity: severity,
      );
      return fallback;
    }
  }
}