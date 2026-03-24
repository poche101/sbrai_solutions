
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://sbraisolutions.com';

  Future<Map<String, dynamic>> registerVendor({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String nin,
    required String address,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/vendor/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': name,
          'email': email,
          'phone_number': phone,
          'business_name': businessName,
          'nin': nin,
          'business_address': address,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}