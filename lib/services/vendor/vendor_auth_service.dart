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
    required String address,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      debugPrint("🔐 Attempting vendor registration for: $email");

      final response = await _apiService.post('/vendor/register', {
        'full_name': name,
        'email': email,
        'phone_number': phone,
        'business_name': businessName,
        'business_address': address,
        'password': password,
        'password_confirmation': confirmPassword,
      }, isProtected: false);

      final responseData = jsonDecode(response.body);
      debugPrint("📦 Registration response: $responseData");

      // Handle Laravel Validation Errors (422)
      if (response.statusCode == 422) {
        if (responseData['errors'] != null) {
          Map<String, dynamic> errors = responseData['errors'];
          // Extract the first specific error message
          String firstError = errors.values.first[0].toString();
          throw Exception(firstError);
        }
        throw Exception(responseData['message'] ?? "Validation failed");
      }

      // Handle Success
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['data'] != null &&
            responseData['data']['token'] != null) {
          await _apiService.saveToken(responseData['data']['token']);
          debugPrint("🔐 Vendor token saved after registration");
        }
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? "Registration failed");
      }
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

      final response = await _apiService.post('/vendor/login', {
        'email': email,
        'password': password,
      }, isProtected: false);

      final responseData = jsonDecode(response.body);
      debugPrint("📦 Login response body: $responseData");

      if (response.statusCode == 422 || response.statusCode == 401) {
        throw Exception(
          responseData['message'] ?? "Invalid email or password.",
        );
      }

      if (response.statusCode == 200) {
        if (responseData['data'] != null &&
            responseData['data']['token'] != null) {
          await _apiService.saveToken(responseData['data']['token']);
          debugPrint("🔐 Vendor token saved after login");
          debugPrint("✅ Login successful for: $email");
        }
        return responseData;
      } else {
        throw Exception("Login failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Login error: $e");
      rethrow;
    }
  }

  /// ---------------- LOGOUT ----------------
  Future<void> logout() async {
    try {
      await _apiService.post('/vendor/logout', {}, isProtected: true);
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
        '/vendor/profile',
        isProtected: true,
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) return responseData;
      throw Exception(responseData['message'] ?? "Failed to fetch profile");
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
      final response = await _apiService.post('/vendor/update-profile', {
        'full_name': name,
        'phone_number': phone,
        'business_name': businessName,
        'business_address': address,
      }, isProtected: true);

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) return responseData;

      throw Exception(responseData['message'] ?? "Profile update failed");
    } catch (e) {
      debugPrint("❌ Update profile error: $e");
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

      final response = await _apiService.post('/vendor/nin/verify', {
        'nin': nin,
      }, isProtected: true);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 422) {
        String msg = responseData['errors'] != null
            ? responseData['errors'].values.first[0].toString()
            : (responseData['message'] ?? "Verification failed");
        throw Exception(msg);
      }

      if (response.statusCode == 200) return responseData;
      throw Exception(responseData['message'] ?? "NIN verification failed");
    } catch (e) {
      debugPrint("❌ NIN verification error: $e");
      rethrow;
    }
  }

  /// ---------------- HELPERS ----------------
  Future<Map<String, dynamic>> checkNINStatus(String nin) async {
    try {
      final response = await _apiService.get(
        '/vendor/nin/$nin/status',
        isProtected: true,
      );
      return jsonDecode(response.body);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNINDetails(String nin) async {
    try {
      final response = await _apiService.get(
        '/vendor/nin/$nin/details',
        isProtected: true,
      );
      return jsonDecode(response.body);
    } catch (e) {
      rethrow;
    }
  }
}
