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
/// All verify responses include an updated `progress` value:
///   { "status": true, "data": { "progress": 0.67 } }
///
/// Error responses always have:
///   { "status": false, "message": "..." }
/// The service throws the message string so callers just catch a String.

class KycService {
  final ApiService _api;

  KycService({ApiService? api}) : _api = api ?? ApiService();

  // ── GET /api/v1/kyc/status ─────────────────────────────────────────────────
  /// Fetches the full KYC status. Call this on KYCScreen load to pre-fill
  /// the progress bar. Returns a typed [KycStatus].
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
  /// Returns the server confirmation message (e.g. "Verification code sent to …").
  /// Throws if the email is already verified (422) or the send fails (500).
  Future<String> sendEmailOtp() async {
    try {
      final response = await _api.sendEmailOtp();
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['status'] == true) {
        return body['message'] as String? ?? 'Verification code sent.';
      }

      throw body['message'] ?? 'Failed to send email verification code.';
    } catch (e) {
      debugPrint("❌ KycService.sendEmailOtp: $e");
      rethrow;
    }
  }

  /// POST /api/v1/kyc/email/verify
  /// Submits the 6-digit [code] the user received by email.
  /// Returns the updated [KycStatus] (with new progress value) on success.
  ///
  /// Controller validates: required|string|size:6
  /// Throws on invalid/expired code (422).
  Future<KycStatus> verifyEmail(String code) async {
    _assertOtpFormat(code);
    try {
      final response = await _api.verifyEmail(code);
      return _parseVerifyResponse(response, 'verifyEmail');
    } catch (e) {
      debugPrint("❌ KycService.verifyEmail: $e");
      rethrow;
    }
  }

  // ── Phone ──────────────────────────────────────────────────────────────────

  /// POST /api/v1/kyc/phone/send
  /// Triggers a 6-digit OTP SMS to the user's registered phone number.
  /// Throws if phone is not set on the account (422) or already verified (422).
  ///
  /// Note: SMS is currently logged server-side (Termii pending sender-ID
  /// approval). Check Laravel logs for the code during testing.
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
  /// Returns the updated [KycStatus] on success.
  ///
  /// Controller validates: required|string|size:6
  /// Throws on invalid/expired code (422).
  Future<KycStatus> verifyPhone(String code) async {
    _assertOtpFormat(code);
    try {
      final response = await _api.verifyPhone(code);
      return _parseVerifyResponse(response, 'verifyPhone');
    } catch (e) {
      debugPrint("❌ KycService.verifyPhone: $e");
      rethrow;
    }
  }

  // ── Identity (NIN) ─────────────────────────────────────────────────────────

  /// POST /api/v1/kyc/identity/verify
  /// Submits the user's NIN and an optional supporting [document] file.
  ///
  /// [nin] must be exactly 11 numeric digits (validated server-side).
  /// [document] is optional; accepted formats: pdf, jpg, jpeg, png — max 5 MB.
  ///
  /// Returns the updated [KycStatus] on success.
  /// Throws if NIN is already used by another account, already verified, or
  /// the file exceeds the size limit.
  Future<KycStatus> verifyIdentity({
    required String nin,
    File? document,
  }) async {
    _assertNinFormat(nin);
    try {
      final response = await _api.verifyIdentity(nin: nin, document: document);
      return _parseVerifyResponse(response, 'verifyIdentity');
    } catch (e) {
      debugPrint("❌ KycService.verifyIdentity: $e");
      rethrow;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Parses the standard verify response envelope:
  /// { "status": true, "data": { "progress": 0.67 } }
  ///
  /// Merges the returned progress into a fresh [KycStatus] by re-fetching,
  /// or falls back to a minimal status built from the progress value alone.
  Future<KycStatus> _parseVerifyResponse(
    dynamic response,
    String caller,
  ) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (body['status'] == true) {
      // The verify endpoints only return { progress } in data, not the full
      // status object. Re-fetch the full status so the UI stays consistent.
      try {
        return await getStatus();
      } catch (_) {
        // If the re-fetch fails, return a minimal status with the new progress.
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
  /// Matches the server rule: required|string|size:6
  void _assertOtpFormat(String code) {
    if (code.length != 6 || int.tryParse(code) == null) {
      throw 'Please enter the 6-digit code.';
    }
  }

  /// Client-side guard: NIN must be exactly 11 numeric digits.
  /// Matches the server rule: required|string|size:11|regex:/^[0-9]+$/
  void _assertNinFormat(String nin) {
    if (nin.length != 11 || int.tryParse(nin) == null) {
      throw 'NIN must be exactly 11 digits.';
    }
  }
}
