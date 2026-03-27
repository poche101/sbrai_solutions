import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class VendorApiService {
  static const String baseUrl = "https://sbraisolutions.com/api";
  static const String _vendorTokenKey = 'vendor_auth_token';

  static final VendorApiService _instance = VendorApiService._internal();
  factory VendorApiService() => _instance;
  VendorApiService._internal();

  /// --- VENDOR TOKEN MANAGEMENT ---
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vendorTokenKey, token);
    debugPrint("🔐 Vendor token saved");
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vendorTokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vendorTokenKey);
    debugPrint("🔐 Vendor token cleared");
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
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$baseUrl$cleanEndpoint');
  }

  /// --- CORE METHODS ---
  Future<http.Response> get(String endpoint, {bool isProtected = true}) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 VENDOR API GET: $url");

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

      debugPrint("🚀 VENDOR API POST: $url");
      debugPrint("📦 PAYLOAD: ${jsonEncode(data)}");

      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _processError(e, "POST", endpoint);
    }
  }

  /// --- MULTIPART FILE UPLOAD (for identity verification documents) ---
  Future<http.Response> upload(
      String endpoint,
      Map<String, String> data, {
        required String filePath,
        required String fileField,
        bool isProtected = true,
      }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      // Remove content-type for multipart request
      headers.remove('Content-Type');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      // Add text fields
      data.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add file
      final file = await http.MultipartFile.fromPath(fileField, filePath);
      request.files.add(file);

      debugPrint("🚀 VENDOR API UPLOAD: $url");
      debugPrint("📦 FIELDS: $data");
      debugPrint("📄 FILE: $filePath");

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _processError(e, "UPLOAD", endpoint);
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

      debugPrint("🚀 VENDOR API PUT: $url");
      debugPrint("📦 PAYLOAD: ${jsonEncode(data)}");

      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _processError(e, "PUT", endpoint);
    }
  }

  Future<http.Response> delete(String endpoint, {bool isProtected = true}) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 VENDOR API DELETE: $url");

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return _processError(e, "DELETE", endpoint);
    }
  }

  /// --- VENDOR LOGOUT ---
  Future<void> logout() async {
    try {
      await post('/v1/vendor/logout', {}, isProtected: true);
    } catch (e) {
      debugPrint("Vendor logout API failed: $e");
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
    debugPrint("❌ VENDOR $method ERROR [$endpoint]: $e");

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