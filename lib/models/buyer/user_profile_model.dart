/// Matches the resource shape returned by BuyerProfileController.profileResource()
///
/// Controller returns:
/// {
///   "id": 1,
///   "full_name": "Jane Doe",        ← primary
///   "name": "Jane Doe",             ← fallback
///   "email": "jane@example.com",
///   "phone": "08012345678",         ← always string
///   "address": "Lagos",
///   "photo": "https://...",         ← primary photo key
///   "profile_photo": "https://...", ← fallback photo key
///   "role": "buyer",
///   "created_at": "2024-01-01T00:00:00+00:00",
///   "updated_at": "2024-01-01T00:00:00+00:00"
/// }

class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String? photoUrl;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.photoUrl,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Name: controller sends both 'full_name' and 'name'; prefer full_name.
    final name = (json['full_name'] as String?)?.trim().isNotEmpty == true
        ? json['full_name'] as String
        : (json['name'] as String? ?? '');

    // Photo: controller sends both 'photo' and 'profile_photo'; prefer photo.
    final rawPhoto = (json['photo'] as String?)?.isNotEmpty == true
        ? json['photo'] as String
        : (json['profile_photo'] as String?);
    final photo = (rawPhoto != null && rawPhoto.isNotEmpty) ? rawPhoto : null;

    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: name,
      email: json['email'] as String? ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address'] as String? ?? '',
      photoUrl: photo,
      role: json['role'] as String? ?? 'buyer',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  /// Human-readable join date, e.g. "Jan 2024"
  String get joinedLabel {
    if (createdAt == null) return '---';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[createdAt!.month - 1]} ${createdAt!.year}';
  }

  /// Display name, never empty.
  String get displayName => fullName.isNotEmpty ? fullName : 'User';

  UserProfile copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'UserProfile(id: $id, fullName: $fullName, email: $email, role: $role)';
}
