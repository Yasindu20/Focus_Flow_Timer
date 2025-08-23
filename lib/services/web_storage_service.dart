import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class WebStorageService {
  static bool _isSupported = true;
  static const String _prefix = 'focus_flow_';
  
  static bool get isSupported => _isSupported;
  
  static Future<void> initialize() async {
    if (!kIsWeb) return;
    
    try {
      // Test if localStorage is available
      html.window.localStorage['test'] = 'test';
      html.window.localStorage.remove('test');
      _isSupported = true;
    } catch (e) {
      debugPrint('Web storage not available: $e');
      _isSupported = false;
    }
  }
  
  static String? getString(String key) {
    if (!_isSupported || !kIsWeb) return null;
    
    try {
      return html.window.localStorage[_prefix + key];
    } catch (e) {
      debugPrint('Error reading from localStorage: $e');
      return null;
    }
  }
  
  static Future<bool> setString(String key, String value) async {
    if (!_isSupported || !kIsWeb) return false;
    
    try {
      html.window.localStorage[_prefix + key] = value;
      return true;
    } catch (e) {
      debugPrint('Error writing to localStorage: $e');
      return false;
    }
  }
  
  static bool? getBool(String key) {
    final value = getString(key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }
  
  static Future<bool> setBool(String key, bool value) async {
    return setString(key, value.toString());
  }
  
  static double? getDouble(String key) {
    final value = getString(key);
    if (value == null) return null;
    return double.tryParse(value);
  }
  
  static Future<bool> setDouble(String key, double value) async {
    return setString(key, value.toString());
  }
  
  static int? getInt(String key) {
    final value = getString(key);
    if (value == null) return null;
    return int.tryParse(value);
  }
  
  static Future<bool> setInt(String key, int value) async {
    return setString(key, value.toString());
  }
  
  static List<String>? getStringList(String key) {
    final value = getString(key);
    if (value == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(value);
      return decoded.cast<String>();
    } catch (e) {
      debugPrint('Error decoding string list: $e');
      return null;
    }
  }
  
  static Future<bool> setStringList(String key, List<String> value) async {
    try {
      final encoded = json.encode(value);
      return setString(key, encoded);
    } catch (e) {
      debugPrint('Error encoding string list: $e');
      return false;
    }
  }
  
  static Map<String, dynamic>? getMap(String key) {
    final value = getString(key);
    if (value == null) return null;
    
    try {
      return json.decode(value) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding map: $e');
      return null;
    }
  }
  
  static Future<bool> setMap(String key, Map<String, dynamic> value) async {
    try {
      final encoded = json.encode(value);
      return setString(key, encoded);
    } catch (e) {
      debugPrint('Error encoding map: $e');
      return false;
    }
  }
  
  static Future<bool> remove(String key) async {
    if (!_isSupported || !kIsWeb) return false;
    
    try {
      html.window.localStorage.remove(_prefix + key);
      return true;
    } catch (e) {
      debugPrint('Error removing from localStorage: $e');
      return false;
    }
  }
  
  static Future<bool> clear() async {
    if (!_isSupported || !kIsWeb) return false;
    
    try {
      final keys = html.window.localStorage.keys
          .where((key) => key.startsWith(_prefix))
          .toList();
      
      for (final key in keys) {
        html.window.localStorage.remove(key);
      }
      return true;
    } catch (e) {
      debugPrint('Error clearing localStorage: $e');
      return false;
    }
  }
  
  static List<String> getAllKeys() {
    if (!_isSupported || !kIsWeb) return [];
    
    try {
      return html.window.localStorage.keys
          .where((key) => key.startsWith(_prefix))
          .map((key) => key.substring(_prefix.length))
          .toList();
    } catch (e) {
      debugPrint('Error getting all keys: $e');
      return [];
    }
  }
}