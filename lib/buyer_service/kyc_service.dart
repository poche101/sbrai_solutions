import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/buyer/kyc_status_model.dart';

/// Service layer for all KYC endpoints.
///
/// Routes (all require auth:sanctum):
///   GET  /api/v1/kyc/status
///   POST /api/v1/kyc/email/send
///   POST /api/v1/kyc/email/verify       body: { "code": "123456" }
///   POST /api/v1/kyc/phone/send
///   POST /api/v1/kyc/phone/verify       body: { "code": "123456" }
///   POST /api/v1/kyc/identity/verify    body: { "nin": "12345678901", "document"?: file }
///
/// Controller response envelope always uses:
///   { "status": true/false, "message": "...", "data": { ... } }
///
/// The service throws the message string so callers just catch a String.

class KycService {
  final ApiService _api;

  KycService({ApiService? api}) : _api = api ?? ApiService();

  // ── GET /api/v1/kyc/status ─────────────────────────────────────────────────
  /// Fetches the full KYC status. Call this on KYCScreen load to pre-fill
  /// the progress bar.
  ///
  /// Controller returns:
  /// {
  ///   "status": true,
  ///   "data": {
  ///     "email_verified": bool,
  ///     "phone_verified": bool,
  ///     "identity_verified": bool,
  ///     "is_verified": bool,
  ///     "progress": 0.0–1.0
  ///   }
  /// }
  Future<KycStatus> getStatus() async {
    try {
      final response = await _api.getKycStatus();
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['status'] == true && body['data'] != null) {
        return KycStatus.fromJson(body['data'] as Map<String, dynamic>);
      }

      throw body['message'] ?? 'Failed to load KYC status.';
    } catch (e) {
      debugPrint("❌ KycService.getStatus: $e");
      rethrow;
    }
  }

  // ── Email ──────────────────────────────────────────────────────────────────

  /// POST /api/v1/kyc/email/send
  /// Triggers a 6-digit OTP email to the user's registered address.
  ///
  /// Controller returns:
  ///   { "status": true, "message": "Verification code sent to user@example.com" }
  ///
  /// Throws if already verified (422) or send fails (500).
  Future<String> sendEmailOtp() async {
    try {
      final response = await _api.sendEmailOtp();
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      print("📡 API Status Code: ${response.statusCode}");
      print("📡 API Response Body: ${response.body}");

      if (body['status'] == true) {
        return body['message'] as String? ?? 'Verification code sent.';
      }

      throw body['message'] ?? 'Failed to send code.';
    } catch (e) {
      print("❌ KycService.sendEmailOtp Exception: $e");
      rethrow;
    }
  }

  /// POST /api/v1/kyc/email/verify
  /// Submits the 6-digit [code] the user received by email.
  ///
  /// Controller validates: required|string|size:6  (field name: "code")
  /// Controller returns:
  ///   { "status": true, "message": "Email verified successfully.", "data": { "progress": 0.33 } }
  ///
  /// Throws on invalid/expired code (422).
  /// POST /api/v1/kyc/email/verify
  Future<KycStatus> verifyEmail(String code) async {
    _assertOtpFormat(code); // ← This stays here

    try {
      final response = await _api.verifyEmail(code);

      print("✅ Verify Response Code: ${response.statusCode}");
      print("✅ Verify Response Body: ${response.body}");

      return await _parseVerifyResponse(response, 'verifyEmail');
    } catch (e) {
      print("❌ verifyEmail Error: $e");
      rethrow;
    }
  }
  // ── Phone ──────────────────────────────────────────────────────────────────

  /// POST /api/v1/kyc/phone/send
  /// Triggers a 6-digit OTP SMS to the user's registered phone number.
  ///
  /// Controller returns:
  ///   { "status": true, "message": "SMS code sent to 080XXXXXXXX" }
  ///
  /// Throws if phone not set (422) or already verified (422).
  /// Note: OTP is currently logged server-side (Termii pending sender-ID approval).
  Future<String> sendPhoneOtp() async {
    try {
      final response = await _api.sendPhoneOtp();
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['status'] == true) {
        return body['message'] as String? ?? 'SMS code sent.';
      }

      throw body['message'] ?? 'Failed to send SMS verification code.';
    } catch (e) {
      debugPrint("❌ KycService.sendPhoneOtp: $e");
      rethrow;
    }
  }

  /// POST /api/v1/kyc/phone/verify
  /// Submits the 6-digit [code] the user received by SMS.
  ///
  /// Controller validates: required|string|size:6  (field name: "code")
  /// Controller returns:
  ///   { "status": true, "message": "Phone number verified successfully.", "data": { "progress": 0.67 } }
  ///
  /// Throws on invalid/expired code (422).
  Future<KycStatus> verifyPhone(String code) async {
    _assertOtpFormat(code);
    try {
      final response = await _api.verifyPhone(code);
      return await _parseVerifyResponse(response, 'verifyPhone');
    } catch (e) {
      debugPrint("❌ KycService.verifyPhone: $e");
      rethrow;
    }
  }

  // ── Identity (NIN) ─────────────────────────────────────────────────────────

  /// POST /api/v1/kyc/identity/verify
  /// Submits the user's NIN and an optional supporting [document] file.
  ///
  /// Controller validates:
  ///   nin      — required|string|size:11|regex:/^[0-9]+$/
  ///   document — nullable|file|mimes:pdf,jpg,jpeg,png|max:5120 (5 MB)
  ///
  /// Controller returns:
  ///   {
  ///     "status": true,
  ///     "message": "Identity verified successfully.",
  ///     "data": { "document_uploaded": bool, "progress": 1.0 }
  ///   }
  ///
  /// Throws if NIN already used (422), already verified (422), or file too large (422).
  Future<KycStatus> verifyIdentity({
    required String nin,
    File? document,
  }) async {
    _assertNinFormat(nin);
    try {
      final response = await _api.verifyIdentity(nin: nin, document: document);
      return await _parseVerifyResponse(response, 'verifyIdentity');
    } catch (e) {
      debugPrint("❌ KycService.verifyIdentity: $e");
      rethrow;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Parses the standard verify response envelope:
  /// { "status": true, "message": "...", "data": { "progress": 0.67 } }
  ///
  /// The verify endpoints only return { progress } in data, not the full
  /// status object. Re-fetches the full status so the UI stays consistent.
  /// Falls back to a minimal KycStatus built from the progress value if
  /// the re-fetch fails.
  Future<KycStatus> _parseVerifyResponse(
    dynamic response,
    String caller,
  ) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (body['status'] == true) {
      try {
        return await getStatus();
      } catch (_) {
        // Re-fetch failed — build a minimal status from the returned progress
        final progress = (body['data']?['progress'] as num?)?.toDouble() ?? 0.0;
        return KycStatus(
          emailVerified: false,
          phoneVerified: false,
          identityVerified: false,
          isVerified: progress >= 1.0,
          progress: progress,
        );
      }
    }

    throw body['message'] ?? '$caller failed.';
  }

  /// Client-side guard: OTP must be exactly 6 numeric digits.
  /// Matches controller rule: required|string|size:6
  void _assertOtpFormat(String code) {
    if (code.length != 6 || int.tryParse(code) == null) {
      throw 'Please enter the 6-digit code.';
    }
  }

  /// Client-side guard: NIN must be exactly 11 numeric digits.
  /// Matches controller rule: required|string|size:11|regex:/^[0-9]+$/
  void _assertNinFormat(String nin) {
    if (nin.length != 11 || int.tryParse(nin) == null) {
      throw 'NIN must be exactly 11 digits.';
    }
  }
}
