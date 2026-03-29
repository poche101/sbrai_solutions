import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// Ensure these paths match your project structure
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/buyer/user_profile_model.dart';

class ProfileService {
  final ApiService _api = ApiService();

  /// GET: v1/buyers/profile
  /// Fetches the authenticated user's profile data.
  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _api.get('/v1/buyers/profile', isProtected: true);

      // DEBUG: This will show you exactly what the server is sending back.
      // Check your console to see if 'full_name' or 'email' are missing or nested.
      debugPrint("DEBUG API RESPONSE: ${response.body}");

      final decoded = jsonDecode(response.body);

      // Laravel Resources usually wrap the object in a 'data' key.
      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;

      return UserProfile.fromJson(profileData);
    } catch (e) {
      debugPrint("❌ ProfileService Fetch Error: $e");
      rethrow;
    }
  }

  /// NEW: POST (Multipart) v1/buyers/profile/upload-photo
  /// This handles the actual File upload from the gallery/camera.
  Future<UserProfile> uploadAvatar(File imageFile) async {
    try {
      final response = await _api.postMultipart(
        '/v1/buyers/profile/upload-photo',
        imageFile,
        'profile_photo', // This key must match Laravel's $request->file('profile_photo')
        isProtected: true,
      );

      debugPrint("DEBUG UPLOAD RESPONSE: ${response.body}");

      final decoded = jsonDecode(response.body);
      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;

      return UserProfile.fromJson(profileData);
    } catch (e) {
      debugPrint("❌ ProfileService Upload Error: $e");
      rethrow;
    }
  }

  /// PUT: v1/buyers/profile/update
  /// Updates text-based profile info.
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> body = {};

      if (name != null && name.isNotEmpty) body['fullName'] = name;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;

      if (body.isEmpty) throw "No changes detected to update.";

      final response = await _api.post(
        '/v1/buyers/profile/update',
        body,
        isProtected: true,
      );

      debugPrint("DEBUG UPDATE RESPONSE: ${response.body}");

      final decoded = jsonDecode(response.body);
      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;

      return UserProfile.fromJson(profileData);
    } catch (e) {
      debugPrint("❌ ProfileService Update Error: $e");
      rethrow;
    }
  }

  /// DELETE: v1/buyers/profile
  Future<bool> deleteProfile() async {
    try {
      await _api.delete('/v1/buyers/profile', isProtected: true);
      return true;
    } catch (e) {
      debugPrint("❌ ProfileService Delete Error: $e");
      return false;
    }
  }
}
