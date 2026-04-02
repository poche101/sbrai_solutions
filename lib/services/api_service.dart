import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Base URL - The versioning root
  static const String baseUrl = "https://sbraisolutions.com/api/v1";

  // Unique keys for different user types
  static const String _buyerTokenKey = 'buyer_auth_token';
  static const String _vendorTokenKey = 'vendor_auth_token';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// ---------------- TOKEN MANAGEMENT ----------------

  String _getCorrectKey(String? userType) {
    return userType == 'buyer' ? _buyerTokenKey : _vendorTokenKey;
  }

  Future<void> saveToken(String token, {String userType = 'vendor'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getCorrectKey(userType), token);
      debugPrint("🔐 $userType token saved");
    } catch (e) {
      debugPrint("❌ Local Storage Error (Save): $e");
    }
  }

  Future<String?> getToken({String userType = 'vendor'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_getCorrectKey(userType));
    } catch (e) {
      debugPrint("❌ Local Storage Error (Get): $e");
      return null;
    }
  }

  Future<void> clearToken({String userType = 'vendor'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getCorrectKey(userType));
      debugPrint("🔐 $userType token cleared");
    } catch (e) {
      debugPrint("❌ Local Storage Error (Clear): $e");
    }
  }

  /// ---------------- HEADERS & URL ----------------

  Future<Map<String, String>> _getHeaders({
    bool protected = false,
    String userType = 'vendor',
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (protected) {
      final token = await getToken(userType: userType);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// ✅ FIX: Prevents doubling of "v1" if already provided in endpoint
  Uri _buildUrl(String endpoint) {
    String cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;

    // If endpoint already starts with v1, strip it to avoid v1/v1/
    if (cleanEndpoint.startsWith('v1/')) {
      cleanEndpoint = cleanEndpoint.replaceFirst('v1/', '');
    }

    return Uri.parse('$baseUrl/$cleanEndpoint');
  }

  /// ---------------- HTTP METHODS ----------------

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
      return _processError(e, "GET", endpoint);
    }
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = false,
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
      return _processError(e, "POST", endpoint);
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
      return _processError(e, "PUT", endpoint);
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
      return _processError(e, "DELETE", endpoint);
    }
  }

  /// ---------------- UPLOAD (Multipart) ----------------

  Future<http.Response> upload(
    String endpoint,
    Map<String, String> data, {
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

      data.forEach((key, value) => request.fields[key] = value);

      if (filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, filePath),
        );
      }

      debugPrint("🚀 UPLOAD: $url");
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      return _handleResponse(response, userType: userType);
    } catch (e) {
      return _processError(e, "UPLOAD", endpoint);
    }
  }

  /// ---------------- RESPONSE HANDLING ----------------

  http.Response _handleResponse(
    http.Response response, {
    required String userType,
  }) {
    final statusCode = response.statusCode;
    debugPrint("📥 STATUS: $statusCode");

    if (statusCode >= 200 && statusCode < 300) {
      return response;
    }

    if (statusCode == 401) {
      clearToken(userType: userType);
      throw "Session expired. Please login again.";
    }

    // Comprehensive Error Parsing
    try {
      final decoded = jsonDecode(response.body);

      // Handle Laravel Validation Errors (422)
      if (statusCode == 422 && decoded['errors'] != null) {
        final Map<String, dynamic> errors = decoded['errors'];
        final firstKey = errors.keys.first;
        final firstError = errors[firstKey];

        if (firstError is List && firstError.isNotEmpty) {
          throw firstError.first.toString();
        } else {
          throw firstError.toString();
        }
      }

      // Handle General API Messages
      throw decoded['message'] ?? "Request failed with status: $statusCode";
    } catch (e) {
      if (e is String) rethrow;
      throw "Server error: $statusCode";
    }
  }

  /// ✅ Catch-all error processor
  http.Response _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");

    if (e is SocketException) {
      throw "No internet connection. Please check your network.";
    } else if (e is TimeoutException) {
      throw "Connection timed out. The server is taking too long to respond.";
    } else if (e is HandshakeException) {
      throw "Secure connection failed (SSL error).";
    } else if (e is FormatException) {
      throw "Bad response format from server.";
    } else {
      // Strips the "Exception: " prefix for cleaner UI messages
      throw e.toString().replaceAll("Exception: ", "");
    }
  }
}
