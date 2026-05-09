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
    final name = (json['full_name'] as String?)?.trim().isNotEmpty == true
        ? json['full_name'] as String
        : (json['name'] as String? ?? '');
    final rawPhoto = (json['photo'] as String?)?.isNotEmpty == true
        ? json['photo'] as String
        : (json['profile_photo'] as String?);
    return UserProfile(
      id:        (json['id'] as num?)?.toInt() ?? 0,
      fullName:  name,
      email:     json['email']   as String? ?? '',
      phone:     json['phone']?.toString() ?? '',
      address:   json['address'] as String? ?? '',
      photoUrl:  (rawPhoto != null && rawPhoto.isNotEmpty) ? rawPhoto : null,
      role:      json['role']    as String? ?? 'buyer',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try { return DateTime.parse(raw.toString()); } catch (_) { return null; }
  }

  String get joinedLabel {
    if (createdAt == null) return '---';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[createdAt!.month - 1]} ${createdAt!.year}';
  }

  String get displayName => fullName.isNotEmpty ? fullName : 'User';

  UserProfile copyWith({
    int? id, String? fullName, String? email, String? phone,
    String? address, String? photoUrl, String? role,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id, fullName: fullName ?? this.fullName,
      email: email ?? this.email, phone: phone ?? this.phone,
      address: address ?? this.address, photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role, createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
