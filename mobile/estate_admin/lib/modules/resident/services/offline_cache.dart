import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline cache manager for storing API data locally
class OfflineCache {
  static const String _prefix = 'offline_cache_';
  static const Duration _defaultExpiry = Duration(hours: 24);
  
  /// Save data to cache with optional expiry
  static Future<void> save(String key, dynamic data, {Duration? expiry}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiryMs': (expiry ?? _defaultExpiry).inMilliseconds,
    };
    await prefs.setString('$_prefix$key', jsonEncode(cacheData));
  }
  
  /// Get cached data if valid (not expired)
  static Future<T?> get<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_prefix$key');
    
    if (cached == null) return null;
    
    try {
      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final expiryMs = cacheData['expiryMs'] as int;
      
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > expiryMs) {
        // Cache expired
        await prefs.remove('$_prefix$key');
        return null;
      }
      
      return cacheData['data'] as T?;
    } catch (e) {
      return null;
    }
  }
  
  /// Check if cache exists and is valid
  static Future<bool> has(String key) async {
    return await get(key) != null;
  }
  
  /// Remove specific cache entry
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }
  
  /// Clear all cached data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
  
  /// Get cache age in seconds
  static Future<int?> getAge(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_prefix$key');
    
    if (cached == null) return null;
    
    try {
      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      return (DateTime.now().millisecondsSinceEpoch - timestamp) ~/ 1000;
    } catch (e) {
      return null;
    }
  }
}

/// Cache keys for different data types
class CacheKeys {
  static const String userProfile = 'user_profile';
  static const String userPasses = 'user_passes';
  static const String userBills = 'user_bills';
  static const String announcements = 'announcements';
}
