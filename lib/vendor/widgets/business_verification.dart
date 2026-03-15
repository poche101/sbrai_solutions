import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class BusinessVerification extends StatefulWidget {
  const BusinessVerification({super.key});

  @override
  State<BusinessVerification> createState() => _BusinessVerificationState();
}

class _BusinessVerificationState extends State<BusinessVerification> {
  final TextEditingController _rcNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _certificateName;
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rcNumberController.addListener(_validateForm);
    _addressController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      // Button only enables if RC Number, Address, AND Certificate are provided
      _isButtonEnabled =
          _rcNumberController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty &&
          _certificateName != null;
    });
  }

  void _showCustomToast(BuildContext context, String message) {
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
              color: Colors.white,
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
              mainAxisSize: MainAxisSize.min,
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
                    style: const TextStyle(
                      color: Colors.black,
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

  Future<void> _pickCACDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        setState(() {
          _certificateName = result.files.single.name;
        });
        // Re-run validation after picking the file
        _validateForm();
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showCustomToast(context, 'Business documents submitted successfully!');

      // Return true to the KYC Screen to mark this step as completed
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pop(context, true);
      });
    }
  }

  @override
  void dispose() {
    _rcNumberController.dispose();
    _addressController.dispose();
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
          'Business Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
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
                      Icons.business_outlined,
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
                          'Verify Your Business',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Required for vendor verification badge',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildLabel('Business Registration Number (RC Number)'),
              _buildTextField(_rcNumberController, 'RC1234567'),
              _buildSubLabel('CAC registration number'),

              const SizedBox(height: 24),

              _buildLabel('Business Address'),
              _buildTextField(
                _addressController,
                '123 Main Street, Ikeja, Lagos',
              ),

              const SizedBox(height: 24),

              _buildLabel('Upload Business Documents'),
              InkWell(
                onTap: _pickCACDocument,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _certificateName != null
                        ? const Color(0xFFF0FDF4)
                        : Colors.transparent,
                    border: Border.all(
                      color: _certificateName != null
                          ? Colors.green.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _certificateName != null
                            ? Icons.check_circle_outline
                            : Icons.upload_outlined,
                        color: _certificateName != null
                            ? Colors.green
                            : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _certificateName ?? 'Upload CAC Certificate',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _certificateName != null
                                ? Colors.green
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildSubLabel(
                'Upload CAC registration certificate or business permit',
              ),

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
                          'Submit for Verification',
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
      ),
    );
  }

  // ... (Helper methods _buildLabel, _buildSubLabel, _buildTextField remain the same)
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );

  Widget _buildSubLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  );

  Widget _buildTextField(TextEditingController controller, String hint) =>
      TextField(
        controller: controller,
        onChanged: (_) =>
            _validateForm(), // Added explicit call for text changes
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      );
}
