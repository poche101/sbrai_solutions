import 'package:flutter/material.dart';
import 'package:sbrai_solutions/buyer/widgets/email_verification.dart';
import 'package:sbrai_solutions/buyer/widgets/phone_verification.dart';
import 'package:sbrai_solutions/buyer/widgets/identity_verification.dart';
import 'package:sbrai_solutions/buyer_service/kyc_service.dart';
import 'package:sbrai_solutions/models/buyer/kyc_status_model.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  final KycService _kycService = KycService();

  // Null while loading, populated after getStatus() resolves
  KycStatus? _status;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await _kycService.getStatus();
      if (mounted) setState(() => _status = status);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navigates to a verification sub-screen and refreshes status on return.
  /// The sub-screens no longer need to return `true` — the service re-fetches
  /// the authoritative status from the server either way.
  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    // Always refresh after returning — even a back-navigation might reflect
    // a step the user completed before closing the screen.
    await _loadStatus();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KYC Verification',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            'Secure your account',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
      // Refresh button — useful when SMS OTP was logged server-side during testing
      actions: [
        if (!_isLoading)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            tooltip: 'Refresh status',
            onPressed: _loadStatus,
          ),
      ],
    );
  }

  Widget _buildBody() {
    // ── Loading state ──────────────────────────────────────────────────────
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFF97316)),
            SizedBox(height: 16),
            Text(
              'Loading verification status…',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ── Error state ────────────────────────────────────────────────────────
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Loaded state ───────────────────────────────────────────────────────
    final status = _status!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProgressCard(status),
        const SizedBox(height: 16),
        _buildVerificationTile(
          icon: Icons.mail_outline,
          title: 'Email Verification',
          subtitle: 'Verify your email address',
          isCompleted: status.emailVerified,
          onTap: () => _navigateAndRefresh(const EmailVerification()),
        ),
        _buildVerificationTile(
          icon: Icons.phone_outlined,
          title: 'Phone Verification',
          subtitle: 'Verify your phone number',
          isCompleted: status.phoneVerified,
          onTap: () => _navigateAndRefresh(const PhoneVerification()),
        ),
        _buildVerificationTile(
          icon: Icons.badge_outlined,
          title: 'Identity Verification',
          subtitle: 'NIN required',
          isCompleted: status.identityVerified,
          onTap: () => _navigateAndRefresh(const IdentityVerification()),
        ),
        const SizedBox(height: 8),
        if (status.isVerified) _buildVerifiedBanner(),
        const SizedBox(height: 8),
        _buildInfoBox(),
      ],
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildProgressCard(KycStatus status) {
    final progress = status.progress;
    final percent = (progress * 100).toInt();
    final isComplete = status.isVerified;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verification Progress',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isComplete ? Colors.green : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Step label from model: "2 / 3 steps complete"
          Text(
            status.progressLabel,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              // Never show fully-empty bar — use 0.05 as minimum visual fill
              value: progress == 0 ? 0.05 : progress,
              backgroundColor: const Color(0xFFFFE4E1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : const Color(0xFFF97316),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        // Completed steps are still tappable so users can re-verify if needed
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _buildCard(
          child: Row(
            children: [
              // Step icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green[50]
                      : const Color(0xFFFFF5F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? Colors.green : const Color(0xFFF97316),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted ? 'Verified ✓' : subtitle,
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Status icon
              Icon(
                isCompleted ? Icons.check_circle : Icons.chevron_right,
                color: isCompleted ? Colors.green : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown when all three steps are complete and is_verified is true.
  Widget _buildVerifiedBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified, color: Colors.green, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account fully verified',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'You now have access to all features.',
                  style: TextStyle(color: Colors.green, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'Why verify your account?',
                style: TextStyle(
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBullet('Build trust with buyers and sellers'),
          _buildBullet('Access premium features'),
          _buildBullet('Get the verified badge'),
          _buildBullet('Secure your transactions'),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
