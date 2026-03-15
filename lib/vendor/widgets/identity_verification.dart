import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class IdentityVerification extends StatefulWidget {
  const IdentityVerification({super.key});

  @override
  State<IdentityVerification> createState() => _IdentityVerificationState();
}

class _IdentityVerificationState extends State<IdentityVerification> {
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  String? _fileName;
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ninController.addListener(_validateFields);
    _bvnController.addListener(_validateFields);
  }

  void _validateFields() {
    setState(() {
      // Enables if either NIN or BVN is provided
      _isButtonEnabled =
          _ninController.text.trim().isNotEmpty ||
          _bvnController.text.trim().isNotEmpty;
    });
  }

  /// Custom Toast Notification
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

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);

    // Simulate API call for Identity verification
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showCustomToast(context, 'Identity information submitted successfully!');

      // Delay slightly to let the user see the toast before popping
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context, true);
      });
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
                          'Provide your NIN or BVN',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildLabel('National Identification Number (NIN)'),
              _buildTextField(_ninController, '12345678901'),
              _buildSubLabel('11-digit NIN issued by NIMC'),

              const SizedBox(height: 20),
              _buildDividerWithText('OR'),
              const SizedBox(height: 20),

              _buildLabel('Bank Verification Number (BVN)'),
              _buildTextField(_bvnController, '22334455667'),
              _buildSubLabel('11-digit BVN from your bank'),

              const SizedBox(height: 24),

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

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => _validateFields(),
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
