/// Matches the response shape from KycController.status()
///
/// {
///   "status": true,
///   "data": {
///     "email_verified":    false,
///     "phone_verified":    false,
///     "identity_verified": false,
///     "is_verified":       false,
///     "progress":          0.0    ← 0.0 – 1.0 (rounded to 2 dp)
///   }
/// }
class KycStatus {
  final bool emailVerified;
  final bool phoneVerified;
  final bool identityVerified;
  final bool isVerified;

  /// Overall progress as a fraction: 0.0, 0.33, 0.67, or 1.0.
  /// Mirrors KycController::calculateProgress() — completed / 3.
  final double progress;

  const KycStatus({
    required this.emailVerified,
    required this.phoneVerified,
    required this.identityVerified,
    required this.isVerified,
    required this.progress,
  });

  factory KycStatus.fromJson(Map<String, dynamic> json) {
    return KycStatus(
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      identityVerified: json['identity_verified'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Steps completed out of 3.
  int get completedSteps => (progress * 3).round();

  /// Human-readable progress label, e.g. "2 / 3 steps complete".
  String get progressLabel => '$completedSteps / 3 steps complete';

  /// Returns an updated copy after a successful verification step.
  KycStatus copyWith({
    bool? emailVerified,
    bool? phoneVerified,
    bool? identityVerified,
    bool? isVerified,
    double? progress,
  }) {
    return KycStatus(
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      identityVerified: identityVerified ?? this.identityVerified,
      isVerified: isVerified ?? this.isVerified,
      progress: progress ?? this.progress,
    );
  }

  @override
  String toString() =>
      'KycStatus(email: $emailVerified, phone: $phoneVerified, '
      'identity: $identityVerified, verified: $isVerified, progress: $progress)';
}
