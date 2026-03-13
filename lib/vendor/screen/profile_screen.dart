import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final bool isVerified;
  final DateTime joinedDate;
  final double rating;
  final String userName;
  final String email;
  final String phone;
  final String businessName;

  const ProfileScreen({
    super.key,
    this.isVerified = false, // Defaults to false (Not Verified)
    required this.joinedDate,
    this.rating = 0.0,
    this.userName = 'Demo User',
    this.email = 'user@example.com',
    this.phone = '000-000-0000',
    this.businessName = 'My Business',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController businessController;

  late String currentName;
  late String currentPhone;
  late String currentBusinessName;

  @override
  void initState() {
    super.initState();
    // DEBUG: Check your console! If this prints 'true',
    // the parent widget is passing 'true' and overriding your default.
    debugPrint("ProfileScreen isVerified: ${widget.isVerified}");

    currentName = widget.userName;
    currentPhone = widget.phone;
    currentBusinessName = widget.businessName;

    _resetControllers();
  }

  void _resetControllers() {
    nameController = TextEditingController(text: currentName);
    phoneController = TextEditingController(text: currentPhone);
    businessController = TextEditingController(text: currentBusinessName);
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MMM yyyy').format(widget.joinedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!isEditing)
            IconButton(
              onPressed: () => setState(() => isEditing = true),
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFFF7043),
                size: 28,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- HEADER SECTION ---
            _buildSectionCard(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 50,
                      color: Color(0xFFFF7043),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusBadge('Vendor', const Color(0xFFFF7043)),
                      const SizedBox(width: 8),
                      // UI LOGIC:
                      _buildStatusBadge(
                        widget.isVerified ? 'Verified' : 'Not Verified',
                        widget.isVerified
                            ? const Color(0xFF00C853)
                            : Colors.grey.shade400,
                        icon: widget.isVerified
                            ? Icons.verified_rounded
                            : Icons.pending_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Joined $formattedDate',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.rating} rating',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- ACCOUNT INFORMATION / EDIT FORM ---
            _buildSectionCard(
              title: 'Account Information',
              child: isEditing ? _buildEditForm() : _buildInfoList(),
            ),
            const SizedBox(height: 16),

            // --- STATISTICS SECTION ---
            _buildSectionCard(
              title: 'Your Statistics',
              child: Row(
                children: [
                  _buildStatItem('0', 'Active\nListings'),
                  _buildStatItem('0', 'Total Views'),
                  _buildStatItem('0', 'Chats'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoList() {
    return Column(
      children: [
        _buildInfoTile(Icons.alternate_email_rounded, 'Email', widget.email),
        _buildInfoTile(Icons.phone_iphone_rounded, 'Phone', currentPhone),
        _buildInfoTile(
          Icons.business_center_rounded,
          'Business Name',
          currentBusinessName,
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Full Name"),
        _buildEditField(nameController, "Enter your full name"),
        _buildLabel("Phone Number"),
        _buildEditField(phoneController, "Enter phone number"),
        _buildLabel("Business Name"),
        _buildEditField(businessController, "Enter business name"),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    isEditing = false;
                    _resetControllers();
                  });
                },
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    currentName = nameController.text;
                    currentPhone = phoneController.text;
                    currentBusinessName = businessController.text;
                    isEditing = false;
                  });
                  _showToast("Profile updated successfully!");
                },
                icon: const Icon(
                  Icons.save_as_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 10),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );

  Widget _buildEditField(TextEditingController controller, String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF1F3F4),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.black45, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF7043),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
