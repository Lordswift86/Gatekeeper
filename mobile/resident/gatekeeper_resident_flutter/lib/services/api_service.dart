import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'offline_cache.dart';

/// Enhanced API service with offline support
class ApiService {
  static const String _tokenKey = 'auth_token';
  static bool _isOfflineMode = false;
  
  /// Check if currently in offline mode
  static bool get isOfflineMode => _isOfflineMode;
  
  /// Enable/disable offline mode
  static void setOfflineMode(bool enabled) {
    _isOfflineMode = enabled;
    debugPrint('Offline mode: ${enabled ? 'ENABLED' : 'DISABLED'}');
  }
  
  // Token management
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  // Get headers with auth token
  static Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // HTTP GET with offline support
  static Future<dynamic> get(String endpoint, {
    bool requiresAuth = true,
    String? cacheKey,
    Duration? cacheExpiry,
  }) async {
    // If offline mode, return cached data only
    if (_isOfflineMode && cacheKey != null) {
      final cached = await OfflineCache.get(cacheKey);
      if (cached != null) return cached;
      throw Exception('No offline data available');
    }
    
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await getHeaders(includeAuth: requiresAuth);
      
      final response = await http.get(url, headers: headers)
          .timeout(ApiConfig.timeoutDuration);
      
      final result = _handleResponse(response);
      
      // Cache successful responses
      if (cacheKey != null && result != null) {
        await OfflineCache.save(cacheKey, result, expiry: cacheExpiry);
      }
      
      return result;
    } catch (e) {
      // Fallback to cache on network error
      if (cacheKey != null) {
        final cached = await OfflineCache.get(cacheKey);
        if (cached != null) {
          debugPrint('Using cached data for $endpoint');
          return cached;
        }
      }
      throw _handleError(e);
    }
  }
  
  // HTTP POST
  static Future<dynamic> post(String endpoint, dynamic body, {bool requiresAuth = true}) async {
    if (_isOfflineMode) {
      throw Exception('Cannot perform this action while offline');
    }
    
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await getHeaders(includeAuth: requiresAuth);
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(ApiConfig.timeoutDuration);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // HTTP PUT
  static Future<dynamic> put(String endpoint, dynamic body, {bool requiresAuth = true}) async {
    if (_isOfflineMode) {
      throw Exception('Cannot perform this action while offline');
    }
    
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await getHeaders(includeAuth: requiresAuth);
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(ApiConfig.timeoutDuration);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // HTTP DELETE
  static Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    if (_isOfflineMode) {
      throw Exception('Cannot perform this action while offline');
    }
    
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await getHeaders(includeAuth: requiresAuth);
      
      final response = await http.delete(
        url,
        headers: headers,
      ).timeout(ApiConfig.timeoutDuration);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Handle response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      clearToken(); // Clear invalid token
      throw Exception('Unauthorized. Please login again.');
    } else {
      final errorBody = response.body.isNotEmpty 
          ? jsonDecode(response.body) 
          : {'message': 'Unknown error'};
      throw Exception(errorBody['message'] ?? 'Request failed');
    }
  }
  
  // Handle errors
  static String _handleError(dynamic error) {
    if (error is Exception) {
      final msg = error.toString().replaceAll('Exception: ', '');
      // Check for network errors
      if (msg.contains('SocketException') || msg.contains('TimeoutException')) {
        return 'No internet connection';
      }
      return msg;
    }
    return 'An unexpected error occurred';
  }
}
