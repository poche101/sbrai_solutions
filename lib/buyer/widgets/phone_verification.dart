import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/buyer_service/kyc_service.dart';

class PhoneVerification extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerification({super.key, this.phoneNumber = ''});

  @override
  State<PhoneVerification> createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification> {
  final KycService _kycService = KycService();
  final ApiService _apiService = ApiService();

  // OTP input — 6 separate controllers + focus nodes
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _codeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _isLoadingPhone = false;
  String? _errorMessage;
  String _resolvedPhone = '';

  // Resend cooldown
  int _resendCooldown = 0;
  bool get _canResend => _resendCooldown == 0 && !_isSending;

  @override
  void initState() {
    super.initState();
    _resolvePhone();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Phone resolution ───────────────────────────────────────────────────────

  /// Use the passed-in phone first. If empty, try SharedPreferences,
  /// then fall back to a fresh API fetch.
  Future<void> _resolvePhone() async {
    // 1. Use what was passed in
    if (widget.phoneNumber.isNotEmpty) {
      setState(() => _resolvedPhone = widget.phoneNumber);
      return;
    }

    setState(() => _isLoadingPhone = true);

    try {
      // 2. Try SharedPreferences cache
      final userData = await _apiService.getUserData();
      final cached = userData['phone'] ?? '';

      if (cached.isNotEmpty) {
        if (mounted) setState(() => _resolvedPhone = cached);
        return;
      }

      // 3. Fall back to fresh profile from API
      final response = await _apiService.getBuyerProfile();
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final phone = body['data']?['phone']?.toString() ?? '';
        await _apiService.saveUserData(body['data'] ?? {});
        if (mounted) setState(() => _resolvedPhone = phone);
      }
    } catch (_) {
      // Silent fail — phone stays empty, user can still send OTP
    } finally {
      if (mounted) setState(() => _isLoadingPhone = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _otpValue => _otpControllers.map((c) => c.text.trim()).join();

  bool get _otpComplete => _otpValue.length == 6;

  String get _displayPhone => _resolvedPhone.isNotEmpty ? _resolvedPhone : '—';

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
                  color: Colors.black.withOpacity(0.1),
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
        _focusNodes[0].requestFocus();
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
        await Future.delayed(const Duration(milliseconds: 800));
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
          'Phone Verification',
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

  Widget _buildInfoCard() {
    return _buildCard(
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
                  Icons.phone_outlined,
                  color: Color(0xFFF97316),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify Your Phone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _codeSent
                          ? 'Code sent to $_displayPhone'
                          : "We'll send an SMS to $_displayPhone",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Phone display chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Color(0xFFF97316)),
                const SizedBox(width: 8),
                Expanded(
                  child: _isLoadingPhone
                      ? const SizedBox(
                          height: 16,
                          width: 100,
                          child: LinearProgressIndicator(
                            color: Color(0xFFF97316),
                            backgroundColor: Color(0xFFFFE4D6),
                          ),
                        )
                      : Text(
                          _displayPhone,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canResend ? _handleSendSMS : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFFF97316,
                ).withOpacity(0.5),
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
                          : 'Send SMS Code',
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
            'Enter the 6-digit code sent to your phone.',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _buildOtpBox(i)),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
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
                ).withOpacity(0.4),
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
                      'Verify Phone',
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
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
