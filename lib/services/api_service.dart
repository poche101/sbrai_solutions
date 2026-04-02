import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // FIX: Remove /v1 from here if you plan to include it in your Service paths,
  // OR keep it here and remove it from your Service paths.
  // Recommendation: Keep the base as the root API and let services define versions.
  static const String baseUrl = "https://sbraisolutions.com/api";

  static const String _buyerTokenKey = 'buyer_auth_token';
  static const String _vendorTokenKey = 'vendor_auth_token';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// --- TOKEN MANAGEMENT ---
  Future<void> saveToken(String token, {required String userType}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userType == 'vendor' ? _vendorTokenKey : _buyerTokenKey;
    await prefs.setString(key, token);
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

  // FIX: Robust URL builder that prevents double slashes and versioning conflicts
  Uri _buildUrl(String endpoint) {
    // Remove leading slash if present
    String cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;

    // Final URL assembly
    final finalUrl = '$baseUrl/$cleanEndpoint';
    return Uri.parse(finalUrl);
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
      data.forEach((key, value) => request.fields[key] = value);
      final file = await http.MultipartFile.fromPath(fileField, filePath);
      request.files.add(file);
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      return _handleResponse(
        await http.Response.fromStream(streamedResponse),
        userType: userType,
      );
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
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
    } catch (e) {
      return _processError(e, "DELETE", endpoint);
    }
  }

  http.Response _handleResponse(
    http.Response response, {
    required String userType,
  }) {
    final int statusCode = response.statusCode;
    debugPrint("📥 STATUS: $statusCode");

    if (statusCode == 401) {
      clearToken(userType: userType);
      throw "Session expired or unauthorized.";
    }

    if (statusCode >= 200 && statusCode < 300) {
      return response;
    } else if (statusCode == 422) {
      final decoded = jsonDecode(response.body);
      if (decoded['errors'] != null) {
        // Extracting Laravel validation messages
        var firstError = (decoded['errors'] as Map).values.first;
        throw (firstError is List) ? firstError.first : firstError.toString();
      }
      throw decoded['message'] ?? "Validation failed";
    } else {
      throw "Server error: $statusCode";
    }
  }

  http.Response _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");
    if (e is SocketException) throw "No internet connection.";
    if (e is TimeoutException) throw "Connection timed out.";
    throw e.toString().replaceAll("Exception: ", "");
  }
}
