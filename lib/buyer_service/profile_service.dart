import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/buyer/user_profile_model.dart';

class ProfileService {
  final ApiService _api;
  ProfileService({ApiService? api}) : _api = api ?? ApiService();

  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _api.getBuyerProfile();
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        await _api.saveUserData(data);
        return UserProfile.fromJson(data);
      }
      throw body['message'] ?? 'Failed to load profile.';
    } catch (e) {
      debugPrint("❌ ProfileService.fetchProfile: $e");
      rethrow;
    }
  }

  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (phone != null) payload['phone'] = phone;
    if (address != null) payload['address'] = address;
    if (payload.isEmpty) throw 'Provide at least one field to update.';
    try {
      final response = await _api.updateBuyerProfile(payload);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        await _api.saveUserData(data);
        return UserProfile.fromJson(data);
      }
      throw body['message'] ?? 'Profile update failed.';
    } catch (e) {
      debugPrint("❌ ProfileService.updateProfile: $e");
      rethrow;
    }
  }

  Future<UserProfile> uploadPhoto(File imageFile) async {
    try {
      final response = await _api.uploadBuyerPhoto(imageFile);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        await _api.saveUserData(data);
        return UserProfile.fromJson(data);
      }
      throw body['message'] ?? 'Photo upload failed.';
    } catch (e) {
      debugPrint("❌ ProfileService.uploadPhoto: $e");
      rethrow;
    }
  }

  Future<UserProfile> uploadAvatar(File imageFile) => uploadPhoto(imageFile);
}
