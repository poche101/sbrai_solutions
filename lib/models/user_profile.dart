import 'package:intl/intl.dart';

class UserProfile {
  String fullName;
  String email;
  String phone;
  String address;
  String joinDate;
  String? photoUrl; // Added to handle the profile image path

  UserProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.joinDate,
    this.photoUrl,
  });

  /// --- FACTORY CONSTRUCTOR ---
  /// Converts the JSON Map from your API into a UserProfile object.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Laravel often nests core user data (email, etc.) under a 'user' key
    final userData = json['user'] ?? {};

    // 1. Handle Date Formatting
    String formattedDate = "Joined recently";
    String? rawDate = json['created_at'] ?? userData['created_at'];
    if (rawDate != null) {
      try {
        DateTime dt = DateTime.parse(rawDate);
        formattedDate = DateFormat('MMM yyyy').format(dt);
      } catch (e) {
        formattedDate = "N/A";
      }
    }

    // 2. Handle Profile Photo Path
    // Adjust the base URL to match your Ubuntu server storage link
    String? profilePhoto = json['profile_photo'] ?? userData['profile_photo'];
    String? fullPhotoUrl;
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      fullPhotoUrl = "https://sbraisolutions.com/storage/$profilePhoto";
    }

    return UserProfile(
      // Priority: profile table full_name -> user table name -> default 'User'
      fullName: json['full_name'] ?? userData['name'] ?? 'User',
      email: userData['email'] ?? json['email'] ?? 'Not provided',
      phone: json['phone'] ?? userData['phone'] ?? '',
      address: json['address'] ?? userData['address'] ?? '',
      joinDate: formattedDate,
      photoUrl: fullPhotoUrl,
    );
  }

  /// --- HELPER FOR UPDATES ---
  /// Converts the object back to a Map for API PUT requests
  Map<String, dynamic> toJson() {
    return {'full_name': fullName, 'phone': phone, 'address': address};
  }
}
