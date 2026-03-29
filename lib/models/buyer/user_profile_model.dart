import 'package:intl/intl.dart';

class UserProfile {
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String joinDate;
  final String? photoUrl;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.joinDate,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Check for a nested user object just in case
    final Map<String, dynamic> userRel = json['user'] is Map
        ? json['user']
        : {};

    return UserProfile(
      // FIX: Changed from 'full_name' to 'fullName' to match your API
      fullName:
          json['fullName'] ?? json['name'] ?? userRel['name'] ?? 'Guest User',

      // Email is already working, but we keep the fallback
      email: json['email'] ?? userRel['email'] ?? 'No email provided',

      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',

      // FIX: Your API already provides "joinDate": "Mar 2026",
      // so we can use it directly or fall back to our parser.
      joinDate: json['joinDate'] ?? _parseDate(json['created_at']),

      // FIX: Changed from 'profile_photo' to 'photo' to match your API
      photoUrl: json['photo'] != null
          ? "https://sbraisolutions.com/storage/${json['photo']}"
          : null,
    );
  }

  /// Helper to handle date parsing safely
  static String _parseDate(dynamic dateValue) {
    if (dateValue == null) return "Joined recently";
    try {
      DateTime dt = DateTime.parse(dateValue.toString());
      return DateFormat('MMM yyyy').format(dt);
    } catch (e) {
      return "N/A";
    }
  }
}
