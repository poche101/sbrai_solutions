import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  /// Create a product with images
  Future<Map<String, dynamic>> createProduct({
    required int categoryId,
    required String title,
    required String description,
    required double price,
    required String priceUnit,
    required String location,
    List<File> images = const [],
  }) async {
    try {
      if (images.isEmpty) {
        final response = await _apiService.post('/vendor/products', {
          'category_id': categoryId,
          'title': title,
          'description': description,
          'price': price,
          'price_unit': priceUnit,
          'location': location,
        }, isProtected: true);

        return jsonDecode(response.body);
      }

      // Handle Multipart for creation
      return await _handleMultipartRequest(
        urlPath: '/vendor/products',
        method: 'POST',
        fields: {
          'category_id': categoryId.toString(),
          'title': title,
          'description': description,
          'price': price.toString(),
          'price_unit': priceUnit,
          'location': location,
        },
        images: images,
      );
    } catch (e) {
      debugPrint('❌ Product creation error: $e');
      rethrow;
    }
  }

  /// Update an existing product
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    int? categoryId,
    String? title,
    String? description,
    double? price,
    String? priceUnit,
    String? location,
    List<File>? newImages,
  }) async {
    try {
      final Map<String, String> data = {};

      if (categoryId != null) data['category_id'] = categoryId.toString();
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price.toString();
      if (priceUnit != null) data['price_unit'] = priceUnit;
      if (location != null) data['location'] = location;

      if (newImages != null && newImages.isNotEmpty) {
        // Laravel Method Spoofing: Use POST with _method=PUT for multipart updates
        data['_method'] = 'PUT';
        return await _handleMultipartRequest(
          urlPath: '/vendor/products/$productId',
          method: 'POST',
          fields: data,
          images: newImages,
        );
      } else {
        // Simple PUT without images
        final response = await _apiService.put(
          '/vendor/products/$productId',
          data,
          isProtected: true,
        );
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('❌ Product update error: $e');
      rethrow;
    }
  }

  // --- FAVORITES SECTION ---

  /// Toggle favorite status (Add/Remove)
  /// Hits your Laravel FavoriteController@toggle
  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    try {
      final response = await _apiService.post('/buyer/favorites/toggle', {
        'product_id': productId,
      }, isProtected: true);

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Toggle favorite error: $e');
      rethrow;
    }
  }

  /// Get all favorite items for the user
  /// Hits your Laravel FavoriteController@index
  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final response = await _apiService.get(
        '/buyer/favorites',
        isProtected: true,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get favorites error: $e');
      rethrow;
    }
  }

  // --- FETCHING & FILTERS ---

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int perPage = 10,
    String? state,
    String? search,
    String? category,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (state != null) queryParams['state'] = state;
      if (search != null) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;

      final queryString = Uri(queryParameters: queryParams).query;
      final response = await _apiService.get(
        '/vendor/products?$queryString',
        isProtected: true,
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get products error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    try {
      final response = await _apiService.get(
        '/vendor/products/$id',
        isProtected: true,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get product error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int id) async {
    try {
      final response = await _apiService.delete(
        '/vendor/products/$id',
        isProtected: true,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Delete product error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _apiService.get(
        '/vendor/categories',
        isProtected: false,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get categories error: $e');
      rethrow;
    }
  }

  // --- PRIVATE HELPERS ---

  /// Helper to handle complex Multipart requests
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

    // Add Text Fields
    request.fields.addAll(fields);

    // Add Images
    for (int i = 0; i < images.length && i < 5; i++) {
      final file = images[i];
      request.files.add(
        await http.MultipartFile.fromPath(
          'photos[$i]',
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
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'];
      }
      return 'Server error: ${response.statusCode}';
    } catch (_) {
      return 'Server error: ${response.statusCode}';
    }
  }
}
