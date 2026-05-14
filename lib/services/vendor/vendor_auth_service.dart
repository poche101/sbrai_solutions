// lib/services/vendor/vendor_auth_service.dart
import 'dart:convert';
import 'dart:io';
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
    required String businessCategory,
    required String address,
    required String state,
    required String city,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      debugPrint("🔐 Attempting vendor registration for: $email");
      debugPrint("🚀 TARGET URL: ${ApiService.baseUrl}/auth/register/vendor");

      // ApiService._handleResponse already throws clean messages for
      // 422 validation errors and other non-2xx responses, so we just
      // need to call and return the decoded body on success.
      final response = await _apiService.post(
        'auth/register/vendor',
        {
          'name': name,
          'email': email,
          'phone': phone,
          'business_name': businessName,
          'business_category': businessCategory,
          'business_address': address,
          'state': state,
          'city': city,
          'password': password,
          'password_confirmation': confirmPassword,
        },
        isProtected: false,
        userType: 'vendor',
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("📦 Registration response: $responseData");

      // Save token if returned on registration
      final token = responseData['data']?['token']?.toString();
      if (token != null) {
        await _apiService.saveToken(token, userType: 'vendor');
        debugPrint("🔐 Vendor token saved after registration");
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
        'auth/login/vendor',
        {'email': email, 'password': password},
        isProtected: false,
        userType: 'vendor',
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("📦 Login response body: $responseData");

      final token = responseData['data']?['token']?.toString();
      if (token != null) {
        await _apiService.saveToken(token, userType: 'vendor');
        debugPrint("🔐 Vendor token saved after login");
        debugPrint("✅ Login successful for: $email");
      }

      return responseData;
    } catch (e) {
      debugPrint("❌ Login error: $e");
      rethrow;
    }
  }

  /// ---------------- LOGOUT ----------------
  Future<void> logout() async {
    try {
      await _apiService.post(
        'auth/logout',
        {},
        isProtected: true,
        userType: 'vendor',
      );
      debugPrint("✅ Vendor logged out successfully");
    } catch (e) {
      debugPrint("❌ Logout API error: $e");
    } finally {
      await _apiService.clearToken();
      debugPrint("🔐 Vendor token cleared");
    }
  }

  /// ---------------- AUTH CHECK ----------------
  Future<bool> isAuthenticated() async {
    final token = await _apiService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// ---------------- GET PROFILE ----------------
  Future<Map<String, dynamic>> getProfile() async {
    try {
      debugPrint("🔐 Fetching vendor profile");
      final response = await _apiService.get(
        'vendor/profile',
        isProtected: true,
        userType: 'vendor',
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
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
      final response = await _apiService.patch(
        // ✅ was post()
        'vendor/profile', // ✅ was vendor/update-profile
        {
          'name': name, // ✅ was full_name
          'phone': phone.toString(),
          'business_name': businessName,
          'business_address': address,
        },
        isProtected: true,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("❌ Update profile error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    try {
      final response = await _apiService.upload(
        'vendor/profile/photo', // ✅ correct endpoint
        {},
        filePath: filePath,
        fileField: 'photo', // ← check what field name the controller expects
        isProtected: true,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("❌ Photo upload error: $e");
      rethrow;
    }
  }

  /// ---------------- KYC / NIN VERIFY ----------------
  Future<Map<String, dynamic>> verifyIdentity({
    required String nin,
    File? document,
  }) async {
    try {
      debugPrint("🔐 Starting NIN verification: $nin");

      if (nin.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(nin)) {
        throw Exception('Invalid NIN format. NIN must be 11 digits.');
      }

      final response = await _apiService.post(
        'kyc/identity/verify',
        {'nin': nin},
        isProtected: true,
        userType: 'vendor',
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("❌ NIN verification error: $e");
      rethrow;
    }
  }

  /// ---------------- HELPERS ----------------
  Future<Map<String, dynamic>> checkNINStatus(String nin) async {
    try {
      final response = await _apiService.get(
        'vendor/nin/$nin/status',
        isProtected: true,
        userType: 'vendor',
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNINDetails(String nin) async {
    try {
      final response = await _apiService.get(
        'vendor/nin/$nin/details',
        isProtected: true,
        userType: 'vendor',
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
