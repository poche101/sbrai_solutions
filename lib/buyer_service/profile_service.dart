import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/buyer/user_profile_model.dart';

/// Service layer for all buyer-profile API calls.
/// Every method returns a [UserProfile] so callers never touch raw JSON.
class ProfileService {
  final ApiService _api;

  ProfileService({ApiService? api}) : _api = api ?? ApiService();

  // ── GET /api/v1/buyers/profile ─────────────────────────────────────────────
  /// Fetches the current buyer's profile, caches it locally, and returns a
  /// typed [UserProfile]. Throws a [String] message on failure.
  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _api.getBuyerProfile();
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        await _api.saveUserData(data); // keep SharedPreferences in sync
        return UserProfile.fromJson(data);
      }

      throw body['message'] ?? 'Failed to load profile.';
    } catch (e) {
      debugPrint("❌ ProfileService.fetchProfile: $e");
      rethrow;
    }
  }

  // ── PUT /api/v1/buyers/profile/update ─────────────────────────────────────
  /// Sends only the provided (non-null) fields. At least one must be given.
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

  // ── POST /api/v1/buyers/profile/upload-photo ──────────────────────────────
  /// Uploads [imageFile] as the new profile photo and returns the updated
  /// [UserProfile]. Accepted: jpeg, jpg, png, webp — max 5 MB.
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

  /// Alias used by [BuyersMenu] — delegates to [uploadPhoto].
  Future<UserProfile> uploadAvatar(File imageFile) => uploadPhoto(imageFile);

  // ── Local cache ────────────────────────────────────────────────────────────
  /// Returns a [UserProfile] built from the locally cached
  /// [SharedPreferences] values — no network call. Returns null if the
  /// cache is empty (first launch, cleared session, etc.).
  Future<UserProfile?> getCachedProfile() async {
    final data = await _api.getUserData();
    final name = data['name'] ?? '';
    final email = data['email'] ?? '';
    if (name.isEmpty && email.isEmpty) return null;
    return UserProfile(
      id: 0,
      fullName: name,
      email: email,
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      photoUrl: data['photo'],
      role: 'buyer',
    );
  }
}
