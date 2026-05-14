import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = "https://sbraisolutions.com/api/v1";

  static const String _tokenKey = 'vendor_auth_token';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ---------------------------------------------------------------------------
  // TOKEN MANAGEMENT
  // ---------------------------------------------------------------------------

  Future<void> saveToken(String token, {String userType = 'vendor'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    debugPrint("🔐 Vendor token saved");
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    debugPrint("🔐 Vendor token cleared");
  }

  // ---------------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _getHeaders({bool protected = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (protected) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint("⚠️ Protected route called without token");
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
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 GET: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
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
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 POST: $url");
      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
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
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 PUT: $url");
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
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
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 PATCH: $url");
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
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
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 DELETE: $url");
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
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
      final token = await getToken();

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
      return _handleResponse(response);
    } catch (e) {
      throw _processError(e, "UPLOAD", endpoint);
    }
  }

  // ---------------------------------------------------------------------------
  // RESPONSE HANDLER
  // ---------------------------------------------------------------------------

  http.Response _handleResponse(http.Response response) {
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
      clearToken();
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

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
