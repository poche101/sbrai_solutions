import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/vendor/vendor_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final VendorAuthService _authService = VendorAuthService();

  bool isEditing = false;
  bool isLoading = true;
  bool isVerified = false;
  double rating = 0.0;
  String joinedDate = '';

  // User data
  String userName = '';
  String email = '';
  String phone = '';
  String businessName = '';
  String businessAddress = '';
  String nin = '';

  // Statistics
  int activeListings = 0;
  int totalViews = 0;
  int totalChats = 0;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController businessController;
  late TextEditingController addressController;

  String currentName = '';
  String currentPhone = '';
  String currentBusinessName = '';
  String currentBusinessAddress = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    nameController = TextEditingController();
    phoneController = TextEditingController();
    businessController = TextEditingController();
    addressController = TextEditingController();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await _authService.getProfile();

      if (!mounted) return;

      if (response['status'] == 'success' && response['data'] != null) {
        final vendor = response['data'];

        setState(() {
          userName = vendor['full_name'] ?? 'Vendor Name';
          email = vendor['email'] ?? '';
          phone = vendor['phone_number'] ?? '';
          businessName = vendor['business_name'] ?? 'My Business';
          businessAddress = vendor['business_address'] ?? '';
          nin = vendor['nin'] ?? '';
          isVerified = (vendor['email_verified_at'] != null) ||
              (vendor['nin_verified_at'] != null);
          rating = (vendor['rating'] ?? 0.0).toDouble();

          // Format joined date
          if (vendor['created_at'] != null) {
            try {
              final date = DateTime.parse(vendor['created_at']);
              joinedDate = DateFormat('MMM yyyy').format(date);
            } catch (e) {
              joinedDate = 'Recently';
            }
          }

          // Load statistics if available
          activeListings = vendor['active_listings'] ?? 0;
          totalViews = vendor['total_views'] ?? 0;
          totalChats = vendor['total_chats'] ?? 0;

          currentName = userName;
          currentPhone = phone;
          currentBusinessName = businessName;
          currentBusinessAddress = businessAddress;

          _updateControllers();
        });
      } else {
        _showToast(response['message'] ?? 'Failed to load profile', isError: true);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        _showToast('Error loading profile: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _updateControllers() {
    nameController.text = currentName;
    phoneController.text = currentPhone;
    businessController.text = currentBusinessName;
    addressController.text = currentBusinessAddress;
  }

  Future<void> _updateProfile() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await _authService.updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        businessName: businessController.text.trim(),
        address: addressController.text.trim(),
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        setState(() {
          currentName = nameController.text;
          currentPhone = phoneController.text;
          currentBusinessName = businessController.text;
          currentBusinessAddress = addressController.text;
          userName = currentName;
          phone = currentPhone;
          businessName = currentBusinessName;
          businessAddress = currentBusinessAddress;
          isEditing = false;
        });

        _showToast(response['message'] ?? 'Profile updated successfully!');
      } else {
        _showToast(response['message'] ?? 'Update failed', isError: true);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        _showToast('Error updating profile: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    businessController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
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
          if (!isEditing && !isLoading)
            IconButton(
              onPressed: () {
                setState(() {
                  isEditing = true;
                  _updateControllers();
                });
              },
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFFF7043),
                size: 28,
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF7043),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Account Information',
              child: isEditing ? _buildEditForm() : _buildInfoList(),
            ),
            const SizedBox(height: 16),
            _buildStatisticsSection(),
            if (nin.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildKycSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return _buildSectionCard(
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
              _buildStatusBadge(
                isVerified ? 'Verified' : 'Not Verified',
                isVerified
                    ? const Color(0xFF00C853)
                    : Colors.grey.shade400,
                icon: isVerified
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
                'Joined ${joinedDate.isEmpty ? 'Recently' : joinedDate}',
                style: const TextStyle(
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (rating > 0) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  rating.toString(),
                  style: const TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    return Column(
      children: [
        _buildInfoTile(Icons.alternate_email_rounded, 'Email', email),
        _buildInfoTile(Icons.phone_iphone_rounded, 'Phone', currentPhone),
        _buildInfoTile(
          Icons.business_center_rounded,
          'Business Name',
          currentBusinessName,
        ),
        _buildInfoTile(
          Icons.location_on_rounded,
          'Business Address',
          currentBusinessAddress.isEmpty ? 'Not provided' : currentBusinessAddress,
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
        _buildLabel("Business Address"),
        _buildEditField(
          addressController,
          "Enter business address",
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    isEditing = false;
                    _updateControllers();
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
                onPressed: isLoading ? null : _updateProfile,
                icon: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
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

  Widget _buildStatisticsSection() {
    return _buildSectionCard(
      title: 'Your Statistics',
      child: Row(
        children: [
          _buildStatItem(
            activeListings.toString(),
            'Active\nListings',
          ),
          _buildStatItem(
            totalViews.toString(),
            'Total Views',
          ),
          _buildStatItem(
            totalChats.toString(),
            'Chats',
          ),
        ],
      ),
    );
  }

  Widget _buildKycSection() {
    return _buildSectionCard(
      title: 'KYC Information',
      child: Column(
        children: [
          _buildInfoTile(
            Icons.credit_card_rounded,
            'NIN',
            nin,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 10),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );

  Widget _buildEditField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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
                  value.isEmpty ? 'Not provided' : value,
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