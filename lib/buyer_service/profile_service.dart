import 'dart:convert';
import 'package:flutter/foundation.dart';
// Ensure you import your ApiService file here
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/buyer/user_profile_model.dart';

class ProfileService {
  final ApiService _api = ApiService();

  /// GET: v1/buyers/profile
  /// Fetches the authenticated user's profile data.
  Future<UserProfile> fetchProfile() async {
    try {
      // ApiService handles baseUrl, headers, and token injection automatically
      final response = await _api.get('/v1/buyers/profile', isProtected: true);

      final decoded = jsonDecode(response.body);

      // Laravel Resources wrap everything in a 'data' key
      if (decoded.containsKey('data')) {
        return UserProfile.fromJson(decoded['data']);
      } else {
        return UserProfile.fromJson(decoded);
      }
    } catch (e) {
      debugPrint("❌ ProfileService Fetch Error: $e");
      // This will now throw the actual error string from ApiService
      rethrow;
    }
  }

  /// PUT: v1/buyers/profile/1
  /// Updates the profile using JSON/Base64.
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? base64Photo,
  }) async {
    try {
      // Build the payload dynamically to avoid sending nulls (prevents 500 errors)
      final Map<String, dynamic> body = {};

      if (name != null && name.isNotEmpty) body['fullName'] = name;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;
      if (base64Photo != null && base64Photo.isNotEmpty)
        body['photo'] = base64Photo;

      if (body.isEmpty) throw "No changes detected to update.";

      // Use the PUT method from ApiService
      final response = await _api.put(
        '/v1/buyers/profile/1',
        body,
        isProtected: true,
      );

      final decoded = jsonDecode(response.body);
      return UserProfile.fromJson(decoded['data'] ?? decoded);
    } catch (e) {
      debugPrint("❌ ProfileService Update Error: $e");
      rethrow;
    }
  }

  /// DELETE: v1/buyers/profile/1
  /// Clears profile data and deletes the profile photo from storage.
  Future<bool> deleteProfile() async {
    try {
      await _api.delete('/v1/buyers/profile/1', isProtected: true);
      return true;
    } catch (e) {
      debugPrint("❌ ProfileService Delete Error: $e");
      return false;
    }
  }
}
