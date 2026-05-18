// lib/models/vendor/vendor_kyc_status_model.dart

class VendorKycStatus {
  final bool emailVerified;
  final bool phoneVerified;
  final bool identityVerified;
  final bool isVerified;
  final double progress;

  const VendorKycStatus({
    required this.emailVerified,
    required this.phoneVerified,
    required this.identityVerified,
    required this.isVerified,
    required this.progress,
  });

  factory VendorKycStatus.fromJson(Map<String, dynamic> json) {
    return VendorKycStatus(
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      identityVerified: json['identity_verified'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Returns a zeroed-out status — useful as an initial state before
  /// the first [VendorKycService.getStatus] call resolves.
  factory VendorKycStatus.empty() => const VendorKycStatus(
    emailVerified: false,
    phoneVerified: false,
    identityVerified: false,
    isVerified: false,
    progress: 0.0,
  );

  VendorKycStatus copyWith({
    bool? emailVerified,
    bool? phoneVerified,
    bool? identityVerified,
    bool? isVerified,
    double? progress,
  }) {
    return VendorKycStatus(
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      identityVerified: identityVerified ?? this.identityVerified,
      isVerified: isVerified ?? this.isVerified,
      progress: progress ?? this.progress,
    );
  }

  @override
  String toString() =>
      'VendorKycStatus(email: $emailVerified, phone: $phoneVerified, '
      'identity: $identityVerified, verified: $isVerified, progress: $progress)';
}
