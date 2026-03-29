// lib/services/vendor/vendor_auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api_service.dart';

class VendorAuthService {
  final ApiService _apiService = ApiService();
  static const String userType = 'vendor';

  // Vendor Registration
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
        isProtected: false,
        userType: userType,
      );

      final responseData = jsonDecode(response.body);

      if (responseData['token'] != null) {
        await _apiService.saveToken(responseData['token'], userType: userType);
        debugPrint("🔐 Vendor token saved after registration");
      }

      return responseData;
    } catch (e) {
      debugPrint("❌ Registration error: $e");
      throw Exception(e.toString());
    }
  }

  // Vendor Login
  Future<Map<String, dynamic>> login({
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
        isProtected: false,
        userType: userType,
      );

      final responseData = jsonDecode(response.body);

      if (responseData['token'] != null) {
        await _apiService.saveToken(responseData['token'], userType: userType);
        debugPrint("🔐 Vendor token saved after login");
      }

      return responseData;
    } catch (e) {
      debugPrint("❌ Login error: $e");
      throw Exception(e.toString());
    }
  }

  // Vendor Logout (Single source of truth)
  Future<void> logout() async {
    try {
      // Call logout API
      await _apiService.post('/v1/vendor/logout', {},
        isProtected: true,
        userType: userType,
      );
      debugPrint("✅ Vendor logged out successfully");
    } catch (e) {
      debugPrint("❌ Logout API error: $e");
    } finally {
      // Always clear token
      await _apiService.clearToken(userType: userType);
      debugPrint("🔐 Vendor token cleared");
    }
  }

  // Check if vendor is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _apiService.getToken(userType: userType);
    return token != null && token.isNotEmpty;
  }

  // Get vendor profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(
        '/v1/vendor/profile',
        isProtected: true,
        userType: userType,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Get profile error: $e");
      throw Exception(e.toString());
    }
  }

  // Update vendor profile
  Future<Map<String, dynamic>> updateProfile({
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
        userType: userType,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Update profile error: $e");
      throw Exception(e.toString());
    }
  }

  // Identity Verification (KYC)
  Future<Map<String, dynamic>> verifyIdentity({
    String? nin,
    String? bvn,
    String? documentPath,
  }) async {
    try {
      if (documentPath != null) {
        // Upload with file
        Map<String, String> data = {};
        if (nin != null) data['nin'] = nin;
        if (bvn != null) data['bvn'] = bvn;

        final response = await _apiService.upload(
          '/v1/vendor/nin/verify',
          data,
          filePath: documentPath,
          fileField: 'document',
          isProtected: true,
          userType: userType,
        );
        return jsonDecode(response.body);
      } else {
        // Regular post without file
        Map<String, dynamic> data = {};
        if (nin != null) data['nin'] = nin;
        if (bvn != null) data['bvn'] = bvn;

        final response = await _apiService.post(
          '/v1/vendor/verify-identity',
          data,
          isProtected: true,
          userType: userType,
        );
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("❌ Identity verification error: $e");
      throw Exception(e.toString());
    }
  }
}