import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sbrai_solutions/buyer_service/kyc_service.dart';

/// Email verification sub-screen.
///
/// Receives [email] from KYCScreen via:
///   EmailVerification(email: _userEmail ?? '')
///
/// If email is empty the UI falls back gracefully to 'your email address'.
class EmailVerification extends StatefulWidget {
  final String email;

  const EmailVerification({super.key, this.email = ''});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  final KycService _kycService = KycService();

  // OTP — 6 separate controllers + focus nodes
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _codeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMessage;

  // Resend cooldown (seconds)
  int _resendCooldown = 0;
  bool get _canResend => _resendCooldown == 0 && !_isSending;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _otpValue => _otpControllers.map((c) => c.text.trim()).join();
  bool get _otpComplete => _otpValue.length == 6;

  /// The email passed from KYCScreen, or a generic fallback.
  String get _displayEmail =>
      widget.email.isNotEmpty ? widget.email : 'your email address';

  /// Masked form: john.doe@gmail.com → j***@gmail.com
  String get _maskedEmail {
    if (widget.email.isEmpty) return 'your email address';
    final parts = widget.email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return widget.email;
    return '${parts[0][0]}***@${parts[1]}';
  }

  void _clearOtp() {
    for (final c in _otpControllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  void _showToast(String message, {bool isError = false}) {
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
              color: isError ? const Color(0xFFFF3B30) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isError ? Colors.white24 : Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.close : Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isError ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleSendCode() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _kycService.sendEmailOtp();
      if (mounted) {
        setState(() => _codeSent = true);
        _showToast(message);
        _startResendCooldown();
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        // Improved error display
        String errorMsg = e.toString();
        if (e is Exception) {
          errorMsg = e.toString().replaceAll('Exception: ', '');
        }

        setState(() => _errorMessage = errorMsg);
        _showToast(errorMsg, isError: true);

        // Print full error for debugging
        print("❌ sendEmailOtp ERROR: $e");
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleVerify() async {
    if (!_otpComplete) {
      _showToast('Please enter the complete 6-digit code.', isError: true);
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await _kycService.verifyEmail(_otpValue);
      if (mounted) {
        _showToast('Email verified successfully! ✓');
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        _showToast(e.toString(), isError: true);
        _clearOtp();
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Email Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoCard(),
            if (_codeSent) ...[const SizedBox(height: 20), _buildOtpCard()],
          ],
        ),
      ),
    );
  }

  // ── Info card (email display + send/resend button) ─────────────────────────

  Widget _buildInfoCard() {
    return _buildCard(
      child: Column(
        children: [
          // ── Header row ─────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
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
                    Text(
                      _codeSent
                          ? 'A 6-digit code was sent to:'
                          : "We'll send a 6-digit code to:",
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Email chip — shows the actual email from KYCScreen ─────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail, size: 18, color: Color(0xFFF97316)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full email (from KYCScreen _userEmail)
                      Text(
                        _displayEmail,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_codeSent && widget.email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Code sent to $_maskedEmail',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Verified chip shown if code already sent
                if (_codeSent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Text(
                      'Code Sent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Send / Resend button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canResend ? _handleSendCode : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFFF97316,
                ).withOpacity(0.45),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _codeSent
                          ? (_resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend Code')
                          : 'Send Verification Code',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── OTP entry card ─────────────────────────────────────────────────────────

  Widget _buildOtpCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Verification Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Check $_maskedEmail for a 6-digit code.',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),

          // ── 6-box OTP row ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, _buildOtpBox),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ── Verify button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_otpComplete && !_isVerifying) ? _handleVerify : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFFF97316,
                ).withOpacity(0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Verify Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Single OTP box ─────────────────────────────────────────────────────────

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey.shade50,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {}); // rebuild to enable/disable verify button
        },
      ),
    );
  }

  // ── Shared card wrapper ────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
