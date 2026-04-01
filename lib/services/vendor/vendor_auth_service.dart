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
        '/vendor/register',
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
      debugPrint("❌ Registration error: $e");
      throw Exception(e.toString());
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
        '/vendor/login',
        {
          'email': email,
          'password': password,
        },
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
        {},
        isProtected: true,
      );

      debugPrint("✅ Vendor logged out successfully");
    } catch (e) {
      debugPrint("❌ Logout API error: $e");
    } finally {
      /// ✅ Always clear token
      await _apiService.clearToken();
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
        '/vendor/profile',
        isProtected: true,
      );

      final responseData = jsonDecode(response.body);
      debugPrint("✅ Profile fetched successfully");

      return responseData;
    } catch (e) {
      debugPrint("❌ Get profile error: $e");
      throw Exception(e.toString());
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
        '/vendor/profile',
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
      throw Exception(e.toString());
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
          '/vendor/nin/verify',
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
          '/vendor/verify-identity',
          data,
          isProtected: true,
        );

        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("❌ Identity verification error: $e");
      throw Exception(e.toString());
    }
  }
}