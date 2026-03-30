import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/buyer/user_profile_model.dart';

class ProfileService {
  final ApiService _api = ApiService();

  /// GET: buyers/profile
  Future<UserProfile> fetchProfile() async {
    try {
      // FIX: Added userType if your ApiService.get requires it
      final response = await _api.get(
        'buyers/profile',
        isProtected: true,
        userType: 'buyer', // <--- Added this
      );

      debugPrint("DEBUG API RESPONSE: ${response.body}");
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

  /// POST (Multipart): buyers/profile/upload-photo
  Future<UserProfile> uploadAvatar(File imageFile) async {
    try {
      final response = await _api.postMultipart(
        'buyers/profile/upload-photo',
        imageFile,
        'profile_photo',
        isProtected: true,
        userType: 'buyer', // <--- Added this
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

  /// POST: buyers/profile/update
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> body = {};

      // NOTE: Verify if Laravel expects 'name' or 'fullName' in the REQUEST
      if (name != null && name.isNotEmpty) body['fullName'] = name;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;

      if (body.isEmpty) throw "No changes detected to update.";

      final response = await _api.post(
        'buyers/profile/update',
        body,
        isProtected: true,
        userType: 'buyer',
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

  /// DELETE: buyers/profile
  Future<bool> deleteProfile() async {
    try {
      await _api.delete(
        'buyers/profile',
        isProtected: true,
        userType: 'buyer', // <--- Added this
      );
      return true;
    } catch (e) {
      debugPrint("❌ ProfileService Delete Error: $e");
      return false;
    }
  }
}
