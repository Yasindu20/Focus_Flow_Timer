import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';

/// Authentication provider for managing user authentication state
/// Integrates with FirebaseService for enterprise authentication features
class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  
  AuthProvider(this._firebaseService) {
    // Listen to Firebase service changes
    _firebaseService.addListener(_onFirebaseServiceChanged);
  }

  // State
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user ?? _firebaseService.currentUser;
  bool get isAuthenticated => user != null;
  String? get userId => user?.uid;

  /// Sign up with email and password
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _performAuthAction(() async {
      await _firebaseService.signUpWithEmailPassword(
        email,
        password,
        displayName: displayName,
      );
      return true;
    });
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _performAuthAction(() async {
      await _firebaseService.signInWithEmailPassword(email, password);
      return true;
    });
  }

  /// Sign out current user
  Future<bool> signOut() async {
    return _performAuthAction(() async {
      await _firebaseService.signOut();
      return true;
    });
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    return _performAuthAction(() async {
      await _firebaseService.sendPasswordResetEmail(email);
      return true;
    });
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Private helper method to handle authentication actions
  Future<bool> _performAuthAction(Future<bool> Function() action) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await action();
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(_getReadableErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
  }

  /// Convert Firebase error codes to readable messages
  String _getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided for that user.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'operation-not-allowed':
          return 'Operation not allowed. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }

  /// Handle Firebase service state changes
  void _onFirebaseServiceChanged() {
    _user = _firebaseService.currentUser;
    notifyListeners();
  }

  @override
  void dispose() {
    _firebaseService.removeListener(_onFirebaseServiceChanged);
    super.dispose();
  }
}