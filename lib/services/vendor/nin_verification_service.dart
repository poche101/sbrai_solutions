import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api_service.dart';

class NINVerificationService {
  final ApiService _apiService = ApiService();

  /// Verify NIN with Mono service
  Future<Map<String, dynamic>> verifyNIN(String nin) async {
    try {
      debugPrint("🔐 Verifying NIN: $nin");

      final response = await _apiService.post(
        '/kyc/identity/verify',
        {'nin': nin},
        isProtected: true,
      );

      final responseData = jsonDecode(response.body);
      debugPrint("📦 NIN Verification response: $responseData");

      return responseData;
    } catch (e) {
      debugPrint("❌ NIN Verification error: $e");
      rethrow;
    }
  }

  /// Check NIN verification status
  Future<Map<String, dynamic>> checkNINStatus(String nin) async {
    try {
      debugPrint("🔐 Checking NIN status for: $nin");

      final response = await _apiService.get(
        '/vendor/nin/$nin/status',
        isProtected: true,
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      debugPrint("❌ Check NIN status error: $e");
      rethrow;
    }
  }

  /// Get NIN verification details
  Future<Map<String, dynamic>> getNINDetails(String nin) async {
    try {
      debugPrint("🔐 Getting NIN details for: $nin");

      final response = await _apiService.get(
        '/vendor/nin/$nin/details',
        isProtected: true,
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      debugPrint("❌ Get NIN details error: $e");
      rethrow;
    }
  }
}