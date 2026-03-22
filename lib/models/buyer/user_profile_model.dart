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
    // 1. Safely handle the nested user object
    final Map<String, dynamic> userRel = json['user'] is Map
        ? json['user']
        : {};

    // 2. Format the date (e.g., "2026-03-22" -> "Mar 2026")
    String formattedDate = "Joined recently";
    if (json['created_at'] != null) {
      try {
        DateTime dt = DateTime.parse(json['created_at']);
        formattedDate = DateFormat('MMM yyyy').format(dt);
      } catch (e) {
        formattedDate = "N/A";
      }
    }

    return UserProfile(
      // Access 'full_name' from profile, fall back to user 'name', then empty string
      fullName: json['full_name'] ?? userRel['name'] ?? 'Guest User',

      // Access email from the nested user relationship
      email: userRel['email'] ?? 'No email provided',

      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      joinDate: formattedDate,

      // Use the absolute URL if your Resource provides it,
      // otherwise prepend your storage base URL
      photoUrl: json['profile_photo'] != null
          ? "https://sbraisolutions.com/storage/${json['profile_photo']}"
          : null,
    );
  }
}
