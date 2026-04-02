import 'package:intl/intl.dart';

class UserProfile {
  String fullName;
  String email;
  String phone;
  String address;
  String joinDate;
  String? photoUrl;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.joinDate,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Laravel/API usually nests data in a 'data' or 'user' key
    final userData = json['data'] ?? json['user'] ?? json;

    // 1. Handle Date Formatting
    String formattedDate = "Recently";
    dynamic rawDate =
        userData['created_at'] ?? userData['joinDate'] ?? json['created_at'];

    if (rawDate != null) {
      try {
        String dateStr = rawDate.toString();
        // If the API already sends "Mar 2026", use it. Otherwise, parse it.
        if (dateStr.contains(RegExp(r'[a-zA-Z]'))) {
          formattedDate = dateStr;
        } else {
          DateTime dt = DateTime.parse(dateStr);
          formattedDate = DateFormat('MMM yyyy').format(dt);
        }
      } catch (e) {
        formattedDate = "Date Error";
      }
    }

    // 2. Handle Profile Photo Path (DEEP SEARCH)
    // We check every possible key the backend might use to be safe
    String? profilePhoto =
        userData['photo'] ??
        userData['profile_photo'] ??
        userData['image'] ??
        json['photo'];

    String? fullPhotoUrl;
    if (profilePhoto != null && profilePhoto.toString().isNotEmpty) {
      String photoPath = profilePhoto.toString();

      // If the API already provides a full URL, use it.
      if (photoPath.startsWith('http')) {
        fullPhotoUrl = photoPath;
      } else {
        // Clean the path (remove leading slashes)
        String cleanPath = photoPath.startsWith('/')
            ? photoPath.substring(1)
            : photoPath;

        // PREVENT DOUBLE STORAGE: If path already has 'storage/', remove it
        // before we add our own base URL.
        if (cleanPath.startsWith('storage/')) {
          cleanPath = cleanPath.replaceFirst('storage/', '');
        }

        fullPhotoUrl = "https://sbraisolutions.com/storage/$cleanPath";
      }
    }

    return UserProfile(
      // Ensure we check all possible name keys (fullName vs name)
      fullName:
          userData['fullName'] ??
          userData['full_name'] ??
          userData['name'] ??
          'User',
      email: userData['email'] ?? 'Not provided',
      // Convert to string in case the API sends numbers
      phone: userData['phone']?.toString() ?? '',
      address: userData['address']?.toString() ?? '',
      joinDate: formattedDate,
      photoUrl: fullPhotoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {'full_name': fullName, 'phone': phone, 'address': address};
  }
}
