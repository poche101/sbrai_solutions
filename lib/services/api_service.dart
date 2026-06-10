// lib/buyer_service/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class ApiService {
  static const String baseUrl = "https://sbraisolutions.com/api/v1";

  // ── Token keys — one per user type ──────────────────────────────────────
  static const String _vendorTokenKey = 'vendor_auth_token';
  static const String _buyerTokenKey = 'buyer_auth_token';
  static const String _userKey = 'vendor_user_data';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '247352594282-ngifekbhv3s8q078tm6cofc29l2slvmo.apps.googleusercontent.com',
  );

  // ---------------------------------------------------------------------------
  // TOKEN MANAGEMENT
  // ---------------------------------------------------------------------------

  Future<void> saveToken(String token, {String userType = 'vendor'}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userType == 'buyer' ? _buyerTokenKey : _vendorTokenKey;
    await prefs.setString(key, token);
    debugPrint("🔐 Token saved for $userType");
  }

  Future<String?> getToken({String? userType}) async {
    final prefs = await SharedPreferences.getInstance();

    if (userType == 'buyer') return prefs.getString(_buyerTokenKey);
    if (userType == 'vendor') return prefs.getString(_vendorTokenKey);

    final vendorToken = prefs.getString(_vendorTokenKey);
    if (vendorToken != null && vendorToken.isNotEmpty) return vendorToken;

    final buyerToken = prefs.getString(_buyerTokenKey);
    if (buyerToken != null && buyerToken.isNotEmpty) return buyerToken;

    return null;
  }

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
  // AUTH ENDPOINTS
  // ---------------------------------------------------------------------------

  Future<http.Response> saveFcmToken(String fcmToken) async => await post(
    'auth/fcm-token',
    {'fcm_token': fcmToken},
    isProtected: true,
    userType: 'vendor',
  );

  Future<http.Response> forgotPassword(String email) async => await post(
    'auth/forgot-password',
    {'email': email},
    isProtected: false,
    userType: 'vendor',
  );

  Future<http.Response> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async => await post(
    'auth/reset-password',
    {
      'token': token,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    },
    isProtected: false,
    userType: 'vendor',
  );

  // ---------------------------------------------------------------------------
  // SOCIAL AUTH
  // ---------------------------------------------------------------------------

  /// Signs in with Google and posts the id_token to the backend.
  Future<http.Response?> signInWithGoogle({String userType = 'vendor'}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        throw "Google idToken is null. Make sure serverClientId is set in GoogleSignIn().";
      }

      return await socialLogin('google', idToken, userType: userType);
    } catch (e) {
      debugPrint("❌ Google Sign-In error: $e");
      rethrow;
    }
  }

  /// Signs in with Facebook and posts the access_token to the backend.
  Future<http.Response?> signInWithFacebook({
    String userType = 'vendor',
  }) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) return null;

      if (result.status != LoginStatus.success) {
        throw "Facebook login failed: ${result.message}";
      }

      final String? accessToken = result.accessToken?.tokenString;
      if (accessToken == null) throw "Facebook access token is null.";

      return await socialLogin('facebook', accessToken, userType: userType);
    } catch (e) {
      debugPrint("❌ Facebook Sign-In error: $e");
      rethrow;
    }
  }

  /// Posts the provider token to the backend and saves the returned Sanctum token.
  /// Google  → backend expects key 'id_token'
  /// Facebook → backend expects key 'access_token'
  Future<http.Response> socialLogin(
    String provider,
    String token, {
    String userType = 'vendor',
  }) async {
    try {
      final String tokenKey = provider == 'google'
          ? 'id_token'
          : 'access_token';

      final response = await post(
        'auth/social/$provider',
        {tokenKey: token, 'user_type': userType},
        isProtected: false,
        userType: userType,
      );

      final responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['status'] == true) {
        final savedToken = responseData['data']?['token']?.toString();
        if (savedToken != null) {
          await saveToken(savedToken, userType: userType);
          debugPrint("🔐 Social login token saved for $userType.");
        }
        if (responseData['data']?['user'] != null) {
          await saveUserData(responseData['data']['user']);
        }
      }
      return response;
    } catch (e) {
      debugPrint("❌ Social login error: $e");
      rethrow;
    }
  }

  Future<void> logout({String? userType}) async {
    try {
      await post(
        'auth/logout',
        {},
        isProtected: true,
        userType: userType ?? 'vendor',
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("⚠️ Logout API call failed (ignored): $e");
    } finally {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      await clearToken(userType: userType);
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
