import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Updated to include /v1 to resolve the fetch failure
  static const String baseUrl = "https://sbraisolutions.com/api/v1";

  // Token keys for different user types
  static const String _buyerTokenKey = 'buyer_auth_token';
  static const String _vendorTokenKey = 'vendor_auth_token';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// --- TOKEN MANAGEMENT (Generic) ---
  Future<void> saveToken(String token, {required String userType}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userType == 'vendor' ? _vendorTokenKey : _buyerTokenKey;
    await prefs.setString(key, token);
    debugPrint("🔐 $userType token saved");
  }

  Future<String?> getToken({required String userType}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userType == 'vendor' ? _vendorTokenKey : _buyerTokenKey;
    return prefs.getString(key);
  }

  Future<void> clearToken({required String userType}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userType == 'vendor' ? _vendorTokenKey : _buyerTokenKey;
    await prefs.remove(key);
    debugPrint("🔐 $userType token cleared");
  }

  /// --- PRIVATE HELPERS ---
  Future<Map<String, String>> _getHeaders({
    bool protected = false,
    required String userType,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (protected) {
      String? token = await getToken(userType: userType);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _buildUrl(String endpoint) {
    // Ensures we don't end up with .../api/v1//endpoint
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return Uri.parse('$baseUrl/$cleanEndpoint');
  }

  /// --- CORE METHODS ---
  Future<http.Response> get(
    String endpoint, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );

      debugPrint("🚀 API GET [$userType]: $url");

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response, userType: userType);
    } catch (e) {
      return _processError(e, "GET", endpoint);
    }
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = false,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );

      debugPrint("🚀 API POST [$userType]: $url");
      debugPrint("📦 PAYLOAD: ${jsonEncode(data)}");

      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response, userType: userType);
    } catch (e) {
      return _processError(e, "POST", endpoint);
    }
  }

  Future<http.Response> upload(
    String endpoint,
    Map<String, String> data, {
    required String filePath,
    required String fileField,
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );

      headers.remove('Content-Type');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      data.forEach((key, value) {
        request.fields[key] = value;
      });

      final file = await http.MultipartFile.fromPath(fileField, filePath);
      request.files.add(file);

      debugPrint("🚀 API UPLOAD [$userType]: $url");

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, userType: userType);
    } catch (e) {
      return _processError(e, "UPLOAD", endpoint);
    }
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );

      debugPrint("🚀 API PUT [$userType]: $url");

      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response, userType: userType);
    } catch (e) {
      return _processError(e, "PUT", endpoint);
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );

      debugPrint("🚀 API DELETE [$userType]: $url");

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response, userType: userType);
    } catch (e) {
      return _processError(e, "DELETE", endpoint);
    }
  }

  /// --- RESPONSE & ERROR HANDLING ---
  http.Response _handleResponse(
    http.Response response, {
    required String userType,
  }) {
    final int statusCode = response.statusCode;
    debugPrint("📥 STATUS: $statusCode");

    if (statusCode == 401) {
      clearToken(userType: userType);
      throw "Session expired. Please sign in again.";
    }

    if (statusCode >= 200 && statusCode < 300) {
      return response;
    } else {
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
