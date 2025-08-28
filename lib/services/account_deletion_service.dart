import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AccountDeletionService {
  static const List<String> firestoreCollections = [
    'users',
    'sessions',
    'tasks',
    'achievements', 
    'analytics',
    'goals',
    'productivity_scores',
    'leaderboard',
    'daily_stats',
    'task_analytics',
    'timer_sessions',
    'pomodoro_sessions'
  ];

  static const List<String> sharedPreferencesKeys = [
    'timer_work_duration',
    'timer_break_duration',
    'timer_long_break_duration',
    'timer_sound_enabled',
    'timer_selected_sound',
    'app_theme_mode',
    'notification_enabled',
    'daily_goal_sessions',
    'weekly_goal_hours',
    'user_preferences',
    'last_sync_timestamp',
    'offline_data',
    'app_intro_completed',
    'analytics_enabled'
  ];

  Future<bool> deleteUserAccount(String userId) async {
    try {
      await _deleteFirestoreData(userId);
      await _deleteLocalData();
      await _deleteFirebaseAuthUser();
      
      return true;
    } catch (e) {
      debugPrint('Account deletion failed: $e');
      rethrow;
    }
  }

  Future<void> _deleteFirestoreData(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (final collection in firestoreCollections) {
      try {
        final querySnapshot = await firestore
            .collection(collection)
            .where('userId', isEqualTo: userId)
            .get();

        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        final userDocRef = firestore.collection(collection).doc(userId);
        final userDocSnapshot = await userDocRef.get();
        if (userDocSnapshot.exists) {
          batch.delete(userDocRef);
        }
      } catch (e) {
        debugPrint('Error deleting from collection $collection: $e');
      }
    }

    await batch.commit();
  }

  Future<void> _deleteLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final key in sharedPreferencesKeys) {
      try {
        await prefs.remove(key);
      } catch (e) {
        debugPrint('Error removing key $key from SharedPreferences: $e');
      }
    }

    try {
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
    }
  }

  Future<void> _deleteFirebaseAuthUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  Future<bool> reauthenticateUser(String email, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Re-authentication failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Re-authentication error: $e');
      return false;
    }
  }

  Future<List<String>> getDataToBeDeleted(String userId) async {
    final List<String> dataInfo = [];
    final firestore = FirebaseFirestore.instance;

    for (final collection in firestoreCollections) {
      try {
        final querySnapshot = await firestore
            .collection(collection)
            .where('userId', isEqualTo: userId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          dataInfo.add('$collection: ${querySnapshot.docs.length} documents');
        }

        final userDocRef = firestore.collection(collection).doc(userId);
        final userDocSnapshot = await userDocRef.get();
        if (userDocSnapshot.exists) {
          dataInfo.add('$collection user profile document');
        }
      } catch (e) {
        debugPrint('Error checking collection $collection: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final localDataCount = sharedPreferencesKeys
        .where((key) => prefs.containsKey(key))
        .length;
    
    if (localDataCount > 0) {
      dataInfo.add('Local preferences: $localDataCount items');
    }

    dataInfo.add('Firebase Auth account');
    
    return dataInfo;
  }
}