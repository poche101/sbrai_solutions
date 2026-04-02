// lib/services/vendor/vendor_auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api_service.dart';

class VendorAuthService {
  final ApiService _apiService = ApiService();

  /// ---------------- REGISTER ----------------
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String address,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      debugPrint("🔐 Attempting vendor registration for: $email");

      final response = await _apiService.post(
<<<<<<< HEAD
        'v1/vendor/register', // Standardized path
=======
        '/vendor/register',
>>>>>>> 5c994598d3001bdbece74318c1bd11712be62327
        {
          'full_name': name,
          'email': email,
          'phone_number': phone,
          'business_name': businessName,
          'business_address': address,
          'password': password,
          'password_confirmation': confirmPassword,
        },
        isProtected: false,
      );

      final responseData = jsonDecode(response.body);
      debugPrint("📦 Registration response: $responseData");

      /// ✅ FIXED: Correct token path
      if (responseData['data'] != null &&
          responseData['data']['token'] != null) {
        await _apiService.saveToken(responseData['data']['token']);
        debugPrint("🔐 Vendor token saved after registration");
      } else {
        debugPrint("⚠️ No token in registration response");
      }

      return responseData;
    } catch (e) {
      debugPrint("❌ Registration service error: $e");
      rethrow;
    }
  }

  /// ---------------- LOGIN ----------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint("🔐 Attempting vendor login for: $email");

      final response = await _apiService.post(
<<<<<<< HEAD
        'v1/vendor/login', // Added v1 to match registration pattern
        {'email': email, 'password': password},
=======
        '/vendor/login',
        {
          'email': email,
          'password': password,
        },
>>>>>>> 5c994598d3001bdbece74318c1bd11712be62327
        isProtected: false,
      );

      final responseData = jsonDecode(response.body);
      debugPrint("📦 Login response status: ${response.statusCode}");
      debugPrint("📦 Login response body: $responseData");

      /// ✅ FIXED: Correct token path
      if (responseData['data'] != null &&
          responseData['data']['token'] != null) {
        await _apiService.saveToken(responseData['data']['token']);
        debugPrint("🔐 Vendor token saved after login");
        debugPrint("✅ Login successful for: $email");
      } else {
        debugPrint("⚠️ No token in login response");
      }

      return responseData;
    } catch (e) {
<<<<<<< HEAD
      debugPrint("❌ Login service error: $e");
      rethrow;
    }
  }

  // Vendor Logout
  Future<void> logout() async {
    try {
      await _apiService.post(
        'v1/vendor/logout', // Consistent naming
=======
      debugPrint("❌ Login error: $e");

      if (e.toString().contains("Invalid email or password") ||
          e.toString().contains("Invalid credentials")) {
        throw Exception("Invalid email or password. Please try again.");
      }

      throw Exception(e.toString());
    }
  }

  /// ---------------- LOGOUT ----------------
  Future<void> logout() async {
    try {
      await _apiService.post(
        '/vendor/logout',
>>>>>>> 5c994598d3001bdbece74318c1bd11712be62327
        {},
        isProtected: true,
      );

      debugPrint("✅ Vendor logged out successfully");
    } catch (e) {
      debugPrint("❌ Logout API error: $e");
    } finally {
<<<<<<< HEAD
      await _apiService.clearToken(userType: userType);
=======
      /// ✅ Always clear token
      await _apiService.clearToken();
>>>>>>> 5c994598d3001bdbece74318c1bd11712be62327
      debugPrint("🔐 Vendor token cleared");
    }
  }

  /// ---------------- AUTH CHECK ----------------
  Future<bool> isAuthenticated() async {
    final token = await _apiService.getToken();
    final isAuth = token != null && token.isNotEmpty;
    debugPrint("🔐 Vendor authenticated: $isAuth");
    return isAuth;
  }

  /// ---------------- GET PROFILE ----------------
  Future<Map<String, dynamic>> getProfile() async {
    try {
      debugPrint("🔐 Fetching vendor profile");

      final response = await _apiService.get(
<<<<<<< HEAD
        'v1/vendor/profile',
=======
        '/vendor/profile',
>>>>>>> 5c994598d3001bdbece74318c1bd11712be62327
        isProtected: true,
      );

      final responseData = jsonDecode(response.body);
      debugPrint("✅ Profile fetched successfully");

      return responseData;
    } catch (e) {
      debugPrint("❌ Get profile error: $e");
      rethrow;
    }
  }

  /// ---------------- UPDATE PROFILE ----------------
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String businessName,
    required String address,
  }) async {
    try {
      debugPrint("🔐 Updating vendor profile");

      final response = await _apiService.put(
<<<<<<< HEAD
        'v1/vendor/profile',
=======
        '/vendor/profile',
>>>>>>> 5c994598d3001bdbece74318c1bd11712be62327
        {
          'full_name': name,
          'phone_number': phone,
          'business_name': businessName,
          'business_address': address,
        },
        isProtected: true,
      );

      final responseData = jsonDecode(response.body);
      debugPrint("✅ Profile updated successfully");

      return responseData;
    } catch (e) {
      debugPrint("❌ Update profile error: $e");
      rethrow;
    }
  }

  /// ---------------- KYC ----------------
  Future<Map<String, dynamic>> verifyIdentity({
    String? nin,
    String? bvn,
    String? documentPath,
  }) async {
    try {
      debugPrint("🔐 Starting identity verification");

      if (documentPath != null) {
        Map<String, String> data = {};
        if (nin != null) data['nin'] = nin;
        if (bvn != null) data['bvn'] = bvn;

        final response = await _apiService.upload(
<<<<<<< HEAD
          'v1/vendor/nin/verify',
=======
          '/vendor/nin/verify',
>>>>>>> 5c994598d3001bdbece74318c1bd11712be62327
          data,
          filePath: documentPath,
          fileField: 'document',
          isProtected: true,
        );

        return jsonDecode(response.body);
      } else {
        Map<String, dynamic> data = {};
        if (nin != null) data['nin'] = nin;
        if (bvn != null) data['bvn'] = bvn;

        final response = await _apiService.post(
<<<<<<< HEAD
          'v1/vendor/verify-identity',
=======
          '/vendor/verify-identity',
>>>>>>> 5c994598d3001bdbece74318c1bd11712be62327
          data,
          isProtected: true,
        );

        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("❌ Identity verification error: $e");
      rethrow;
    }
  }
}
