import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  AuthProvider() {
    _initialize();
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get userDisplayName => _user?.displayName;

  // Initialize the auth provider
  void _initialize() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      _errorMessage = null;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      await _firebaseService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register with email and password
  Future<bool> registerWithEmail(
    String email, 
    String password, {
    String? displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _firebaseService.registerWithEmail(
        email, 
        password,
        displayName: displayName,
        userData: additionalData,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firebaseService.signOut();
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Failed to send reset email: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await _user!.updateDisplayName(displayName);
      if (photoURL != null) {
        await _user!.updatePhotoURL(photoURL);
      }
      
      // Reload user to get updated info
      await _user!.reload();
      _user = FirebaseAuth.instance.currentUser;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await _user!.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Failed to update password: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await _user!.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Failed to delete account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<bool> reauthenticateWithEmail(String email, String password) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final credential = EmailAuthProvider.credential(email: email, password: password);
      await _user!.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Re-authentication failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify email
  Future<bool> sendEmailVerification() async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await _user!.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Failed to send verification email: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // Reload current user
  Future<void> reloadUser() async {
    if (_user != null) {
      await _user!.reload();
      _user = FirebaseAuth.instance.currentUser;
      notifyListeners();
    }
  }

  // Get user claims (roles, permissions, etc.)
  Future<Map<String, dynamic>> getUserClaims() async {
    if (_user == null) return {};

    try {
      final idTokenResult = await _user!.getIdTokenResult();
      return idTokenResult.claims ?? {};
    } catch (e) {
      debugPrint('Error getting user claims: $e');
      return {};
    }
  }

  // Check if user has specific role
  Future<bool> hasRole(String role) async {
    final claims = await getUserClaims();
    return claims['role'] == role;
  }

  // Check if user has premium access
  Future<bool> hasPremiumAccess() async {
    final claims = await getUserClaims();
    return ['premium', 'enterprise', 'admin'].contains(claims['role']);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _setError('No user found with this email address.');
        break;
      case 'wrong-password':
        _setError('Invalid password.');
        break;
      case 'email-already-in-use':
        _setError('An account with this email already exists.');
        break;
      case 'weak-password':
        _setError('Password is too weak. Please choose a stronger password.');
        break;
      case 'invalid-email':
        _setError('Please enter a valid email address.');
        break;
      case 'user-disabled':
        _setError('This account has been disabled.');
        break;
      case 'too-many-requests':
        _setError('Too many failed attempts. Please try again later.');
        break;
      case 'operation-not-allowed':
        _setError('This sign-in method is not allowed.');
        break;
      case 'requires-recent-login':
        _setError('This operation requires recent authentication. Please sign in again.');
        break;
      case 'credential-already-in-use':
        _setError('This credential is already associated with another account.');
        break;
      case 'invalid-credential':
        _setError('The credential is malformed or has expired.');
        break;
      case 'account-exists-with-different-credential':
        _setError('An account already exists with the same email but different sign-in credentials.');
        break;
      case 'network-request-failed':
        _setError('Network error. Please check your connection and try again.');
        break;
      default:
        _setError(e.message ?? 'An authentication error occurred.');
        break;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}