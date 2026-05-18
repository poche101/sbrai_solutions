// lib/vendor/widgets/email_verification.dart
import 'package:flutter/material.dart';
import 'package:sbrai_solutions/services/vendor/vendor_kyc_service.dart';
import 'package:sbrai_solutions/services/vendor/vendor_auth_service.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  final VendorKYCService _kycService = VendorKYCService();
  final VendorAuthService _authService = VendorAuthService();

  String? _email;
  bool _isLoadingEmail = true;
  bool _isSending = false;
  bool _codeSent = false;
  bool _isVerifying = false;
  String? _errorMessage;

  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVendorEmail();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorEmail() async {
    setState(() => _isLoadingEmail = true);

    try {
      final profile = await _authService.getProfile();
      debugPrint("📋 Vendor Profile Response: $profile");

      // Handle nested envelope: { "data": { "email": ... } } or flat { "email": ... }
      final String? email =
          profile['email']?.toString() ??
          profile['data']?['email']?.toString() ??
          profile['user']?['email']?.toString() ??
          profile['data']?['user']?['email']?.toString();

      if (mounted) {
        setState(() {
          _email = (email != null && email.isNotEmpty)
              ? email
              : 'your registered email';
          _isLoadingEmail = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to load vendor email: $e");
      if (mounted) {
        setState(() {
          _email = 'your registered email';
          _isLoadingEmail = false;
        });
      }
    }
  }

  Future<void> _handleSendCode() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _kycService.sendEmailOtp();
      if (mounted) {
        setState(() {
          _isSending = false;
          _codeSent = true;
        });
        _showToast(message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await _kycService.verifyEmail(code);
      if (mounted) {
        _showToast('Email verified successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showToast(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Email Verification',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF5F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mail_outline,
                          color: Color(0xFFF97316),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verify Your Email',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoadingEmail
                                ? Row(
                                    children: [
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Color(0xFFF97316),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Loading email...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    "We'll send a code to $_email",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Error banner
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // OTP input — shown after code is sent
                  if (_codeSent) ...[
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        hintText: '------',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '', // hides the maxLength counter
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isSending || _isVerifying || _isLoadingEmail)
                          ? null
                          : (_codeSent ? _handleVerify : _handleSendCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        disabledBackgroundColor: const Color(
                          0xFFF97316,
                        ).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: (_isSending || _isVerifying)
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _codeSent
                                  ? 'Verify Email'
                                  : 'Send Verification Code',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  if (_codeSent) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _isSending ? null : _handleSendCode,
                      child: const Text(
                        'Resend Code',
                        style: TextStyle(color: Color(0xFFF97316)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
