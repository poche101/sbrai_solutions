import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  // --- FAVORITES SECTION ---

  /// Toggle favorite for an ad.
  /// Backend route: POST /api/v1/ads/{id}/favorite (auth required)
  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    try {
      final response = await _apiService.post(
        '/ads/$productId/favorite',
        {}, // no body needed
        isProtected: true,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Toggle favorite error: $e');
      rethrow;
    }
  }

  /// Get all favorites for the buyer.
  /// Backend route: GET /api/v1/buyers/favorites (auth required)
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

  // --- DYNAMIC LISTING MANAGEMENT (PRODUCTS & SERVICES) ---

  /// Create a new ad (product or service).
  /// Backend route: POST /api/v1/vendor/ads (auth required, vendor only)
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

  /// Update an existing ad.
  /// Backend route: POST /api/v1/vendor/ads/{id} (auth required, vendor only)
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
      final Map<String, String> data = {};

      if (categoryId != null) data['category_id'] = categoryId.toString();
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price.toString();
      if (priceUnit != null) data['price_unit'] = priceUnit;
      if (location != null) data['location'] = location;

      if (newImages != null && newImages.isNotEmpty) {
        // Backend uses POST for multipart updates (no method spoofing needed)
        return await _handleMultipartRequest(
          urlPath: urlPath,
          method: 'POST',
          fields: data,
          images: newImages,
        );
      } else {
        // No images → standard POST (backend may accept fields)
        final response = await _apiService.post(
          urlPath,
          data,
          isProtected: true,
        );
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('❌ Update error: $e');
      rethrow;
    }
  }

  // --- FETCHING & FILTERS ---

  /// Get paginated list of public ads.
  /// Backend route: GET /api/v1/ads (public)
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
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final response = await _apiService.get(
        '/ads?$queryString',
        isProtected: false,               // public route
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get ads error: $e');
      rethrow;
    }
  }

  /// Get a single public ad by ID.
  /// Backend route: GET /api/v1/ads/{id} (public)
  Future<Map<String, dynamic>> getProduct(int id) async {
    try {
      final response = await _apiService.get(
        '/ads/$id',
        isProtected: false,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get ad error: $e');
      rethrow;
    }
  }

  // --- PRIVATE HELPERS ---

  /// Handles multipart image upload for ad creation/update.
  /// Always uses `photos[]` as the file field name (fixed key).
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

    // Attach up to 5 images with the fixed field name
    for (int i = 0; i < images.length && i < 5; i++) {
      final file = images[i];
      request.files.add(
        await http.MultipartFile.fromPath(
          'photos[]',               // <-- fixed field name
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

  /// Converts an HTTP error response into a meaningful string.
  String _handleError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded.containsKey('errors')) return decoded['errors'].toString();
        if (decoded.containsKey('message')) return decoded['message'];
      }
      return 'Server error: ${response.statusCode}';
    } catch (_) {
      return 'Server error: ${response.statusCode}';
    }
  }
}