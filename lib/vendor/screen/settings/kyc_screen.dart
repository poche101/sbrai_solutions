// lib/vendor/screens/kyc_screen.dart
import 'package:flutter/material.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/services/vendor/vendor_kyc_service.dart';
import 'package:sbrai_solutions/services/vendor/vendor_auth_service.dart';
import 'package:sbrai_solutions/models/vendor/vendor_kyc_status.dart';
import 'package:sbrai_solutions/vendor/widgets/email_verification.dart';
import 'package:sbrai_solutions/vendor/widgets/phone_verification.dart';
import 'package:sbrai_solutions/vendor/widgets/identity_verification.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  final VendorKYCService _kycService = VendorKYCService(); // ✅ renamed
  final VendorAuthService _authService = VendorAuthService();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _errorMessage;

  VendorKycStatus _status = VendorKycStatus.empty();

  // Real vendor contact info pulled from profile
  String _vendorEmail = '';
  String _vendorPhone = '';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Fetches KYC status and vendor profile in parallel.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _kycService.getStatus(),
        _authService.getProfile(),
      ]);

      final kycStatus = results[0] as VendorKycStatus;
      final profile = results[1] as Map<String, dynamic>;

      // Profile envelope: { "status": "success", "data": { "email": ..., "phone_number": ... } }
      final profileData = profile['data'] as Map<String, dynamic>? ?? profile;

      if (mounted) {
        setState(() {
          _status = kycStatus;
          _vendorEmail = profileData['email']?.toString() ?? '';
          _vendorPhone =
              profileData['phone_number']?.toString() ?? ''; // ✅ fixed key
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  /// Pushes a verification screen, then always refreshes status on return.
  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ); // ✅ removed unused result — always reload

    await _loadData();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.kyc,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              l10n.secureAccount,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState(l10n)
          : _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Progress Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.verificationProgress,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${(_status.progress * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _status.progress == 0 ? 0.05 : _status.progress,
                    backgroundColor: const Color(0xFFFFE4E1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _status.progress >= 1.0
                          ? Colors.green
                          : const Color(0xFFFCA5A5),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Verification Tiles
          _buildVerificationTile(
            icon: Icons.mail_outline,
            title: l10n.emailVerification,
            subtitle: _vendorEmail.isNotEmpty ? _vendorEmail : '—',
            isCompleted: _status.emailVerified,
            onTap: () => _navigateAndRefresh(const EmailVerification()),
          ),
          _buildVerificationTile(
            icon: Icons.phone_outlined,
            title: l10n.phoneVerification,
            subtitle: _vendorPhone.isNotEmpty ? _vendorPhone : '—',
            isCompleted: _status.phoneVerified,
            onTap: () => _navigateAndRefresh(
              PhoneVerification(phoneNumber: _vendorPhone),
              // ✅ fixed parameter name
            ),
          ),
          _buildVerificationTile(
            icon: Icons.badge_outlined,
            title: l10n.identityVerification,
            subtitle: l10n.ninRequired,
            isCompleted: _status.identityVerified,
            onTap: () => _navigateAndRefresh(const IdentityVerification()),
          ),

          const SizedBox(height: 8),

          _buildInfoBox(l10n),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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

  // ── Reusable widgets ───────────────────────────────────────────────────────
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
        onTap: isCompleted ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: _buildCard(
          child: Row(
            children: [
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
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                color: isCompleted ? Colors.green : Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
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

  Widget _buildInfoBox(AppLocalizations l10n) {
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
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.whyVerify,
                style: const TextStyle(
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBullet(l10n.buildTrust),
          _buildBullet(l10n.accessPremium),
          _buildBullet(l10n.verifiedBadge),
          _buildBullet(l10n.secureTransactions),
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
