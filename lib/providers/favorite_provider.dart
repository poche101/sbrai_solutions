import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/favorite_item.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  static const String _storageBase = 'https://sbraisolutions.com/storage/';

  List<FavoriteItem> _favorites = [];
  List<FavoriteItem> get favorites => _favorites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Check if an ad is favorited ────────────────────────────────────────────
  bool isFavorite(int adId) =>
      _favorites.any((fav) => fav.id == adId.toString());

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
      debugPrint(
        '📡 First item raw: ${data.isNotEmpty ? jsonEncode(data.first) : "empty"}',
      );

      _favorites = data
          .map((json) {
            final adData = (json['ad'] as Map<String, dynamic>?) ?? {};
            final id = (adData['id'] ?? json['ad_id'])?.toString() ?? '';

            String imageUrl = '';
            final images = adData['images'];
            if (images is List && images.isNotEmpty) {
              final first = images.first;
              if (first is Map) {
                final raw =
                    first['path']?.toString() ?? first['url']?.toString() ?? '';
                if (raw.isNotEmpty) {
                  imageUrl = raw.startsWith('http') ? raw : '$_storageBase$raw';
                }
              } else if (first is String && first.isNotEmpty) {
                imageUrl = first.startsWith('http')
                    ? first
                    : '$_storageBase$first';
              }
            }

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

  // ── Toggle favorite by ad ID (called from HomeScreen / CategoryScreen) ─────
  // POST /api/v1/ads/{adId}/favorite
  Future<void> toggleFavoriteById(int adId) async {
    final idStr = adId.toString();
    final exists = _favorites.any((fav) => fav.id == idStr);

    // Optimistic update
    if (exists) {
      _favorites.removeWhere((fav) => fav.id == idStr);
    } else {
      // Add a placeholder so isFavorite() returns true immediately.
      // The real data will load next time fetchFavorites() is called.
      _favorites.add(FavoriteItem(id: idStr, name: '', price: 0, imageUrl: ''));
    }
    notifyListeners();

    try {
      final response = await _apiService.post(
        'ads/$adId/favorite',
        {},
        isProtected: true,
        userType: 'buyer',
      );

      debugPrint('📡 Toggle favorite status: ${response.statusCode}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['success'] != true &&
          responseData['status'] != 'success') {
        _rollbackById(idStr, exists);
      }
    } catch (e) {
      debugPrint('❌ toggleFavoriteById error: $e');
      _rollbackById(idStr, exists);
    }
  }

  // ── Toggle favorite by FavoriteItem (legacy — kept for compatibility) ──────
  Future<void> toggleFavorite(FavoriteItem item) async {
    final exists = _favorites.any((fav) => fav.id == item.id);

    if (exists) {
      _favorites.removeWhere((fav) => fav.id == item.id);
    } else {
      _favorites.add(item);
    }
    notifyListeners();

    try {
      final response = await _apiService.post(
        'ads/${item.id}/favorite',
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
  // POST /api/v1/ads/{adId}/favorite (toggle removes if already saved)
  Future<void> removeFromFavorites(String id) async {
    final itemIndex = _favorites.indexWhere((fav) => fav.id == id);
    if (itemIndex == -1) return;

    final removed = _favorites[itemIndex];

    _favorites.removeAt(itemIndex);
    notifyListeners();

    try {
      final response = await _apiService.post(
        'ads/$id/favorite',
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

  void _rollbackById(String idStr, bool wasFavoritedBefore) {
    if (wasFavoritedBefore) {
      if (!_favorites.any((fav) => fav.id == idStr)) {
        _favorites.add(
          FavoriteItem(id: idStr, name: '', price: 0, imageUrl: ''),
        );
      }
    } else {
      _favorites.removeWhere((fav) => fav.id == idStr);
    }
    notifyListeners();
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
