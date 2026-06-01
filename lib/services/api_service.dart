// lib/buyer_service/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = "https://sbraisolutions.com/api/v1";

  // ── Token keys — one per user type ──────────────────────────────────────
  static const String _vendorTokenKey = 'vendor_auth_token';
  static const String _buyerTokenKey = 'buyer_auth_token'; // ← NEW
  static const String _userKey = 'vendor_user_data';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ---------------------------------------------------------------------------
  // TOKEN MANAGEMENT
  // ---------------------------------------------------------------------------

  /// Saves a token under the correct key for [userType].
  /// Pass userType: 'buyer' from the buyer login flow,
  /// or userType: 'vendor' (default) from the vendor login flow.
  Future<void> saveToken(String token, {String userType = 'vendor'}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userType == 'buyer' ? _buyerTokenKey : _vendorTokenKey;
    await prefs.setString(key, token);
    debugPrint("🔐 Token saved for $userType");
  }

  /// Returns whichever token is available.
  /// Vendor token takes priority; falls back to buyer token.
  /// Pass [userType] to read a specific token directly.
  Future<String?> getToken({String? userType}) async {
    final prefs = await SharedPreferences.getInstance();

    if (userType == 'buyer') {
      return prefs.getString(_buyerTokenKey);
    }
    if (userType == 'vendor') {
      return prefs.getString(_vendorTokenKey);
    }

    // No userType specified — return whichever is present
    final vendorToken = prefs.getString(_vendorTokenKey);
    if (vendorToken != null && vendorToken.isNotEmpty) return vendorToken;

    final buyerToken = prefs.getString(_buyerTokenKey);
    if (buyerToken != null && buyerToken.isNotEmpty) return buyerToken;

    return null;
  }

  /// Clears the token for a specific user type, or both if unspecified.
  Future<void> clearToken({String? userType}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userType == 'vendor' || userType == null) {
      await prefs.remove(_vendorTokenKey);
    }
    if (userType == 'buyer' || userType == null) {
      await prefs.remove(_buyerTokenKey);
    }
    if (userType == null) {
      await prefs.remove(_userKey);
    }
    debugPrint("🔐 Token cleared for ${userType ?? 'all'}");
  }

  // ---------------------------------------------------------------------------
  // USER DATA CACHE
  // ---------------------------------------------------------------------------

  Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(data));
    debugPrint("💾 User data cached");
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _getHeaders({
    bool protected = true,
    String? userType,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (protected) {
      final token = await getToken(userType: userType);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint(
          "⚠️ Protected route called without token (userType: $userType)",
        );
      }
    }
    return headers;
  }

  // ---------------------------------------------------------------------------
  // URL BUILDER
  // ---------------------------------------------------------------------------

  Uri _buildUrl(String endpoint) {
    final clean = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$clean');
  }

  // ---------------------------------------------------------------------------
  // HTTP METHODS
  // ---------------------------------------------------------------------------

  Future<http.Response> get(
    String endpoint, {
    bool isProtected = true,
    String userType = 'vendor',
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 GET: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
    } catch (e) {
      throw _processError(e, "GET", endpoint);
    }
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = true,
    String userType = 'vendor',
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 POST: $url");
      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
    } catch (e) {
      throw _processError(e, "POST", endpoint);
    }
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = true,
    String userType = 'vendor',
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 PUT: $url");
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
    } catch (e) {
      throw _processError(e, "PUT", endpoint);
    }
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = true,
    String userType = 'vendor',
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 PATCH: $url");
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
    } catch (e) {
      throw _processError(e, "PATCH", endpoint);
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    bool isProtected = true,
    String userType = 'vendor',
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 DELETE: $url");
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
    } catch (e) {
      throw _processError(e, "DELETE", endpoint);
    }
  }

  Future<http.Response> upload(
    String endpoint,
    Map<String, String> fields, {
    required String filePath,
    required String fileField,
    bool isProtected = true,
    String userType = 'vendor',
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final token = await getToken(userType: userType);

      final request = http.MultipartRequest('POST', url);
      request.headers['Accept'] = 'application/json';
      if (isProtected && token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      fields.forEach((key, value) => request.fields[key] = value);
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

      debugPrint("🚀 UPLOAD: $url");
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response, userType: userType);
    } catch (e) {
      throw _processError(e, "UPLOAD", endpoint);
    }
  }

  // ---------------------------------------------------------------------------
  // RESPONSE HANDLER
  // ---------------------------------------------------------------------------

  http.Response _handleResponse(http.Response response, {String? userType}) {
    debugPrint("📥 ${response.statusCode} ${response.request?.url}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException("Server error (${response.statusCode})");
    }

    if (response.statusCode == 401) {
      // Only clear the token for the relevant user type
      clearToken(userType: userType);
      throw ApiException("Session expired. Please login again.");
    }

    if (response.statusCode == 422 &&
        decoded is Map &&
        decoded['errors'] != null) {
      final errors = decoded['errors'] as Map<String, dynamic>;
      final messages = errors.values
          .expand((e) => e is List ? e : [e])
          .join(', ');
      throw ApiException(messages);
    }

    final message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : "Request failed (${response.statusCode})";

    throw ApiException(message);
  }

  // ---------------------------------------------------------------------------
  // ERROR PROCESSOR
  // ---------------------------------------------------------------------------

  String _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");
    if (e is SocketException) return "No internet connection.";
    if (e is TimeoutException) return "Connection timed out.";
    if (e is HandshakeException) return "SSL error.";
    return e.toString().replaceFirst('Exception: ', '').trim();
  }
}

// ---------------------------------------------------------------------------
// EXCEPTION
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// CONNECTIVITY TEST (dev only)
// ---------------------------------------------------------------------------

Future<void> testApiConnection() async {
  try {
    final response = await http
        .get(
          Uri.parse("https://sbraisolutions.com/api/v1/categories"),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));
    print("✅ API Test - Status: ${response.statusCode}");
    print("Body: ${response.body.substring(0, 200)}...");
  } catch (e) {
    print("❌ API Test Failed: $e");
  }
}
