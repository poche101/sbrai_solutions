import 'package:flutter/material.dart';

class PhoneVerification extends StatefulWidget {
  final String phoneNumber;

  // Constructor allows passing any phone number dynamically
  const PhoneVerification({
    super.key,
    this.phoneNumber = '08087654321', // Fallback default
  });

  @override
  State<PhoneVerification> createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification> {
  bool _isLoading = false;

  /// Logic to show the custom toast notification at the bottom
  void _showCustomToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // Positions the toast above the bottom of the screen
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
                // Success Icon
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

    // Auto-dismiss the toast after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Handles the "Send SMS" action with a loading state
  Future<void> _handleSendSMS() async {
    setState(() => _isLoading = true);

    // Simulate an API call delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      _showCustomToast(context, 'SMS code sent successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Main Verification Card
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Circular Icon Container
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
                      const SizedBox(width: 20),
                      // Dynamic Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verify Your Phone',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "We'll send an SMS to ${widget.phoneNumber}",
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
                  const SizedBox(height: 30),
                  // Send SMS Button with Loading State
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendSMS,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFFF97316,
                        ).withOpacity(0.6),
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
                              'Send SMS Code',
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
          ],
        ),
      ),
    );
  }
}
