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
  static const String _phoneKey = 'user_phone';
  static const String _addressKey = 'user_address';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // ---------------------------------------------------------------------------
  // USER DATA MANAGEMENT
  // ---------------------------------------------------------------------------

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _nameKey,
      userData['full_name'] ?? userData['name'] ?? '',
    );
    await prefs.setString(_emailKey, userData['email'] ?? '');
    await prefs.setString(_phoneKey, userData['phone']?.toString() ?? '');
    await prefs.setString(_addressKey, userData['address'] ?? '');

    final String? photoUrl = userData['photo'] ?? userData['profile_photo'];
    if (photoUrl != null) await prefs.setString(_photoKey, photoUrl);

    debugPrint("👤 User profile data cached.");
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
      'photo': prefs.getString(_photoKey),
      'phone': prefs.getString(_phoneKey),
      'address': prefs.getString(_addressKey),
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
    await prefs.remove(_phoneKey);
    await prefs.remove(_addressKey);
    debugPrint("🔐 Local auth and user data cleared.");
  }

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<http.Response> registerBuyer(Map<String, dynamic> data) async {
    return await post(
      'auth/register/buyer',
      data,
      isProtected: false,
      userType: 'buyer',
    );
  }

  Future<http.Response> registerVendor(Map<String, dynamic> data) async {
    return await post(
      'auth/register/vendor',
      data,
      isProtected: false,
      userType: 'vendor',
    );
  }

  Future<http.Response> loginBuyer(Map<String, dynamic> data) async {
    return await post(
      'auth/login/buyer',
      data,
      isProtected: false,
      userType: 'buyer',
    );
  }

  Future<http.Response> loginVendor(Map<String, dynamic> data) async {
    return await post(
      'auth/login/vendor',
      data,
      isProtected: false,
      userType: 'vendor',
    );
  }

  Future<void> logout() async {
    try {
      await post(
        'auth/logout',
        {},
        isProtected: true,
        userType: 'buyer',
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("⚠️ Logout API call failed (ignored): $e");
    } finally {
      await _googleSignIn.signOut();
      await clearToken();
    }
  }

  Future<http.Response> getMe() async {
    return await get('auth/me', isProtected: true, userType: 'buyer');
  }

  Future<http.Response> saveFcmToken(String fcmToken) async {
    return await post(
      'auth/fcm-token',
      {'fcm_token': fcmToken},
      isProtected: true,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // SOCIAL AUTH
  // ---------------------------------------------------------------------------

  Future<http.Response?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? token = googleAuth.accessToken;
      if (token == null) throw "Failed to retrieve Google access token.";

      return await socialLogin('google', token);
    } catch (e) {
      debugPrint("❌ Google Sign-In error: $e");
      rethrow;
    }
  }

  Future<http.Response> socialLogin(String provider, String accessToken) async {
    try {
      final response = await post(
        'auth/social/$provider',
        {'access_token': accessToken},
        isProtected: false,
        userType: 'buyer',
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
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
      debugPrint("❌ Social login error: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // BUYER PROFILE
  // ---------------------------------------------------------------------------

  Future<http.Response> getBuyerProfile() async {
    return await get('buyers/profile', isProtected: true, userType: 'buyer');
  }

  Future<http.Response> updateBuyerProfile(Map<String, dynamic> data) async {
    return await put(
      'buyers/profile/update',
      data,
      isProtected: true,
      userType: 'buyer',
    );
  }

  /// Laravel route: POST api/v1/buyers/profile/upload-photo
  Future<http.Response> uploadBuyerPhoto(File imageFile) async {
    return await postMultipart(
      'buyers/profile/upload-photo',
      {},
      filePath: imageFile.path,
      fileField: 'profile_photo',
      isProtected: true,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // FAVORITES
  // ---------------------------------------------------------------------------

  Future<http.Response> getFavorites() async {
    return await get('buyers/favorites', isProtected: true, userType: 'buyer');
  }

  Future<http.Response> removeFavorite(int adId) async {
    return await delete(
      'buyers/favorites/$adId',
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> toggleFavorite(int adId) async {
    return await post(
      'ads/$adId/favorite',
      {},
      isProtected: true,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // ADS (public)
  // ---------------------------------------------------------------------------

  Future<http.Response> getAds({Map<String, String>? queryParams}) async {
    final endpoint = queryParams == null || queryParams.isEmpty
        ? 'ads'
        : 'ads?${Uri(queryParameters: queryParams).query}';
    return await get(endpoint, isProtected: false, userType: 'buyer');
  }

  Future<http.Response> getAd(int id) async {
    return await get('ads/$id', isProtected: false, userType: 'buyer');
  }

  Future<http.Response> recordAdView(int adId) async {
    return await post(
      'ads/$adId/view',
      {},
      isProtected: false,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

  Future<http.Response> getCategories() async {
    return await get('categories', isProtected: false, userType: 'buyer');
  }

  Future<http.Response> getCategoriesByType(String type) async {
    return await get('categories/$type', isProtected: false, userType: 'buyer');
  }

  // ---------------------------------------------------------------------------
  // KYC
  // ---------------------------------------------------------------------------

  Future<http.Response> getKycStatus() async {
    return await get('kyc/status', isProtected: true, userType: 'buyer');
  }

  Future<http.Response> sendEmailOtp() async {
    return await post(
      'kyc/email/send',
      {},
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> verifyEmail(String code) async {
    return await post(
      'kyc/email/verify',
      {'code': code},
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> sendPhoneOtp() async {
    return await post(
      'kyc/phone/send',
      {},
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> verifyPhone(String otp) async {
    return await post(
      'kyc/phone/verify',
      {'code': otp},
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> verifyIdentity({
    required String nin,
    File? document,
  }) async {
    if (document != null) {
      return await postMultipart(
        'kyc/identity/verify',
        {'nin': nin},
        filePath: document.path,
        fileField: 'document',
        isProtected: true,
        userType: 'buyer',
      );
    }
    return await post(
      'kyc/identity/verify',
      {'nin': nin},
      isProtected: true,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // CHATS
  // ---------------------------------------------------------------------------

  Future<http.Response> getChats() async {
    return await get('chats', isProtected: true, userType: 'buyer');
  }

  Future<http.Response> startChat(Map<String, dynamic> data) async {
    return await post('chats', data, isProtected: true, userType: 'buyer');
  }

  Future<http.Response> getChatMessages(int chatId) async {
    return await get(
      'chats/$chatId/messages',
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> sendChatMessage(
    int chatId,
    Map<String, dynamic> data,
  ) async {
    return await post(
      'chats/$chatId/messages',
      data,
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> markChatRead(int chatId) async {
    return await post(
      'chats/$chatId/read',
      {},
      isProtected: true,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // CALLS
  // ---------------------------------------------------------------------------

  Future<http.Response> getCallToken({
    required String channelName,
    required int uid,
  }) async {
    return await post(
      'calls/token',
      {'channel_name': channelName, 'uid': uid},
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> initiateCall({
    required int receiverId,
    required String channelName,
    required String callerName,
    required String callType,
  }) async {
    return await post(
      'calls/initiate',
      {
        'receiver_id': receiverId,
        'channel_name': channelName,
        'caller_name': callerName,
        'call_type': callType,
      },
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> endCall({
    required int receiverId,
    required String channelName,
  }) async {
    return await post(
      'calls/end',
      {'receiver_id': receiverId, 'channel_name': channelName},
      isProtected: true,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // VENDOR
  // ---------------------------------------------------------------------------

  Future<http.Response> getVendorDashboard() async {
    return await get('vendor/dashboard', isProtected: true, userType: 'vendor');
  }

  Future<http.Response> getVendorAnalytics() async {
    return await get('vendor/analytics', isProtected: true, userType: 'vendor');
  }

  Future<http.Response> getVendorProfile() async {
    return await get('vendor/profile', isProtected: true, userType: 'vendor');
  }

  Future<http.Response> updateVendorProfile(Map<String, dynamic> data) async {
    return await patch(
      'vendor/profile',
      data,
      isProtected: true,
      userType: 'vendor',
    );
  }

  /// Laravel route: POST api/v1/vendor/profile/photo
  Future<http.Response> uploadVendorPhoto(File imageFile) async {
    return await postMultipart(
      'vendor/profile/photo',
      {},
      filePath: imageFile.path,
      fileField: 'photo',
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> uploadVendorLogo(File imageFile) async {
    return await postMultipart(
      'vendor/profile/logo',
      {},
      filePath: imageFile.path,
      fileField: 'logo',
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> getVoucher() async {
    return await get('vendor/voucher', isProtected: true, userType: 'vendor');
  }

  Future<http.Response> voucherTopUp(Map<String, dynamic> data) async {
    return await post(
      'vendor/voucher/topup',
      data,
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> voucherSpend(Map<String, dynamic> data) async {
    return await post(
      'vendor/voucher/spend',
      data,
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> getVoucherTransactions() async {
    return await get(
      'vendor/voucher/transactions',
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> getVendorSettings() async {
    return await get('vendor/settings', isProtected: true, userType: 'vendor');
  }

  Future<http.Response> updateVendorSettings(Map<String, dynamic> data) async {
    return await patch(
      'vendor/settings',
      data,
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> getVendorSettingsOptions() async {
    return await get(
      'vendor/settings/options',
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> changeVendorPassword(Map<String, dynamic> data) async {
    return await post(
      'vendor/settings/change-password',
      data,
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> deleteVendorAccount() async {
    return await delete(
      'vendor/settings/account',
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> getMyAds() async {
    return await get('vendor/ads/my', isProtected: true, userType: 'vendor');
  }

  Future<http.Response> createAd(Map<String, dynamic> data) async {
    return await post(
      'vendor/ads',
      data,
      isProtected: true,
      userType: 'vendor',
    );
  }

  /// Laravel route: POST api/v1/vendor/ads/{id}
  Future<http.Response> updateAd(
    int id,
    Map<String, String> fields, {
    File? media,
  }) async {
    if (media != null) {
      return await postMultipart(
        'vendor/ads/$id',
        fields,
        filePath: media.path,
        fileField: 'media',
        isProtected: true,
        userType: 'vendor',
      );
    }
    return await post(
      'vendor/ads/$id',
      fields,
      isProtected: true,
      userType: 'vendor',
    );
  }

  Future<http.Response> deleteAd(int id) async {
    return await delete(
      'vendor/ads/$id',
      isProtected: true,
      userType: 'vendor',
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSLATIONS
  // ---------------------------------------------------------------------------

  Future<http.Response> getLocales() async {
    return await get(
      'translations/locales',
      isProtected: false,
      userType: 'buyer',
    );
  }

  Future<http.Response> getTranslations(String locale) async {
    return await get(
      'translations/$locale',
      isProtected: false,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // CORE HTTP METHODS
  // ---------------------------------------------------------------------------

  Future<http.Response> get(
    String endpoint, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 GET [$userType]: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
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
      debugPrint("🚀 POST: $url");
      debugPrint("🔑 Token being sent: ${headers['Authorization']}");
      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _processError(e, "POST", endpoint);
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
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 PUT [$userType]: $url");
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _processError(e, "PUT", endpoint);
    }
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool isProtected = true,
    required String userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(protected: isProtected);
      debugPrint("🚀 PATCH [$userType]: $url");
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _processError(e, "PATCH", endpoint);
    }
  }

  Future<http.Response> postMultipart(
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

      // Remove Content-Type so MultipartRequest can set its own boundary
      headers.remove('Content-Type');
      headers['Accept'] = 'application/json';

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      data.forEach((key, value) => request.fields[key] = value);

      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          filePath,
          filename: basename(filePath),
        ),
      );

      debugPrint("🚀 UPLOAD ATTEMPT: POST $url");

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _processError(e, "UPLOAD", endpoint);
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
      debugPrint("🚀 DELETE [$userType]: $url");
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _processError(e, "DELETE", endpoint);
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _getHeaders({bool protected = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (protected) {
      final token = await getToken();
      debugPrint(
        "🔑 Auth token from storage: ${token ?? 'NULL — not logged in'}",
      );
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _buildUrl(String endpoint) {
    final clean = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$clean');
  }

  /// Handles HTTP responses.
  ///
  /// Throws [ApiException] with a clean user-facing message on errors.
  /// Using a typed exception prevents _processError from re-wrapping it.
  http.Response _handleResponse(http.Response response) {
    debugPrint("📥 STATUS ${response.statusCode}: ${response.body}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    // Safely decode — 500s may return HTML, not JSON
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      // Non-JSON response (HTML error page, nginx 502, etc.)
      debugPrint("⚠️ Non-JSON error response (${response.statusCode})");
      throw ApiException(
        "Server error (${response.statusCode}). Please try again.",
      );
    }

    // 401 Unauthenticated — clear token and prompt re-login
    // Exception: wrong password returns 401 but should NOT clear the token
    if (response.statusCode == 401 &&
        decoded is Map &&
        decoded['message'] != 'Incorrect email or password.') {
      clearToken();
      throw ApiException("Session expired. Please sign in again.");
    }

    // 422 Validation errors — extract and join field messages
    if (response.statusCode == 422 &&
        decoded is Map &&
        decoded['errors'] != null) {
      final errors = decoded['errors'] as Map<String, dynamic>;
      final buffer = StringBuffer();
      errors.forEach((_, value) {
        buffer.writeln(value is List ? value.join(', ') : value.toString());
      });
      throw ApiException(buffer.toString().trim());
    }

    // Any other error with a message field
    if (decoded is Map && decoded.containsKey('message')) {
      throw ApiException(
        decoded['message']?.toString() ?? "An error occurred.",
      );
    }

    throw ApiException(
      "Server error (${response.statusCode}). Please try again.",
    );
  }

  /// Converts low-level exceptions (network, timeout) into clean strings.
  /// Does NOT re-wrap [ApiException] — those pass through as-is via rethrow
  /// in each HTTP method above.
  String _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");
    if (e is SocketException) return "No internet connection.";
    if (e is TimeoutException) return "Connection timed out.";
    // Unwrap any stray Exception wrappers
    final msg = e.toString().replaceFirst('Exception: ', '');
    return msg.isNotEmpty ? msg : "An unexpected error occurred.";
  }
}

/// Typed exception used internally by [ApiService._handleResponse].
/// Prevents _processError from re-wrapping server error messages.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
