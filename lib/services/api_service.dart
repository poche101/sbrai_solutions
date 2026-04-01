import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = "https://sbraisolutions.com/api/v1";

  /// ✅ Vendor token only
  static const String _tokenKey = 'vendor_auth_token';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// ---------------- TOKEN ----------------

  Future<void> saveToken(String token) async {
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

  /// ---------------- HEADERS ----------------

  Future<Map<String, String>> _getHeaders({bool protected = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (protected) {
      final token = await getToken();

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint("⚠️ No token found for protected route");
      }
    }

    return headers;
  }

  /// ---------------- URL ----------------

  Uri _buildUrl(String endpoint) {
    final cleanEndpoint =
    endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$cleanEndpoint');
  }

  /// ---------------- GET ----------------

  Future<http.Response> get(String endpoint,
      {bool isProtected = true}) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 GET: $url");

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      _processError(e, "GET", endpoint);
      rethrow;
    }
  }

  /// ---------------- POST ----------------

  Future<http.Response> post(
      String endpoint,
      Map<String, dynamic> data, {
        bool isProtected = false,
      }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 POST: $url");
      debugPrint("📦 ${jsonEncode(data)}");

      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      _processError(e, "POST", endpoint);
      rethrow;
    }
  }

  /// ---------------- PUT ----------------

  Future<http.Response> put(
      String endpoint,
      Map<String, dynamic> data, {
        bool isProtected = true,
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
      _processError(e, "PUT", endpoint);
      rethrow;
    }
  }

  /// ---------------- DELETE ----------------

  Future<http.Response> delete(String endpoint,
      {bool isProtected = true}) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      debugPrint("🚀 DELETE: $url");

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      _processError(e, "DELETE", endpoint);
      rethrow;
    }
  }

  /// ---------------- UPLOAD ----------------

  Future<http.Response> upload(
      String endpoint,
      Map<String, String> data, {
        required String filePath,
        required String fileField,
        bool isProtected = true,
      }) async {
    try {
      final url = _buildUrl(endpoint);
      final token = await getToken();

      final request = http.MultipartRequest('POST', url);

      request.headers['Accept'] = 'application/json';

      if (isProtected && token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      data.forEach((key, value) {
        request.fields[key] = value;
      });

      request.files.add(
        await http.MultipartFile.fromPath(fileField, filePath),
      );

      debugPrint("🚀 UPLOAD: $url");

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      return _handleResponse(response);
    } catch (e) {
      _processError(e, "UPLOAD", endpoint);
      rethrow;
    }
  }

  /// ---------------- RESPONSE ----------------

  http.Response _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    debugPrint("📥 STATUS: $statusCode");

    if (statusCode == 401) {
      clearToken();
      throw "Session expired. Please login again.";
    }

    if (statusCode >= 200 && statusCode < 300) {
      return response;
    }

    try {
      final decoded = jsonDecode(response.body);
      throw decoded['message'] ?? "Server error ($statusCode)";
    } catch (_) {
      throw "Server error: $statusCode";
    }
  }

  /// ---------------- ERROR ----------------

  void _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");

    if (e is SocketException) {
      throw "No internet connection.";
    } else if (e is TimeoutException) {
      throw "Request timeout.";
    } else if (e is HandshakeException) {
      throw "SSL error.";
    } else {
      throw e.toString();
    }
  }
}