import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/settings_model.dart';

class SettingsService {
  // Ensure this trailing slash isn't causing double-slashes in your Uri.parse
  final String baseUrl = "https://sbraisolutions.com/api/v1";

  Future<bool> updateNotificationSettings(
    SettingsModel settings,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/buyers/notifications/settings');
    String? fcmToken;

    // 1. Improved FCM handling with a timeout to prevent hanging
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        fcmToken = await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
      }
    } catch (e) {
      debugPrint("FCM Token fetch failed: $e");
    }

    try {
      // 2. Flattening the payload. Laravel often expects the settings
      // at the top level or under a 'preferences' key.
      // We'll keep your structure but ensure it's valid JSON.
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'fcm_token': fcmToken ?? 'no_token',
              ...settings
                  .toJson(), // Spreading the keys at top level is safer for Laravel validation
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          ); // Add a timeout to trigger 'catch' on slow networks

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint("Server rejected settings: ${response.body}");
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } on SocketException catch (e) {
      debugPrint("No Internet connection or server down: $e");
      return false;
    } on HttpException catch (e) {
      debugPrint("Could not find the protocol/route: $e");
      return false;
    } catch (e) {
      debugPrint("Network Error in SettingsService: $e");
      return false;
    }
  }

  Future<SettingsModel?> fetchSettings(String token) async {
    final url = Uri.parse('$baseUrl/buyers/notifications/settings');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Robust parsing to handle Laravel Resource wrappers
        dynamic targetData = responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        if (targetData is Map<String, dynamic>) {
          // Check if nested in 'preferences' or 'settings'
          if (targetData.containsKey('preferences')) {
            return SettingsModel.fromJson(
              targetData['preferences'] as Map<String, dynamic>,
            );
          } else if (targetData.containsKey('settings')) {
            return SettingsModel.fromJson(
              targetData['settings'] as Map<String, dynamic>,
            );
          }
          return SettingsModel.fromJson(targetData);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching settings: $e");
      return null;
    }
  }
}
