import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:sbrai_solutions/services/vendor/vendor_auth_service.dart';
import 'package:sbrai_solutions/services/vendor/nin_verification_service.dart';

class IdentityVerification extends StatefulWidget {
  const IdentityVerification({super.key});

  @override
  State<IdentityVerification> createState() => _IdentityVerificationState();
}

class _IdentityVerificationState extends State<IdentityVerification> {
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  String? _fileName;
  File? _selectedFile;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _ninError;
  String? _bvnError;

  // NIN verification result
  Map<String, dynamic>? _ninVerificationData;
  bool _ninVerified = false;

  final VendorAuthService _authService = VendorAuthService();
  final NINVerificationService _ninService = NINVerificationService();

  @override
  void initState() {
    super.initState();
    _ninController.addListener(_validateFields);
    _bvnController.addListener(_validateFields);
  }

  void _validateFields() {
    setState(() {
      // Validate NIN (required for now)
      if (_ninController.text.trim().isNotEmpty) {
        if (_ninController.text.trim().length != 11) {
          _ninError = 'NIN must be exactly 11 digits';
        } else if (!RegExp(r'^[0-9]+$').hasMatch(_ninController.text.trim())) {
          _ninError = 'NIN must contain only numbers';
        } else {
          _ninError = null;
        }
      } else {
        _ninError = 'NIN is required for verification';
      }

      // BVN validation (commented out - on hold)
      // if (_bvnController.text.trim().isNotEmpty) {
      //   if (_bvnController.text.trim().length != 11) {
      //     _bvnError = 'BVN must be exactly 11 digits';
      //   } else if (!RegExp(r'^[0-9]+$').hasMatch(_bvnController.text.trim())) {
      //     _bvnError = 'BVN must contain only numbers';
      //   } else {
      //     _bvnError = null;
      //   }
      // } else {
      //   _bvnError = null;
      // }

      // Button enabled only if NIN is valid
      final hasValidNin = _ninController.text.trim().isNotEmpty && _ninError == null;
      // final hasValidBvn = _bvnController.text.trim().isNotEmpty && _bvnError == null;

      _isButtonEnabled = hasValidNin; // Only NIN for now
    });
  }

  void _showCustomToast(
      BuildContext context,
      String message, {
        bool isError = false,
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade50 : Colors.white,
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
                    color: isError ? Colors.red : Colors.black,
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
                      color: isError ? Colors.red.shade800 : Colors.black,
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

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_isButtonEnabled) return;

    setState(() => _isLoading = true);

    try {
      final nin = _ninController.text.trim();

      _showCustomToast(context, 'Verifying NIN...', isError: false);

      debugPrint("🆔 Submitting NIN: $nin");

      // Use the correct verifyIdentity method with only NIN
      final response = await _authService.verifyIdentity(nin: nin);

      debugPrint("📦 Response: $response");

      if (response['status'] == 'success') {
        setState(() {
          _ninVerified = true;
          _ninVerificationData = response['data']?['nin_data'];
        });

        _showCustomToast(context, response['message'] ?? 'NIN verified successfully!');


        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        throw Exception(response['message'] ?? 'NIN verification failed');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        debugPrint("❌ Error: $errorMessage");

        if (errorMessage.contains('401') || errorMessage.contains('unauthenticated')) {
          errorMessage = 'Session expired. Please login again.';
        } else if (errorMessage.contains('NIN already used')) {
          errorMessage = 'This NIN has already been used for verification';
        } else if (errorMessage.contains('Invalid NIN')) {
          errorMessage = 'The NIN provided is invalid. Please check and try again.';
        } else if (errorMessage.contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        _showCustomToast(context, errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _ninController.dispose();
    _bvnController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Identity Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icons.badge_outlined,
                          color: Color(0xFFF97316),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Your Identity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Verify with your NIN',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // NIN Section (Active)
                  _buildLabel('National Identification Number (NIN) *'),
                  _buildTextField(
                    _ninController,
                    '12345678901',
                    errorText: _ninError,
                  ),
                  _buildSubLabel('11-digit NIN issued by NIMC'),

                  // Show NIN verification details if verified
                  if (_ninVerified && _ninVerificationData != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'NIN Verified Successfully!',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildVerifiedInfo('Full Name',
                              '${_ninVerificationData?['surname'] ?? ''} ${_ninVerificationData?['firstname'] ?? ''} ${_ninVerificationData?['middlename'] ?? ''}'.trim()),
                          const SizedBox(height: 6),
                          _buildVerifiedInfo('Date of Birth', _ninVerificationData?['birthdate'] ?? 'N/A'),
                          const SizedBox(height: 6),
                          _buildVerifiedInfo('Gender', _ninVerificationData?['gender'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Divider with note about BVN
                  _buildDividerWithText('BVN Verification Coming Soon'),
                  const SizedBox(height: 20),

                  // BVN Section (Disabled/Hold)
                  _buildLabel('Bank Verification Number (BVN)'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _bvnController,
                      keyboardType: TextInputType.number,
                      enabled: false, // Disabled until BVN integration is ready
                      style: TextStyle(color: Colors.grey.shade400),
                      decoration: InputDecoration(
                        hintText: '22334455667',
                        hintStyle: TextStyle(color: Colors.grey.shade300),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildSubLabel('BVN verification will be available soon'),

                  const SizedBox(height: 24),

                  // Document Upload Section
                  _buildLabel('Upload ID Document (Optional)'),
                  InkWell(
                    onTap: _pickDocument,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _fileName != null
                            ? const Color(0xFFF0FDF4)
                            : Colors.transparent,
                        border: Border.all(
                          color: _fileName != null
                              ? Colors.green.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _fileName != null
                                ? Icons.check_circle_outline
                                : Icons.upload_outlined,
                            color: _fileName != null
                                ? Colors.green
                                : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _fileName ?? 'Upload Document',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _fileName != null
                                    ? Colors.green
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildSubLabel('Supported formats: PDF, JPG, PNG (Max 5MB)'),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isButtonEnabled && !_isLoading)
                          ? _handleSubmit
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        disabledBackgroundColor: const Color(
                          0xFFF97316,
                        ).withOpacity(0.4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Verify with NIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Box
            const SizedBox(height: 16),
            Container(
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
                        'Why verify your NIN?',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'NIN verification helps us confirm your identity and provides:',
                    style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildBullet('Verified badge on your profile'),
                  _buildBullet('Increased trust from customers'),
                  _buildBullet('Access to premium features'),
                  _buildBullet('Higher listing limits'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
              style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildSubLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint, {
        String? errorText,
      }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => _validateFields(),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}