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

      final response = await _apiService.post(
        '/vendor/update-profile',
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
    required String nin, // Make nin required
    String? documentPath, // Document is optional
  }) async {
    try {
      debugPrint("🔐 Starting NIN verification");
      debugPrint("🆔 NIN: $nin");

      // Validate NIN format
      if (nin.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(nin)) {
        throw Exception('Invalid NIN format. NIN must be 11 digits.');
      }


      final response = await _apiService.post(
        '/vendor/nin/verify',
        {'nin': nin},
        isProtected: true,
      );

      final responseData = jsonDecode(response.body);
      debugPrint("📦 NIN verification response: $responseData");

      return responseData;
    } catch (e) {
      debugPrint("❌ NIN verification error: $e");
      rethrow;
    }
  }

// Helper method to check NIN verification status
  Future<Map<String, dynamic>> checkNINStatus(String nin) async {
    try {
      debugPrint("🔐 Checking NIN status for: $nin");

      final response = await _apiService.get(
        '/vendor/nin/$nin/status',
        isProtected: true,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Check NIN status error: $e");
      rethrow;
    }
  }

// Helper method to get NIN verification details
  Future<Map<String, dynamic>> getNINDetails(String nin) async {
    try {
      debugPrint("🔐 Getting NIN details for: $nin");

      final response = await _apiService.get(
        '/vendor/nin/$nin/details',
        isProtected: true,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Get NIN details error: $e");
      rethrow;
    }
  }
}