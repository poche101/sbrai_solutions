import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  // ─────────────────────────────────────────────────────────────
  // CATEGORIES SECTION
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _apiService.get('/categories', isProtected: false);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] is Map) {
        final grouped = data['data'] as Map<String, dynamic>;
        final List<Map<String, dynamic>> loaded = [];

        grouped.forEach((type, list) {
          if (list is List) {
            for (final cat in list) {
              final name = cat['name']?.toString() ?? '';
              final id = cat['id'] as int?;
              final slug = cat['slug']?.toString() ?? '';
              if (name.isNotEmpty && id != null) {
                loaded.add({
                  'id': id,
                  'name': name,
                  'type': type,
                  'slug': slug,
                });
              }
            }
          }
        });
        return loaded;
      }
      return [];
    } catch (e) {
      debugPrint("❌ getCategories error: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FAVORITES SECTION
  // ─────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────
  // FAVORITES SECTION
  // ─────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────
  // FAVORITES SECTION
  // ─────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(int adId) async {
    try {
      final token = await _apiService.getToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = Uri.parse(
        'https://sbraisolutions.com/api/v1/buyers/ads/$adId/favorite',
      );

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Favorite toggled successfully for ad #$adId');
        // You can parse response if backend returns new status
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        debugPrint(
          '❌ Toggle failed: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ toggleFavorite error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final response = await _apiService.get(
        '/buyers/favorites',
        isProtected: true,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ GET Favorites error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LISTING MANAGEMENT (Create, Update, Delete)
  // ─────────────────────────────────────────────────────────────

  /// Create a new ad/listing
  Future<Map<String, dynamic>> createListing({
    required int categoryId,
    required String title,
    required String description,
    required double price,
    required String priceUnit,
    required String location,
    List<File> images = const [],
  }) async {
    try {
      final String urlPath = '/vendor/ads';
      final Map<String, String> fields = {
        'category_id': categoryId.toString(),
        'title': title,
        'description': description,
        'price': price.toString(),
        'price_unit': priceUnit,
        'location': location,
      };

      if (images.isNotEmpty) {
        return await _handleMultipartRequest(
          urlPath: urlPath,
          method: 'POST',
          fields: fields,
          images: images,
        );
      }

      final response = await _apiService.post(
        urlPath,
        fields,
        isProtected: true,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Creation error: $e');
      rethrow;
    }
  }

  /// Update an existing ad/listing
  Future<Map<String, dynamic>> updateListing({
    required int id,
    int? categoryId,
    String? title,
    String? description,
    double? price,
    String? priceUnit,
    String? location,
    List<File>? newImages,
  }) async {
    try {
      final String urlPath = '/vendor/ads/$id';
      final Map<String, String> fields = {};

      if (categoryId != null) fields['category_id'] = categoryId.toString();
      if (title != null) fields['title'] = title;
      if (description != null) fields['description'] = description;
      if (price != null) fields['price'] = price.toString();
      if (priceUnit != null) fields['price_unit'] = priceUnit;
      if (location != null) fields['location'] = location;

      if (newImages != null && newImages.isNotEmpty) {
        return await _handleMultipartRequest(
          urlPath: urlPath,
          method: 'POST', // Backend uses POST for updates with files
          fields: fields,
          images: newImages,
        );
      } else {
        // No new images → simple update
        final response = await _apiService.post(
          urlPath,
          fields,
          isProtected: true,
        );
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('❌ Update error: $e');
      rethrow;
    }
  }

  /// Delete an ad/listing
  Future<Map<String, dynamic>> deleteListing(int id) async {
    try {
      final response = await _apiService.delete('/ads/$id', isProtected: true);
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Delete listing error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FETCHING & FILTERS
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null)
        queryParams['category_id'] = categoryId.toString();

      final queryString = Uri(queryParameters: queryParams).query;
      final response = await _apiService.get(
        '/ads?$queryString',
        isProtected: false,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get ads error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    try {
      final response = await _apiService.get('/ads/$id', isProtected: false);
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get ad error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _handleMultipartRequest({
    required String urlPath,
    required String method,
    required Map<String, String> fields,
    required List<File> images,
  }) async {
    final token = await _apiService.getToken();
    final url = Uri.parse('${ApiService.baseUrl}$urlPath');

    final request = http.MultipartRequest(method, url);
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    // ✅ Backend expects 'images[]' (matches StoreAdRequest validation)
    for (int i = 0; i < images.length && i < 5; i++) {
      final file = images[i];
      request.files.add(
        await http.MultipartFile.fromPath(
          'images[]',
          file.path,
          filename: path.basename(file.path),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw _handleError(response);
    }
  }

  String _handleError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return decoded['message'] ??
            decoded['errors']?.toString() ??
            'Server error';
      }
      return 'Server error: ${response.statusCode}';
    } catch (_) {
      return 'Server error: ${response.statusCode}';
    }
  }
}
