import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../api_service.dart';
import 'package:sbrai_solutions/models/vendor/services_model.dart';

class ServiceProvider {
  final ApiService _apiService = ApiService();
  final String _basePath = '/vendor/services';

  /// Fetch valid service categories to avoid the "Invalid Category" error
  Future<List<Map<String, dynamic>>> getServiceCategories() async {
    try {
      final response = await _apiService.get('/service-categories');
      final decoded = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(decoded['data'] ?? []);
    } catch (e) {
      debugPrint('❌ Fetch Categories Error: $e');
      return [];
    }
  }

  /// Create a new Service with Base64 images
  Future<ServiceModel> createService({
    required int categoryId,
    required String title,
    String? description,
    double? price,
    String? priceUnit,
    String? location,
    List<File> images = const [],
  }) async {
    try {
      debugPrint('🛠️ Flutter is attempting to send Category ID: $categoryId');

      // 1. Process Images to Base64
      List<String> base64Images = [];
      for (var file in images) {
        final bytes = await file.readAsBytes();
        String extension = file.path.split('.').last;
        base64Images.add("data:image/$extension;base64,${base64Encode(bytes)}");
      }

      // 2. Prepare Payload
      final Map<String, dynamic> payload = {
        'service_category_id': categoryId,
        'title': title,
        'description': description,
        'price': price,
        'price_unit': priceUnit,
        'location': location,
        'images': base64Images,
      };

      // --- DEBUG LINES ---
      debugPrint('🔴 CATEGORY ID CHECK: $categoryId');
      debugPrint('🔴 PAYLOAD BEING SENT: ${jsonEncode(payload)}');
      // --------------------------

      final response = await _apiService.post(
        _basePath,
        payload,
        isProtected: true,
      );

      debugPrint(
        '📥 Server Response (${response.statusCode}): ${response.body}',
      );

      final decoded = jsonDecode(response.body);
      if (decoded['status'] == true) {
        return ServiceModel.fromJson(decoded['data']);
      } else {
        // --- ENHANCED ERROR LOGGING ---
        if (decoded['error_detail'] != null) {
          debugPrint('‼️ SQL/SERVER ERROR: ${decoded['error_detail']}');
        }

        if (decoded['errors'] != null) {
          debugPrint('🔍 Validation Errors: ${decoded['errors']}');
        }
        // ------------------------------

        throw decoded['message'] ?? 'Failed to create service';
      }
    } catch (e) {
      debugPrint('❌ Create Service Error: $e');
      rethrow;
    }
  }

  /// Get all services
  Future<List<ServiceModel>> getServices() async {
    try {
      final response = await _apiService.get(_basePath, isProtected: true);
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'] ?? [];
      return data.map((item) => ServiceModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('❌ Get Services Error: $e');
      rethrow;
    }
  }

  /// Update service
  Future<void> updateService(int id, Map<String, dynamic> data) async {
    try {
      await _apiService.put('$_basePath/$id', data, isProtected: true);
    } catch (e) {
      debugPrint('❌ Update Service Error: $e');
      rethrow;
    }
  }

  /// Delete service
  Future<void> deleteService(int id) async {
    try {
      await _apiService.delete('$_basePath/$id', isProtected: true);
    } catch (e) {
      debugPrint('❌ Delete Service Error: $e');
      rethrow;
    }
  }
}
