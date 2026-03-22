import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Base URL updated to point to the root API
  static const String baseUrl = "https://sbraisolutions.com/api";
  static const String _tokenKey = 'auth_token';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// --- TOKEN MANAGEMENT ---

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    debugPrint("🔐 Local auth token cleared.");
  }

  /// --- PRIVATE HELPERS ---

  Future<Map<String, String>> _getHeaders({bool protected = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (protected) {
      String? token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _buildUrl(String endpoint) {
    // Correctly handles slashes to prevent double-slash issues (e.g. api//v1)
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$baseUrl$cleanEndpoint');
  }

  /// --- CORE METHODS ---

  Future<http.Response> get(String endpoint, {bool isProtected = true}) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 API GET: $url");

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _processError(e, "GET", endpoint);
    }
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = false,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 API POST: $url");
      debugPrint("📦 PAYLOAD: ${jsonEncode(data)}");

      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _processError(e, "POST", endpoint);
    }
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = true,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 API PUT: $url");
      debugPrint("📦 PAYLOAD: ${jsonEncode(data)}");

      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _processError(e, "PUT", endpoint);
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    bool isProtected = true,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 API DELETE: $url");

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _processError(e, "DELETE", endpoint);
    }
  }

  /// --- LOGOUT ---

  Future<void> logout() async {
    try {
      await post('/v1/buyers/logout', {}, isProtected: true);
    } catch (e) {
      debugPrint("Logout API failed: $e");
    } finally {
      await clearToken();
    }
  }

  /// --- RESPONSE & ERROR HANDLING ---

  http.Response _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;
    debugPrint("📥 STATUS: $statusCode");

    if (statusCode == 401) {
      clearToken();
      throw "Session expired. Please sign in again.";
    }

    // If status is 200-299, return the response
    if (statusCode >= 200 && statusCode < 300) {
      return response;
    } else {
      // Parse Laravel error messages if available
      try {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? "Server error ($statusCode)";
        throw message;
      } catch (e) {
        throw "Server error: $statusCode";
      }
    }
  }

  http.Response _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");

    if (e is SocketException) {
      throw "No internet connection. Please check your network.";
    } else if (e is TimeoutException) {
      throw "Connection timed out. Please try again.";
    } else if (e is HandshakeException) {
      throw "Security certificate error. Contact support.";
    } else {
      throw e.toString();
    }
  }
}
