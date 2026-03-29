import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart';

class ApiService {
  static const String baseUrl = "https://sbraisolutions.com/api";
  static const String _tokenKey = 'auth_token';

  // Storage Keys
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _photoKey = 'user_photo';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// --- USER DATA MANAGEMENT ---

  /// Saves user profile details to local storage
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, userData['name'] ?? '');
    await prefs.setString(_emailKey, userData['email'] ?? '');
    if (userData['profile_photo_url'] != null) {
      await prefs.setString(_photoKey, userData['profile_photo_url']);
    }
    debugPrint("👤 User profile data cached.");
  }

  /// Retrieves cached user data for the UI
  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
      'photo': prefs.getString(_photoKey),
    };
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    debugPrint("🔐 Auth token saved successfully.");
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
      final response = await post('/v1/buyers/social-signup', {
        'provider': provider,
        'access_token': accessToken,
      }, isProtected: false);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // Save the token
        await saveToken(responseData['data']['access_token']);

        // Save user data so the Menu can see it
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
      throw _processError(e, "GET", endpoint);
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
      throw _processError(e, "POST", endpoint);
    }
  }

  /// --- UPLOAD METHODS (MULTIPART) ---

  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      final response = await postMultipart(
        '/v1/buyers/profile/upload-photo',
        imageFile,
        'photo',
        isProtected: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        // If the server returns the new photo URL, update our local cache
        if (responseData['data'] != null &&
            responseData['data']['profile_photo_url'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            _photoKey,
            responseData['data']['profile_photo_url'],
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Profile Image Upload Error: $e");
      return false;
    }
  }

  Future<http.Response> postMultipart(
    String endpoint,
    File file,
    String fieldName, {
    bool isProtected = true,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final String? token = await getToken();

      debugPrint("🚀 API MULTIPART POST: $url");

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

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = true,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw _processError(e, "PUT", endpoint);
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    bool isProtected = true,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw _processError(e, "DELETE", endpoint);
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
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$baseUrl$cleanEndpoint');
  }

  Future<void> logout() async {
    try {
      await post(
        '/v1/buyers/logout',
        {},
        isProtected: true,
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
    if (statusCode == 401) {
      clearToken();
      throw "Session expired. Please sign in again.";
    }
    if (statusCode >= 200 && statusCode < 300) {
      return response;
    } else {
      final decoded = jsonDecode(response.body);
      throw decoded['message'] ?? "Server error ($statusCode)";
    }
  }

  String _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");
    if (e is SocketException) return "No internet connection.";
    if (e is TimeoutException) return "Connection timed out.";
    return e.toString().replaceFirst('Exception: ', '');
  }
}
