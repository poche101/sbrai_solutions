import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/favorite_item.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<FavoriteItem> _favorites = [];
  List<FavoriteItem> get favorites => _favorites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Fetch all favorites ────────────────────────────────────────────────────
  // GET /api/v1/buyers/favorites
  Future<void> fetchFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(
        'buyers/favorites',
        isProtected: true,
        userType: 'buyer',
      );

      debugPrint('📡 Favorites status: ${response.statusCode}');
      debugPrint('📡 Favorites body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final rawList = responseData['data'];
      final List<dynamic> data = rawList is List ? rawList : [];

      _favorites = data
          .map((json) {
            final adData = (json['ad'] as Map<String, dynamic>?) ?? {};
            final id = (adData['id'] ?? json['ad_id'])?.toString() ?? '';
            final imageUrl =
                adData['image_url']?.toString() ??
                adData['image']?.toString() ??
                adData['thumbnail']?.toString() ??
                '';

            return FavoriteItem(
              id: id,
              name:
                  adData['title']?.toString() ??
                  adData['name']?.toString() ??
                  'Unknown Item',
              price: double.tryParse(adData['price']?.toString() ?? '0') ?? 0,
              imageUrl: imageUrl,
            );
          })
          .where((item) => item.id.isNotEmpty)
          .toList();

      debugPrint('✅ Loaded ${_favorites.length} favorites');
    } catch (e) {
      debugPrint('❌ fetchFavorites error: $e');
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Toggle favorite ────────────────────────────────────────────────────────
  // POST /api/v1/buyers/ads/{ad}/favorite
  Future<void> toggleFavorite(FavoriteItem item) async {
    final exists = _favorites.any((fav) => fav.id == item.id);

    // Optimistic update
    if (exists) {
      _favorites.removeWhere((fav) => fav.id == item.id);
    } else {
      _favorites.add(item);
    }
    notifyListeners();

    try {
      final response = await _apiService.post(
        'buyers/ads/${item.id}/favorite',
        {},
        isProtected: true,
        userType: 'buyer',
      );

      debugPrint('📡 Toggle favorite status: ${response.statusCode}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['success'] != true &&
          responseData['status'] != 'success') {
        _rollbackLocalState(item, exists);
      }
    } catch (e) {
      debugPrint('❌ toggleFavorite error: $e');
      _rollbackLocalState(item, exists);
    }
  }

  // ── Remove favorite by id ──────────────────────────────────────────────────
  // POST /api/v1/buyers/ads/{adId}/favorite (toggle removes if already saved)
  Future<void> removeFromFavorites(String id) async {
    final itemIndex = _favorites.indexWhere((fav) => fav.id == id);
    if (itemIndex == -1) return;

    final removed = _favorites[itemIndex];

    // Optimistic remove
    _favorites.removeAt(itemIndex);
    notifyListeners();

    try {
      final response = await _apiService.post(
        'buyers/ads/$id/favorite',
        {},
        isProtected: true,
        userType: 'buyer',
      );

      debugPrint('📡 Remove favorite status: ${response.statusCode}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['success'] != true &&
          responseData['status'] != 'success') {
        _favorites.insert(itemIndex, removed);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ removeFromFavorites error: $e');
      _favorites.insert(itemIndex, removed);
      notifyListeners();
    }
  }

  void _rollbackLocalState(FavoriteItem item, bool wasFavoritedBefore) {
    if (wasFavoritedBefore) {
      if (!_favorites.any((fav) => fav.id == item.id)) {
        _favorites.add(item);
      }
    } else {
      _favorites.removeWhere((fav) => fav.id == item.id);
    }
    notifyListeners();
  }

  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }
}
