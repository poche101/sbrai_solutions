import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart';

class ApiService {
  static const String baseUrl = "https://sbraisolutions.com/api/v1";
  static const String _tokenKey = 'auth_token';

  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _photoKey = 'user_photo';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// --- USER DATA MANAGEMENT ---

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, userData['name'] ?? '');
    await prefs.setString(_emailKey, userData['email'] ?? '');
    if (userData['profile_photo_url'] != null) {
      await prefs.setString(_photoKey, userData['profile_photo_url']);
    }
    debugPrint("👤 User profile data cached.");
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
      'photo': prefs.getString(_photoKey),
    };
  }

  Future<void> saveToken(String token, {required String userType}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    debugPrint("🔐 Auth token saved for $userType.");
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_photoKey);
    debugPrint("🔐 Local auth and user data cleared.");
  }

  /// --- SOCIAL AUTHENTICATION ---

  Future<http.Response?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? token = googleAuth.accessToken;

      if (token == null) throw "Failed to retrieve Google Access Token.";

      return await socialLogin('google', token);
    } catch (e) {
      debugPrint("❌ Google Sign-In Flow Error: $e");
      rethrow;
    }
  }

  Future<http.Response> socialLogin(String provider, String accessToken) async {
    try {
      final response = await post(
        'buyers/social-signup',
        {'provider': provider, 'access_token': accessToken},
        isProtected: false,
        userType: 'buyer',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        await saveToken(
          responseData['data']['access_token'],
          userType: 'buyer',
        );

        if (responseData['data']['user'] != null) {
          await saveUserData(responseData['data']['user']);
        }
      }

      return response;
    } catch (e) {
      debugPrint("❌ Social Login API Error: $e");
      rethrow;
    }
  }

  /// --- CORE METHODS ---

  Future<http.Response> get(
    String endpoint, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 API GET: $url");

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
    bool isProtected = false,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 API POST ($userType): $url");

      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      throw _processError(e, "POST", endpoint);
    }
  }

  /// --- UPDATED PUT METHOD ---
  /// Use this specifically for the profile update route
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 API PUT ($userType): $url");

      // We send a real PUT request here
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      throw _processError(e, "PUT", endpoint);
    }
  }

  Future<http.Response> postMultipart(
    String endpoint,
    File file,
    String fieldName, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final String? token = await getToken();

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({'Accept': 'application/json'});

      if (isProtected && token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: basename(file.path),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _processError(e, "MULTIPART", endpoint);
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 API DELETE ($userType): $url");

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
    Map<String, String> data, {
    required String filePath,
    required String fileField,
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);

      // Multipart requests handle their own content-type
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
      return _handleResponse(response);
    } catch (e) {
      throw _processError(e, "UPLOAD", endpoint);
    }
  }

  /// --- PRIVATE HELPERS ---

  Future<Map<String, String>> _getHeaders({bool protected = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (protected) {
      String? token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUrl(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return Uri.parse('$baseUrl/$cleanEndpoint');
  }

  Future<void> logout() async {
    try {
      await post(
        'buyers/logout',
        {},
        isProtected: true,
        userType: 'buyer',
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("⚠️ Logout API failed: $e");
    } finally {
      await _googleSignIn.signOut();
      await clearToken();
    }
  }

  http.Response _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;

    // Log response for debugging
    debugPrint("📥 RESPONSE [${response.statusCode}]: ${response.body}");

    if (statusCode >= 200 && statusCode < 300) {
      return response;
    }

    final dynamic decoded = jsonDecode(response.body);

    // Handle Session Expiry
    if (statusCode == 401 &&
        decoded is Map &&
        decoded['message'] != 'Incorrect email or password.') {
      clearToken();
      throw "Session expired. Please sign in again.";
    }

    // Handle Validation Errors (422)
    if (statusCode == 422 && decoded is Map && decoded['errors'] != null) {
      Map<String, dynamic> errors = decoded['errors'];
      String errorMessage = "";
      errors.forEach((key, value) {
        if (value is List) {
          errorMessage += "${value.join(", ")}\n";
        } else {
          errorMessage += "$value\n";
        }
      });
      throw errorMessage.trim();
    }

    if (decoded is Map && decoded.containsKey('message')) {
      throw decoded['message'];
    }

    throw "Server error ($statusCode)";
  }

  String _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");
    if (e is SocketException) return "No internet connection.";
    if (e is TimeoutException) return "Connection timed out.";
    return e.toString().replaceFirst('Exception: ', '');
  }
}
