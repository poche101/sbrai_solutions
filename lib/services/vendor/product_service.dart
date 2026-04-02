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
      // Check if we have images to upload
      if (images.isEmpty) {
        // Simple POST without images
        final response = await _apiService.post(
          '/vendor/products',
          {
            'category_id': categoryId,
            'title': title,
            'description': description,
            'price': price,
            'price_unit': priceUnit,
            'location': location,
          },
          isProtected: true,
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      }

      // With images - using multipart request
      final token = await _apiService.getToken();
      final url = Uri.parse('${ApiService.baseUrl}/vendor/products');

      final request = http.MultipartRequest('POST', url);
      request.headers['Accept'] = 'application/json';

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add fields
      request.fields['category_id'] = categoryId.toString();
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['price_unit'] = priceUnit;
      request.fields['location'] = location;

      // Add images (max 5)
      for (int i = 0; i < images.length && i < 5; i++) {
        final file = images[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        final multipartFile = http.MultipartFile(
          'photos[$i]',  // Backend expects array format
          stream,
          length,
          filename: path.basename(file.path),
        );

        request.files.add(multipartFile);
      }

      debugPrint('🚀 UPLOAD: $url');
      debugPrint('📦 Fields: ${request.fields}');
      debugPrint('📷 Files: ${request.files.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw _handleError(response);
      }

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
      final data = <String, dynamic>{};

      if (categoryId != null) data['category_id'] = categoryId;
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (priceUnit != null) data['price_unit'] = priceUnit;
      if (location != null) data['location'] = location;

      // If we have new images to upload
      if (newImages != null && newImages.isNotEmpty) {
        final token = await _apiService.getToken();
        final url = Uri.parse('${ApiService.baseUrl}/vendor/products/$productId');

        final request = http.MultipartRequest('POST', url);
        request.headers['Accept'] = 'application/json';

        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Add fields
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        // Add images (max 5)
        for (int i = 0; i < newImages.length && i < 5; i++) {
          final file = newImages[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();

          final multipartFile = http.MultipartFile(
            'photos[$i]',
            stream,
            length,
            filename: path.basename(file.path),
          );

          request.files.add(multipartFile);
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          return responseData;
        } else {
          throw _handleError(response);
        }
      } else {
        // Simple PUT without images
        final response = await _apiService.put(
          '/vendor/products/$productId',
          data,
          isProtected: true,
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      }

    } catch (e) {
      debugPrint('❌ Product update error: $e');
      rethrow;
    }
  }

  /// Get all products for the vendor
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/vendor/products?page=$page&per_page=$perPage',
        isProtected: true,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      debugPrint('❌ Get products error: $e');
      rethrow;
    }
  }

  /// Get a single product by ID
  Future<Map<String, dynamic>> getProduct(int id) async {
    try {
      final response = await _apiService.get(
        '/vendor/products/$id',
        isProtected: true,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      debugPrint('❌ Get product error: $e');
      rethrow;
    }
  }

  /// Delete a product
  Future<Map<String, dynamic>> deleteProduct(int id) async {
    try {
      final response = await _apiService.delete(
        '/vendor/products/$id',
        isProtected: true,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      debugPrint('❌ Delete product error: $e');
      rethrow;
    }
  }

  /// Get product categories
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _apiService.get(
        '/vendor/categories',
        isProtected: false,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      debugPrint('❌ Get categories error: $e');
      rethrow;
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