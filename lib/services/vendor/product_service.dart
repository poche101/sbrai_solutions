import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  // --- FAVORITES SECTION ---

  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    try {
      final response = await _apiService.post('/v1/buyers/favorites/toggle', {
        'product_id': productId,
      }, isProtected: true);

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Toggle favorite error: $e');
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
      debugPrint('❌ GET ERROR [/v1/buyers/favorites]: $e');
      rethrow;
    }
  }

  // --- DYNAMIC LISTING MANAGEMENT (PRODUCTS & SERVICES) ---

  /// Create a listing (Product or Service)
  Future<Map<String, dynamic>> createListing({
    required String type, // 'Product' or 'Service'
    required int categoryId,
    required String title,
    required String description,
    required double price,
    required String priceUnit,
    required String location,
    List<File> images = const [],
  }) async {
    try {
      // 1. Determine dynamic keys based on type
      final bool isService = type.toLowerCase() == 'service';
      final String urlPath = isService
          ? '/vendor/services'
          : '/vendor/products';
      final String categoryKey = isService
          ? 'service_category_id'
          : 'category_id';
      final String photoKey = isService ? 'images[]' : 'photos[]';

      final Map<String, String> fields = {
        categoryKey: categoryId.toString(),
        'title': title,
        'description': description,
        'price': price.toString(),
        'price_unit': priceUnit,
        'location': location,
      };

      // 2. Route to Multipart if images exist, otherwise standard POST
      if (images.isNotEmpty) {
        return await _handleMultipartRequest(
          urlPath: urlPath,
          method: 'POST',
          fields: fields,
          images: images,
          photoKey: photoKey,
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

  /// Update an existing listing
  Future<Map<String, dynamic>> updateListing({
    required int id,
    required String type,
    int? categoryId,
    String? title,
    String? description,
    double? price,
    String? priceUnit,
    String? location,
    List<File>? newImages,
  }) async {
    try {
      final bool isService = type.toLowerCase() == 'service';
      final String urlPath = isService
          ? '/vendor/services/$id'
          : '/vendor/products/$id';
      final String categoryKey = isService
          ? 'service_category_id'
          : 'category_id';
      final String photoKey = isService ? 'images[]' : 'photos[]';

      final Map<String, String> data = {};
      if (categoryId != null) data[categoryKey] = categoryId.toString();
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price.toString();
      if (priceUnit != null) data['price_unit'] = priceUnit;
      if (location != null) data['location'] = location;

      if (newImages != null && newImages.isNotEmpty) {
        data['_method'] = 'PUT'; // Laravel Method Spoofing
        return await _handleMultipartRequest(
          urlPath: urlPath,
          method: 'POST',
          fields: data,
          images: newImages,
          photoKey: photoKey,
        );
      } else {
        final response = await _apiService.put(
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
        '/v1/vendor/products/$id',
        isProtected: true,
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Get product error: $e');
      rethrow;
    }
  }

  // --- PRIVATE HELPERS ---

  Future<Map<String, dynamic>> _handleMultipartRequest({
    required String urlPath,
    required String method,
    required Map<String, String> fields,
    required List<File> images,
    required String photoKey,
  }) async {
    final token = await _apiService.getToken();
    final url = Uri.parse('${ApiService.baseUrl}$urlPath');

    final request = http.MultipartRequest(method, url);
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    for (int i = 0; i < images.length && i < 5; i++) {
      final file = images[i];
      request.files.add(
        await http.MultipartFile.fromPath(
          photoKey, // Uses 'photos[]' or 'images[]' dynamically
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
        // Return validation errors if they exist, otherwise the message
        if (decoded.containsKey('errors')) return decoded['errors'].toString();
        if (decoded.containsKey('message')) return decoded['message'];
      }
      return 'Server error: ${response.statusCode}';
    } catch (_) {
      return 'Server error: ${response.statusCode}';
    }
  }
}
