import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../buyer_service/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Vendor Registration
  Future<Map<String, dynamic>> registerVendor({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String address,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/v1/vendor/register',
        {
          'full_name': name,
          'email': email,
          'phone_number': phone,
          'business_name': businessName,
          'business_address': address,
          'password': password,
          'password_confirmation': confirmPassword,
        },
        isProtected: false, // Registration doesn't require auth
      );

      final responseData = jsonDecode(response.body);

      // If registration returns a token, save it automatically
      if (responseData['token'] != null) {
        await _apiService.saveToken(responseData['token']);
        debugPrint("🔐 Vendor token saved after registration");
      }

      return responseData;
    } catch (e) {
      debugPrint("❌ Registration error: $e");
      throw Exception(e.toString());
    }
  }

  // Vendor Login
  Future<Map<String, dynamic>> loginVendor({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/v1/vendor/login',
        {
          'email': email,
          'password': password,
        },
        isProtected: false, // Login doesn't require auth
      );

      final responseData = jsonDecode(response.body);

      // Save token on successful login
      if (responseData['token'] != null) {
        await _apiService.saveToken(responseData['token']);
        debugPrint("🔐 Vendor token saved after login");
      }

      return responseData;
    } catch (e) {
      debugPrint("❌ Login error: $e");
      throw Exception(e.toString());
    }
  }

  // Vendor Logout
  Future<void> logoutVendor() async {
    try {
      // Call logout endpoint if your API has one
      await _apiService.post('/v1/vendor/logout', {}, isProtected: true);
      debugPrint("✅ Vendor logged out successfully");
    } catch (e) {
      debugPrint("❌ Logout error: $e");
      // Even if API fails, clear local token
    } finally {
      await _apiService.clearToken();
      debugPrint("🔐 Vendor token cleared");
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _apiService.getToken();
    return token != null && token.isNotEmpty;
  }

  // Get current vendor profile (example protected endpoint)
  Future<Map<String, dynamic>> getVendorProfile() async {
    try {
      final response = await _apiService.get(
        '/v1/vendor/profile',
        isProtected: true,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Get profile error: $e");
      throw Exception(e.toString());
    }
  }

  // Update vendor profile (example protected endpoint)
  Future<Map<String, dynamic>> updateVendorProfile({
    required String name,
    required String phone,
    required String businessName,
    required String address,
  }) async {
    try {
      final response = await _apiService.put(
        '/v1/vendor/profile',
        {
          'full_name': name,
          'phone_number': phone,
          'business_name': businessName,
          'business_address': address,
        },
        isProtected: true,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Update profile error: $e");
      throw Exception(e.toString());
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/v1/vendor/change-password',
        {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
        isProtected: true,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Change password error: $e");
      throw Exception(e.toString());
    }
  }

  // Forgot password request
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        '/v1/vendor/forgot-password',
        {
          'email': email,
        },
        isProtected: false,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Forgot password error: $e");
      throw Exception(e.toString());
    }
  }

  // Reset password with token
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/v1/vendor/reset-password',
        {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': confirmPassword,
        },
        isProtected: false,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Reset password error: $e");
      throw Exception(e.toString());
    }
  }
}