import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/settings_model.dart';
import 'api_service.dart';

class SettingsService {
  final String _baseUrl = "https://sbraisolutions.com/api/v1";
  final ApiService _apiService = ApiService();

  // ── GET /api/v1/settings/notifications ────────────────────────────────────
  // Controller returns: { success: true, data: { notif_new_listings: true, ... } }
  Future<SettingsModel?> fetchSettings() async {
    try {
      final token = await _apiService.getToken(userType: 'buyer');
      if (token == null) {
        debugPrint("⚠️ No buyer token found for fetchSettings");
        return null;
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/settings/notifications'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("📥 fetchSettings STATUS: ${response.statusCode}");
      debugPrint("📥 fetchSettings BODY: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        // Controller always returns { success: true, data: { ... } }
        if (body['success'] == true && body['data'] is Map<String, dynamic>) {
          return SettingsModel.fromJson(body['data'] as Map<String, dynamic>);
        }

        debugPrint("⚠️ fetchSettings: unexpected shape — ${response.body}");
      }

      // 401 = token expired, 422 = validation, anything else = server error
      debugPrint(
        "⚠️ fetchSettings failed [${response.statusCode}]: ${response.body}",
      );
      return null;
    } catch (e) {
      debugPrint("❌ fetchSettings exception: $e");
      return null;
    }
  }

  // ── PATCH /api/v1/settings/notifications ──────────────────────────────────
  // Controller validates 7 optional boolean fields and returns the updated data.
  // Sending only the changed field is enough (partial update via 'sometimes' rule).
  // Returns the fresh SettingsModel from the server so the UI stays in sync.
  Future<SettingsModel?> updateNotificationSettings(
    SettingsModel settings,
  ) async {
    try {
      final token = await _apiService.getToken(userType: 'buyer');
      if (token == null) {
        debugPrint("⚠️ No buyer token found for updateNotificationSettings");
        return null;
      }

      // toJson() maps Dart field names → the 7 backend column names the
      // controller expects: notif_*, privacy_*
      final body = jsonEncode(settings.toJson());
      debugPrint("📤 updateSettings BODY: $body");

      final response = await http
          .patch(
            Uri.parse('$_baseUrl/settings/notifications'),
            headers: _headers(token),
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("📥 updateSettings STATUS: ${response.statusCode}");
      debugPrint("📥 updateSettings BODY: ${response.body}");

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      // 200 → success, controller returns updated data
      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Return the server-confirmed model so the UI reflects what was saved
        if (responseBody['data'] is Map<String, dynamic>) {
          return SettingsModel.fromJson(
            responseBody['data'] as Map<String, dynamic>,
          );
        }
      }

      // 422 → controller returned "No valid settings provided"
      if (response.statusCode == 422) {
        debugPrint("⚠️ updateSettings: ${responseBody['message']}");
        return null;
      }

      debugPrint(
        "⚠️ updateSettings failed [${response.statusCode}]: ${response.body}",
      );
      return null;
    } catch (e) {
      debugPrint("❌ updateSettings exception: $e");
      return null;
    }
  }

  // ── Shared headers ─────────────────────────────────────────────────────────
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
