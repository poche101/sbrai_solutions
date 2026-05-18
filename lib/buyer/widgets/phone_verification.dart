// lib/vendor/widgets/phone_verification.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sbrai_solutions/services/vendor/vendor_kyc_service.dart';
import 'package:sbrai_solutions/services/vendor/vendor_auth_service.dart';

class PhoneVerification extends StatefulWidget {
  final String vendorPhone;

  const PhoneVerification({super.key, this.vendorPhone = ''});

  @override
  State<PhoneVerification> createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification>
    with SingleTickerProviderStateMixin {
  final VendorKYCService _kycService = VendorKYCService();
  final VendorAuthService _authService = VendorAuthService();

  // OTP controllers + focus nodes
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Animation
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  bool _codeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _isLoadingPhone = true;
  String? _errorMessage;
  String _resolvedPhone = '';

  int _resendCooldown = 0;
  bool get _canResend => _resendCooldown == 0 && !_isSending;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );

    _loadVendorPhone();
  }

  @override
  void dispose() {
    _slideController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Phone resolution ───────────────────────────────────────────────────────

  Future<void> _loadVendorPhone() async {
    if (widget.vendorPhone.isNotEmpty) {
      setState(() {
        _resolvedPhone = widget.vendorPhone;
        _isLoadingPhone = false;
      });
      return;
    }

    setState(() => _isLoadingPhone = true);

    try {
      final profile = await _authService.getProfile();
      final data = profile['data'] as Map<String, dynamic>? ?? {};

      final String? phone =
          data['phone_number']?.toString() ??
          data['phone']?.toString() ??
          profile['phone_number']?.toString() ??
          profile['phone']?.toString();

      if (mounted) {
        setState(() {
          _resolvedPhone = (phone != null && phone.isNotEmpty) ? phone : '';
          _isLoadingPhone = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to load vendor phone: $e");
      if (mounted) setState(() => _isLoadingPhone = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _otpValue => _otpControllers.map((c) => c.text.trim()).join();

  bool get _otpComplete => _otpValue.length == 6;

  String get _displayPhone => _resolvedPhone.isNotEmpty ? _resolvedPhone : '—';

  /// Masks phone: 0801***4321
  String get _maskedPhone {
    if (_resolvedPhone.length < 7) return _displayPhone;
    final start = _resolvedPhone.substring(0, 4);
    final end = _resolvedPhone.substring(_resolvedPhone.length - 4);
    return '$start***$end';
  }

  void _clearOtp() {
    for (final c in _otpControllers) c.clear();
    setState(() {});
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
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

  Future<void> _handleSendSMS() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _kycService.sendPhoneOtp();
      if (mounted) {
        setState(() => _codeSent = true);
        _showToast(message);
        _startResendCooldown();
        // Trigger OTP card slide-in animation
        _slideController.forward(from: 0);
        Future.delayed(
          const Duration(milliseconds: 500),
          () => _focusNodes[0].requestFocus(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        _showToast(e.toString(), isError: true);
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
      await _kycService.verifyPhone(_otpValue);
      if (mounted) {
        _showToast('Phone number verified successfully!');
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) Navigator.pop(context, true);
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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Phone Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(),

            const SizedBox(height: 24),

            // ── Step 1: Phone info + Send button ────────────────────────────
            _buildSendCard(),

            // ── Step 2: OTP input (animated in after code sent) ─────────────
            if (_codeSent) ...[
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildOtpCard(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.phone_android_rounded,
            color: Color(0xFFF97316),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verify your phone\nnumber',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _codeSent
              ? 'Enter the 6-digit code sent to $_maskedPhone'
              : 'We\'ll send a one-time SMS code to confirm your number.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSendCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step label
          Row(
            children: [
              _buildStepBadge('1', done: _codeSent),
              const SizedBox(width: 10),
              Text(
                _codeSent ? 'Code sent' : 'Send verification code',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _codeSent ? Colors.green : const Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Phone chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: Color(0xFFF97316),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _isLoadingPhone
                      ? const SizedBox(
                          height: 16,
                          child: LinearProgressIndicator(
                            color: Color(0xFFF97316),
                            backgroundColor: Color(0xFFFFE4D6),
                          ),
                        )
                      : Text(
                          _displayPhone,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                if (_codeSent)
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Send / Resend button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_canResend && !_isLoadingPhone)
                  ? _handleSendSMS
                  : null,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _codeSent ? Icons.refresh : Icons.send_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _codeSent
                              ? (_resendCooldown > 0
                                    ? 'Resend in ${_resendCooldown}s'
                                    : 'Resend Code')
                              : 'Send SMS Code',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step label
          Row(
            children: [
              _buildStepBadge('2'),
              const SizedBox(width: 10),
              const Text(
                'Enter verification code',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Check your SMS for the 6-digit code.',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),

          const SizedBox(height: 24),

          // OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, _buildOtpBox),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
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

          // Verify button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_otpComplete && !_isVerifying) ? _handleVerify : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Verify Phone Number',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final isFilled = _otpControllers[index].text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isFilled ? const Color(0xFFFFF5F2) : Colors.grey.shade50,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isFilled ? const Color(0xFFF97316) : Colors.grey.shade300,
              width: isFilled ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _buildStepBadge(String step, {bool done = false}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: done ? Colors.green : const Color(0xFFF97316),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
