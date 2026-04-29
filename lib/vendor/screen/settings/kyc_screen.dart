import 'package:flutter/material.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
// import '../../../l10n/app_localizations.dart';
// Ensure these paths match your actual project structure
import 'package:sbrai_solutions/vendor/widgets/email_verification.dart';
import 'package:sbrai_solutions/vendor/widgets/phone_verification.dart';
import 'package:sbrai_solutions/vendor/widgets/identity_verification.dart';
// BUSINESS VERIFICATION COMMENTED OUT - Will be re-enabled later
// import 'package:sbrai_solutions/vendor/widgets/business_verification.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  // Dynamic State: Tracking which steps are verified
  bool isEmailVerified = false;
  bool isPhoneVerified = false;
  bool isIdentityVerified = false;
  // BUSINESS VERIFICATION COMMENTED OUT
  // bool isBusinessVerified = false;

  // Logic to calculate progress percentage (updated for 3 items instead of 4)
  double get _calculationProgress {
    int completed = 0;
    if (isEmailVerified) completed++;
    if (isPhoneVerified) completed++;
    if (isIdentityVerified) completed++;
    // if (isBusinessVerified) completed++; // COMMENTED OUT
    return completed / 3; // Changed from 4 to 3
  }

  /// Helper method to navigate and update state on return
  /// Expects the verification screens to return 'true' upon success
  Future<void> _navigateAndVerify(Widget screen, String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (result == true) {
      setState(() {
        switch (type) {
          case 'email':
            isEmailVerified = true;
            break;
          case 'phone':
            isPhoneVerified = true;
            break;
          case 'identity':
            isIdentityVerified = true;
            break;
        // BUSINESS VERIFICATION COMMENTED OUT
        // case 'business':
        //   isBusinessVerified = true;
        //   break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double progress = _calculationProgress;

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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Dynamic Progress Card
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
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress == 0 ? 0.05 : progress,
                    backgroundColor: const Color(0xFFFFE4E1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : const Color(0xFFFCA5A5),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Verification Items
          _buildVerificationTile(
            icon: Icons.mail_outline,
            title: l10n.emailVerification,
            subtitle: 'vendor@demo.com',
            isCompleted: isEmailVerified,
            onTap: () => _navigateAndVerify(const EmailVerification(), 'email'),
          ),
          _buildVerificationTile(
            icon: Icons.phone_outlined,
            title: l10n.phoneVerification,
            subtitle: '08087654321',
            isCompleted: isPhoneVerified,
            onTap: () => _navigateAndVerify(const PhoneVerification(), 'phone'),
          ),
          _buildVerificationTile(
            icon: Icons.badge_outlined,
            title: l10n.identityVerification,
            subtitle: l10n.ninRequired, // Changed from "NIN or BVN required" to "NIN required"
            isCompleted: isIdentityVerified,
            onTap: () =>
                _navigateAndVerify(const IdentityVerification(), 'identity'),
          ),

          // BUSINESS VERIFICATION COMMENTED OUT
          // _buildVerificationTile(
          //   icon: Icons.apartment_outlined,
          //   title: l10n.businessVerification,
          //   subtitle: l10n.businessVerificationRequired,
          //   isCompleted: isBusinessVerified,
          //   onTap: () =>
          //       _navigateAndVerify(const BusinessVerification(), 'business'),
          // ),

          const SizedBox(height: 8),

          // Info Box
          _buildInfoBox(l10n),
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
              const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
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