// lib/services/vendor/vendor_kyc_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sbrai_solutions/services/api_service.dart';
import 'package:sbrai_solutions/models/vendor/vendor_kyc_status.dart';

/// Service layer for all Vendor KYC endpoints.
///
/// Routes (all require auth:sanctum, userType: vendor):
///   GET  /api/v1/kyc/status
///   POST /api/v1/kyc/email/send
///   POST /api/v1/kyc/email/verify       body: { "code": "123456" }
///   POST /api/v1/kyc/phone/send
///   POST /api/v1/kyc/phone/verify       body: { "code": "123456" }
///   POST /api/v1/kyc/identity/verify    body: { "nin": "12345678901", "document"?: file }
///
/// Controller response envelope:
///   { "status": true/false OR "success"/"error", "message": "...", "data": { ... } }
///
/// The service throws the message string so callers just catch a String.

class VendorKYCService {
  final ApiService _api;

  VendorKYCService({ApiService? api}) : _api = api ?? ApiService();

  // ── GET /api/v1/kyc/status ─────────────────────────────────────────────────
  /// Fetches the full KYC status for the authenticated vendor.
  /// Call this on KYCScreen load to pre-fill the progress bar.
  ///
  /// Controller returns:
  /// {
  ///   "status": true,
  ///   "data": {
  ///     "email_verified":    bool,
  ///     "phone_verified":    bool,
  ///     "identity_verified": bool,
  ///     "is_verified":       bool,
  ///     "progress":          0.0–1.0
  ///   }
  /// }
  Future<VendorKycStatus> getStatus() async {
    try {
      final response = await _api.get(
        'kyc/status',
        isProtected: true,
        userType: 'vendor',
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      debugPrint("📡 getStatus body: ${response.body}");

      if (_isSuccess(body) && body['data'] != null) {
        return VendorKycStatus.fromJson(body['data'] as Map<String, dynamic>);
      }

      throw body['message'] ?? 'Failed to load KYC status.';
    } catch (e) {
      debugPrint("❌ VendorKYCService.getStatus: $e");
      rethrow;
    }
  }

  // ── Email ──────────────────────────────────────────────────────────────────

  /// POST /api/v1/kyc/email/send
  /// Triggers a 6-digit OTP email to the vendor's registered address.
  ///
  /// Controller returns:
  ///   { "status": true, "message": "Verification code sent to vendor@example.com" }
  ///
  /// Throws if already verified (422) or send fails (500).
  Future<String> sendEmailOtp() async {
    try {
      final response = await _api.post(
        'kyc/email/send',
        {},
        isProtected: true,
        userType: 'vendor',
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      debugPrint("📡 sendEmailOtp status: ${response.statusCode}");
      debugPrint("📡 sendEmailOtp body: ${response.body}");

      if (_isSuccess(body)) {
        return body['message'] as String? ?? 'Verification code sent.';
      }

      throw body['message'] ?? 'Failed to send code.';
    } catch (e) {
      debugPrint("❌ VendorKYCService.sendEmailOtp: $e");
      rethrow;
    }
  }

  /// POST /api/v1/kyc/email/verify
  /// Submits the 6-digit [code] the vendor received by email.
  ///
  /// Controller validates: required|string|size:6  (field name: "code")
  /// Controller returns:
  ///   { "status": true, "message": "Email verified successfully.", "data": { "progress": 0.33 } }
  ///
  /// Throws on invalid/expired code (422).
  Future<VendorKycStatus> verifyEmail(String code) async {
    _assertOtpFormat(code);

    try {
      final response = await _api.post(
        'kyc/email/verify',
        {'code': code},
        isProtected: true,
        userType: 'vendor',
      );

      debugPrint("✅ verifyEmail status: ${response.statusCode}");
      debugPrint("✅ verifyEmail body: ${response.body}");

      return await _parseVerifyResponse(response, 'verifyEmail');
    } catch (e) {
      debugPrint("❌ VendorKYCService.verifyEmail: $e");
      rethrow;
    }
  }

  // ── Phone ──────────────────────────────────────────────────────────────────

  /// POST /api/v1/kyc/phone/send
  /// Triggers a 6-digit OTP SMS to the vendor's registered phone number.
  ///
  /// Controller returns:
  ///   { "status": true, "message": "SMS code sent to 080XXXXXXXX" }
  ///
  /// Throws if phone not set (422) or already verified (422).
  /// Note: OTP is currently logged server-side (Termii pending sender-ID approval).
  Future<String> sendPhoneOtp() async {
    try {
      final response = await _api.post(
        'kyc/phone/send',
        {},
        isProtected: true,
        userType: 'vendor',
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      debugPrint("📡 sendPhoneOtp status: ${response.statusCode}");
      debugPrint("📡 sendPhoneOtp body: ${response.body}");

      if (_isSuccess(body)) {
        return body['message'] as String? ?? 'SMS code sent.';
      }

      throw body['message'] ?? 'Failed to send SMS verification code.';
    } catch (e) {
      debugPrint("❌ VendorKYCService.sendPhoneOtp: $e");
      rethrow;
    }
  }

  /// POST /api/v1/kyc/phone/verify
  /// Submits the 6-digit [code] the vendor received by SMS.
  ///
  /// Controller validates: required|string|size:6  (field name: "code")
  /// Controller returns:
  ///   { "status": true, "message": "Phone number verified successfully.", "data": { "progress": 0.67 } }
  ///
  /// Throws on invalid/expired code (422).
  Future<VendorKycStatus> verifyPhone(String code) async {
    _assertOtpFormat(code);

    try {
      final response = await _api.post(
        'kyc/phone/verify',
        {'code': code},
        isProtected: true,
        userType: 'vendor',
      );

      debugPrint("✅ verifyPhone status: ${response.statusCode}");
      debugPrint("✅ verifyPhone body: ${response.body}");

      return await _parseVerifyResponse(response, 'verifyPhone');
    } catch (e) {
      debugPrint("❌ VendorKYCService.verifyPhone: $e");
      rethrow;
    }
  }

  // ── Identity (NIN) ─────────────────────────────────────────────────────────

  /// POST /api/v1/kyc/identity/verify
  /// Submits the vendor's NIN and an optional supporting [document] file.
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
  Future<VendorKycStatus> verifyIdentity({
    required String nin,
    File? document,
  }) async {
    _assertNinFormat(nin);

    try {
      late dynamic response;

      if (document != null) {
        // Multipart upload when a supporting document is attached
        response = await _api.upload(
          'kyc/identity/verify',
          {'nin': nin},
          filePath: document.path,
          fileField: 'document',
          isProtected: true,
        );
      } else {
        response = await _api.post(
          'kyc/identity/verify',
          {'nin': nin},
          isProtected: true,
          userType: 'vendor',
        );
      }

      debugPrint("✅ verifyIdentity status: ${response.statusCode}");
      debugPrint("✅ verifyIdentity body: ${response.body}");

      return await _parseVerifyResponse(response, 'verifyIdentity');
    } catch (e) {
      debugPrint("❌ VendorKYCService.verifyIdentity: $e");
      rethrow;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Normalises the status field — handles both boolean `true` and
  /// string `"success"` so this service works regardless of which
  /// envelope style the controller uses.
  bool _isSuccess(Map<String, dynamic> body) {
    final status = body['status'];
    return status == true || status == 'success';
  }

  /// Parses the standard verify response envelope:
  ///   { "status": true, "message": "...", "data": { "progress": 0.67 } }
  ///
  /// Verify endpoints only return { progress } in data, not the full status
  /// object. Re-fetches the full status so the UI stays consistent.
  /// Falls back to a minimal VendorKycStatus built from the progress value
  /// if the re-fetch fails.
  Future<VendorKycStatus> _parseVerifyResponse(
    dynamic response,
    String caller,
  ) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (_isSuccess(body)) {
      try {
        return await getStatus();
      } catch (_) {
        // Re-fetch failed — build a minimal status from the returned progress
        final progress = (body['data']?['progress'] as num?)?.toDouble() ?? 0.0;
        return VendorKycStatus(
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
