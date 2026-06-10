import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:path/path.dart';

class ApiService {
  static const String baseUrl = "https://sbraisolutions.com/api/v1";

  static const String _buyerTokenKey = 'auth_token';
  static const String _vendorTokenKey = 'vendor_auth_token';
  static const String _idKey = 'user_id';
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _photoKey = 'user_photo';
  static const String _phoneKey = 'user_phone';
  static const String _addressKey = 'user_address';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '247352594282-ngifekbhv3s8q078tm6cofc29l2slvmo.apps.googleusercontent.com',
  );

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
    final id = userData['id']?.toString() ?? '';
    if (id.isNotEmpty) await prefs.setString(_idKey, id);
    final String? photoUrl = userData['photo'] ?? userData['profile_photo'];
    if (photoUrl != null) await prefs.setString(_photoKey, photoUrl);
    debugPrint("👤 User data cached (id: $id).");
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_idKey),
      'name': prefs.getString(_nameKey),
      'email': prefs.getString(_emailKey),
      'photo': prefs.getString(_photoKey),
      'phone': prefs.getString(_phoneKey),
      'address': prefs.getString(_addressKey),
    };
  }

  Future<void> saveToken(String token, {required String userType}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userType == 'vendor' ? _vendorTokenKey : _buyerTokenKey;
    await prefs.setString(key, token);
    debugPrint("🔐 Token saved for $userType.");
  }

  Future<String?> getToken({String? userType}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userType == 'vendor') return prefs.getString(_vendorTokenKey);
    if (userType == 'buyer') return prefs.getString(_buyerTokenKey);
    final vendor = prefs.getString(_vendorTokenKey);
    if (vendor != null && vendor.isNotEmpty) return vendor;
    final buyer = prefs.getString(_buyerTokenKey);
    if (buyer != null && buyer.isNotEmpty) return buyer;
    return null;
  }

  Future<void> clearToken({String? userType}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userType == 'vendor') {
      await prefs.remove(_vendorTokenKey);
      debugPrint("🔐 Vendor token cleared.");
      return;
    }
    if (userType == 'buyer') {
      await prefs.remove(_buyerTokenKey);
      debugPrint("🔐 Buyer token cleared.");
      return;
    }
    await prefs.remove(_vendorTokenKey);
    await prefs.remove(_buyerTokenKey);
    await prefs.remove(_idKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_photoKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_addressKey);
    debugPrint("🔐 All auth data cleared.");
  }

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<http.Response> registerBuyer(Map<String, dynamic> data) async =>
      await post(
        'auth/register/buyer',
        data,
        isProtected: false,
        userType: 'buyer',
      );

  Future<http.Response> registerVendor(Map<String, dynamic> data) async =>
      await post(
        'auth/register/vendor',
        data,
        isProtected: false,
        userType: 'vendor',
      );

  Future<http.Response> loginBuyer(Map<String, dynamic> data) async =>
      await post(
        'auth/login/buyer',
        data,
        isProtected: false,
        userType: 'buyer',
      );

  Future<http.Response> loginVendor(Map<String, dynamic> data) async =>
      await post(
        'auth/login/vendor',
        data,
        isProtected: false,
        userType: 'vendor',
      );

  Future<void> logout({String? userType}) async {
    try {
      await post(
        'auth/logout',
        {},
        isProtected: true,
        userType: userType ?? 'buyer',
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("⚠️ Logout API call failed (ignored): $e");
    } finally {
      await _googleSignIn.signOut();
      // Sign out of Facebook too if logged in
      await FacebookAuth.instance.logOut();
      await clearToken(userType: userType);
    }
  }

  Future<http.Response> getMe() async =>
      await get('auth/me', isProtected: true, userType: 'buyer');

  Future<http.Response> saveFcmToken(String fcmToken) async => await post(
    'auth/fcm-token',
    {'fcm_token': fcmToken},
    isProtected: true,
    userType: 'buyer',
  );

  Future<http.Response> forgotPassword(String email) async => await post(
    'auth/forgot-password',
    {'email': email},
    isProtected: false,
    userType: 'buyer',
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
    userType: 'buyer',
  );

  // ---------------------------------------------------------------------------
  // SOCIAL AUTH
  // ---------------------------------------------------------------------------

  /// Signs in with Google and posts the id_token to the backend.
  Future<http.Response?> signInWithGoogle({String userType = 'buyer'}) async {
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
  Future<http.Response?> signInWithFacebook({String userType = 'buyer'}) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) return null; // user cancelled

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
    String userType = 'buyer',
  }) async {
    try {
      // ── KEY FIX: each provider uses a different body key ──────────────────
      final String tokenKey = provider == 'google'
          ? 'id_token'
          : 'access_token';

      final response = await post(
        'auth/social/$provider',
        {
          tokenKey: token, // 'id_token' for google, 'access_token' for facebook
          'user_type': userType,
        },
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

  // ---------------------------------------------------------------------------
  // BUYER PROFILE
  // ---------------------------------------------------------------------------

  Future<http.Response> getBuyerProfile() async =>
      await get('buyers/profile', isProtected: true, userType: 'buyer');

  Future<http.Response> updateBuyerProfile(Map<String, dynamic> data) async =>
      await put(
        'buyers/profile/update',
        data,
        isProtected: true,
        userType: 'buyer',
      );

  Future<http.Response> uploadBuyerPhoto(File imageFile) async =>
      await postMultipart(
        'buyers/profile/upload-photo',
        {},
        filePath: imageFile.path,
        fileField: 'profile_photo',
        isProtected: true,
        userType: 'buyer',
      );

  // ---------------------------------------------------------------------------
  // FAVORITES
  // ---------------------------------------------------------------------------

  Future<http.Response> getFavorites() async =>
      await get('buyers/favorites', isProtected: true, userType: 'buyer');

  Future<http.Response> toggleFavorite(int adId) async {
    debugPrint("⭐ Toggling favorite for ad ID: $adId");
    return await post(
      'ads/$adId/favorite',
      {},
      isProtected: true,
      userType: 'buyer',
    );
  }

  Future<http.Response> removeFavorite(int adId) async {
    debugPrint("🗑️ Removing favorite for ad ID: $adId");
    return await post(
      'ads/$adId/favorite',
      {},
      isProtected: true,
      userType: 'buyer',
    );
  }

  // ---------------------------------------------------------------------------
  // ADS
  // ---------------------------------------------------------------------------

  Future<http.Response> getAds({Map<String, String>? queryParams}) async {
    final endpoint = queryParams == null || queryParams.isEmpty
        ? 'ads'
        : 'ads?${Uri(queryParameters: queryParams).query}';
    return await get(endpoint, isProtected: false, userType: 'buyer');
  }

  Future<http.Response> getAd(int id) async =>
      await get('ads/$id', isProtected: false, userType: 'buyer');

  Future<http.Response> recordAdView(int adId) async =>
      await post('ads/$adId/view', {}, isProtected: false, userType: 'buyer');

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

  Future<http.Response> getCategories() async =>
      await get('categories', isProtected: false, userType: 'buyer');

  Future<http.Response> getCategoriesByType(String type) async =>
      await get('categories/$type', isProtected: false, userType: 'buyer');

  // ---------------------------------------------------------------------------
  // KYC
  // ---------------------------------------------------------------------------

  Future<http.Response> getKycStatus() async =>
      await get('kyc/status', isProtected: true, userType: 'buyer');

  Future<http.Response> sendEmailOtp() async =>
      await post('kyc/email/send', {}, isProtected: true, userType: 'buyer');

  Future<http.Response> verifyEmail(String code) async => await post(
    'kyc/email/verify',
    {'code': code},
    isProtected: true,
    userType: 'buyer',
  );

  Future<http.Response> sendPhoneOtp() async =>
      await post('kyc/phone/send', {}, isProtected: true, userType: 'buyer');

  Future<http.Response> verifyPhone(String otp) async => await post(
    'kyc/phone/verify',
    {'code': otp},
    isProtected: true,
    userType: 'buyer',
  );

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

  Future<http.Response> getChats() async =>
      await get('chats', isProtected: true, userType: 'buyer');

  Future<http.Response> startChat(Map<String, dynamic> data) async =>
      await post('chats', data, isProtected: true, userType: 'buyer');

  Future<http.Response> getChatMessages(int chatId) async =>
      await get('chats/$chatId/messages', isProtected: true, userType: 'buyer');

  Future<http.Response> sendChatMessage(
    int chatId,
    Map<String, dynamic> data,
  ) async => await post(
    'chats/$chatId/messages',
    data,
    isProtected: true,
    userType: 'buyer',
  );

  Future<http.Response> markChatRead(int chatId) async => await post(
    'chats/$chatId/read',
    {},
    isProtected: true,
    userType: 'buyer',
  );

  // ---------------------------------------------------------------------------
  // CALLS
  // ---------------------------------------------------------------------------

  Future<http.Response> getCallToken({
    required String channelName,
    required int uid,
  }) async => await post(
    'calls/token',
    {'channel_name': channelName, 'uid': uid},
    isProtected: true,
    userType: 'buyer',
  );

  Future<http.Response> initiateCall({
    required int receiverId,
    required String channelName,
    required String callerName,
    required String callType,
  }) async => await post(
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

  Future<http.Response> endCall({
    required int receiverId,
    required String channelName,
  }) async => await post(
    'calls/end',
    {'receiver_id': receiverId, 'channel_name': channelName},
    isProtected: true,
    userType: 'buyer',
  );

  // ---------------------------------------------------------------------------
  // VENDOR
  // ---------------------------------------------------------------------------

  Future<http.Response> getVendorDashboard() async =>
      await get('vendor/dashboard', isProtected: true, userType: 'vendor');

  Future<http.Response> getVendorAnalytics() async =>
      await get('vendor/analytics', isProtected: true, userType: 'vendor');

  Future<http.Response> getVendorProfile() async =>
      await get('vendor/profile', isProtected: true, userType: 'vendor');

  Future<http.Response> updateVendorProfile(Map<String, dynamic> data) async =>
      await patch(
        'vendor/profile',
        data,
        isProtected: true,
        userType: 'vendor',
      );

  Future<http.Response> uploadVendorPhoto(File imageFile) async =>
      await postMultipart(
        'vendor/profile/photo',
        {},
        filePath: imageFile.path,
        fileField: 'photo',
        isProtected: true,
        userType: 'vendor',
      );

  Future<http.Response> uploadVendorLogo(File imageFile) async =>
      await postMultipart(
        'vendor/profile/logo',
        {},
        filePath: imageFile.path,
        fileField: 'logo',
        isProtected: true,
        userType: 'vendor',
      );

  Future<http.Response> getVoucher() async =>
      await get('vendor/voucher', isProtected: true, userType: 'vendor');

  Future<http.Response> voucherTopUp(Map<String, dynamic> data) async =>
      await post(
        'vendor/voucher/topup',
        data,
        isProtected: true,
        userType: 'vendor',
      );

  Future<http.Response> voucherSpend(Map<String, dynamic> data) async =>
      await post(
        'vendor/voucher/spend',
        data,
        isProtected: true,
        userType: 'vendor',
      );

  Future<http.Response> getVoucherTransactions() async => await get(
    'vendor/voucher/transactions',
    isProtected: true,
    userType: 'vendor',
  );

  Future<http.Response> getVendorSettings() async =>
      await get('vendor/settings', isProtected: true, userType: 'vendor');

  Future<http.Response> updateVendorSettings(Map<String, dynamic> data) async =>
      await patch(
        'vendor/settings',
        data,
        isProtected: true,
        userType: 'vendor',
      );

  Future<http.Response> getVendorSettingsOptions() async => await get(
    'vendor/settings/options',
    isProtected: true,
    userType: 'vendor',
  );

  Future<http.Response> changeVendorPassword(Map<String, dynamic> data) async =>
      await post(
        'vendor/settings/change-password',
        data,
        isProtected: true,
        userType: 'vendor',
      );

  Future<http.Response> deleteVendorAccount() async => await delete(
    'vendor/settings/account',
    isProtected: true,
    userType: 'vendor',
  );

  Future<http.Response> getMyAds() async =>
      await get('vendor/ads/my', isProtected: true, userType: 'vendor');

  Future<http.Response> createAd(Map<String, dynamic> data) async =>
      await post('vendor/ads', data, isProtected: true, userType: 'vendor');

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

  Future<http.Response> deleteAd(int id) async =>
      await delete('vendor/ads/$id', isProtected: true, userType: 'vendor');

  // ---------------------------------------------------------------------------
  // TRANSLATIONS
  // ---------------------------------------------------------------------------

  Future<http.Response> getLocales() async =>
      await get('translations/locales', isProtected: false, userType: 'buyer');

  Future<http.Response> getTranslations(String locale) async =>
      await get('translations/$locale', isProtected: false, userType: 'buyer');

  // ---------------------------------------------------------------------------
  // NOTIFICATION SETTINGS
  // ---------------------------------------------------------------------------

  Future<http.Response> getNotificationSettings() async =>
      await get('settings/notifications', isProtected: true, userType: 'buyer');

  Future<http.Response> updateNotificationSettings(
    Map<String, dynamic> data,
  ) async => await patch(
    'settings/notifications',
    data,
    isProtected: true,
    userType: 'buyer',
  );

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
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 GET [$userType]: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
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
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 POST [$userType]: $url");
      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
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
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 PUT [$userType]: $url");
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
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
    String? userType,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 PATCH [$userType]: $url");
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
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
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      headers.remove('Content-Type');
      headers['Accept'] = 'application/json';
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(headers);
      data.forEach((key, value) => request.fields[key] = value);
      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          filePath,
          filename: basename(filePath),
        ),
      );
      debugPrint("🚀 UPLOAD [$userType]: $url");
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response, userType: userType);
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
      final headers = await _getHeaders(
        protected: isProtected,
        userType: userType,
      );
      debugPrint("🚀 DELETE [$userType]: $url");
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response, userType: userType);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw _processError(e, "DELETE", endpoint);
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _getHeaders({
    bool protected = false,
    String? userType,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (protected) {
      final token = await getToken(userType: userType);
      debugPrint(
        "🔑 Token for $userType: ${token != null ? '[present]' : 'NULL'}",
      );
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint("⚠️ No token for userType: $userType");
      }
    }
    return headers;
  }

  Uri _buildUrl(String endpoint) {
    final clean = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$clean');
  }

  http.Response _handleResponse(http.Response response, {String? userType}) {
    debugPrint("📥 STATUS ${response.statusCode}: ${response.request?.url}");
    if (response.statusCode >= 200 && response.statusCode < 300)
      return response;

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        "Server error (${response.statusCode}). Please try again.",
      );
    }

    if (response.statusCode == 401 &&
        decoded is Map &&
        decoded['message'] != 'Incorrect email or password.') {
      clearToken(userType: userType);
      throw ApiException("Session expired. Please sign in again.");
    }

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

    if (decoded is Map && decoded.containsKey('message')) {
      throw ApiException(
        decoded['message']?.toString() ?? "An error occurred.",
      );
    }

    throw ApiException(
      "Server error (${response.statusCode}). Please try again.",
    );
  }

  String _processError(dynamic e, String method, String endpoint) {
    debugPrint("❌ $method ERROR [$endpoint]: $e");
    if (e is SocketException) return "No internet connection.";
    if (e is TimeoutException) return "Connection timed out.";
    final msg = e.toString().replaceFirst('Exception: ', '');
    return msg.isNotEmpty ? msg : "An unexpected error occurred.";
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
