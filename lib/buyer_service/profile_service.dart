import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/buyer/user_profile_model.dart';

class ProfileService {
  final ApiService _api = ApiService();

  /// GET: buyers/profile
  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _api.get(
        'buyers/profile',
        isProtected: true,
        userType: 'buyer',
      );

      final decoded = jsonDecode(response.body);
      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;

      return UserProfile.fromJson(profileData);
    } catch (e) {
      debugPrint("❌ ProfileService Fetch Error: $e");
      rethrow;
    }
  }

  /// UPLOAD: buyers/profile/upload-photo
  /// Note: Laravel usually handles file uploads via POST.
  /// If your backend specifically requires PUT for files,
  /// we keep the '_method': 'PUT' spoofing here because multipart is not JSON.
  Future<UserProfile> uploadAvatar(File imageFile) async {
    try {
      final http.Response response = await _api.upload(
        'buyers/profile/upload-photo',
        {'_method': 'PUT'}, // Keep spoofing for Multipart specifically
        filePath: imageFile.path,
        fileField: 'profile_photo',
        isProtected: true,
        userType: 'buyer',
      );

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

  /// PUT: buyers/profile/update
  /// Switched from .post to .put to satisfy backend route requirements
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      // Build the body dynamically
      final Map<String, dynamic> body = {};

      if (name != null && name.isNotEmpty) body['name'] = name;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;

      // Check if we actually have data to send (excluding the old _method field)
      if (body.isEmpty) throw "No changes detected to update.";

      // CRITICAL CHANGE: Using _api.put instead of _api.post
      // This sends a real PUT request with application/json
      final response = await _api.put(
        'buyers/profile/update',
        body,
        isProtected: true,
        userType: 'buyer',
      );

      debugPrint("✅ PROFILE UPDATE SUCCESS: ${response.body}");

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

  /// DELETE: buyers/profile
  Future<bool> deleteProfile() async {
    try {
      await _api.delete('buyers/profile', isProtected: true, userType: 'buyer');
      return true;
    } catch (e) {
      debugPrint("❌ ProfileService Delete Error: $e");
      return false;
    }
  }
}
