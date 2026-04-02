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
        'v1/vendor/register', // Standardized path with versioning
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

      // Save token if registration automatically logs the user in
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
        'v1/vendor/login', // Standardized path
        {'email': email, 'password': password},
        isProtected: false,
      );

      final responseData = jsonDecode(response.body);
      debugPrint("📦 Login response status: ${response.statusCode}");
      debugPrint("📦 Login response body: $responseData");

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
      debugPrint("❌ Login service error: $e");

      // Better user-facing error messages for common auth failures
      if (e.toString().contains("401") ||
          e.toString().contains("Invalid credentials")) {
        throw Exception("Invalid email or password. Please try again.");
      }
      rethrow;
    }
  }

  /// ---------------- LOGOUT ----------------
  Future<void> logout() async {
    try {
      await _apiService.post('v1/vendor/logout', {}, isProtected: true);
      debugPrint("✅ Vendor logged out successfully from server");
    } catch (e) {
      debugPrint("❌ Logout API error (server-side): $e");
    } finally {
      // Always clear the local token regardless of server success
      await _apiService.clearToken();
      debugPrint("🔐 Local vendor token cleared");
    }
  }

  /// ---------------- AUTH CHECK ----------------
  Future<bool> isAuthenticated() async {
    final token = await _apiService.getToken();
    final isAuth = token != null && token.isNotEmpty;
    debugPrint("🔐 Vendor authenticated check: $isAuth");
    return isAuth;
  }

  /// ---------------- GET PROFILE ----------------
  Future<Map<String, dynamic>> getProfile() async {
    try {
      debugPrint("🔐 Fetching vendor profile");

      final response = await _apiService.get(
        'v1/vendor/profile',
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

      final response = await _apiService.put('v1/vendor/profile', {
        'full_name': name,
        'phone_number': phone,
        'business_name': businessName,
        'business_address': address,
      }, isProtected: true);

      final responseData = jsonDecode(response.body);
      debugPrint("✅ Profile updated successfully");

      return responseData;
    } catch (e) {
      debugPrint("❌ Update profile error: $e");
      rethrow;
    }
  }

  /// ---------------- KYC / IDENTITY ----------------
  Future<Map<String, dynamic>> verifyIdentity({
    String? nin,
    String? bvn,
    String? documentPath,
  }) async {
    try {
      debugPrint("🔐 Starting identity verification");

      if (documentPath != null) {
        // Multi-part upload for files
        Map<String, String> data = {};
        if (nin != null) data['nin'] = nin;
        if (bvn != null) data['bvn'] = bvn;

        final response = await _apiService.upload(
          'v1/vendor/nin/verify',
          data,
          filePath: documentPath,
          fileField: 'document',
          isProtected: true,
        );

        return jsonDecode(response.body);
      } else {
        // Standard JSON post for textual data only
        Map<String, dynamic> data = {};
        if (nin != null) data['nin'] = nin;
        if (bvn != null) data['bvn'] = bvn;

        final response = await _apiService.post(
          'v1/vendor/verify-identity',
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
