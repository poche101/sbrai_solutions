import 'package:flutter/material.dart';
import 'package:sbrai_solutions/services/vendor/vendor_auth_service.dart';
import 'screen/profile_screen.dart';
import 'screen/vendor_dashboard_screen.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';
import 'package:sbrai_solutions/vendor/screen/settings/kyc_screen.dart';
import 'package:sbrai_solutions/screens/message_screen.dart';
import 'package:sbrai_solutions/vendor/screen/settings/vendor_settings_screen.dart';
import 'package:sbrai_solutions/vendor/screen/login_screen.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';

class VendorMenu extends StatefulWidget {
  final String userName;
  final String userEmail;

  const VendorMenu({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<VendorMenu> createState() => _VendorMenuState();
}

class _VendorMenuState extends State<VendorMenu> {
  bool _isLoggingOut = false;
  bool _isLoadingProfile = false;
  final VendorAuthService _authService = VendorAuthService();

  String _displayName = '';
  String _displayEmail = '';
  bool _isVerified = false;
  String? _businessName;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _displayEmail = widget.userEmail;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoadingProfile = true);

    try {
      final response = await _authService.getProfile();

      if (response['status'] == 'success' && response['data'] != null) {
        final vendorData = response['data'];
        setState(() {
          _displayName = vendorData['full_name'] ?? widget.userName;
          _displayEmail = vendorData['email'] ?? widget.userEmail;
          _businessName = vendorData['business_name'];
          _profilePhotoUrl = vendorData['profile_photo_url']?.toString();
          _isVerified =
              vendorData['email_verified_at'] != null ||
              vendorData['nin_verified_at'] != null;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile in menu: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _navigateToMessages() async {
    final apiService = ApiService();
    final token = await apiService.getToken() ?? '';
    final userData = await apiService.getUserData();
    final currentUserId = int.tryParse(userData['id']?.toString() ?? '0') ?? 0;

    if (!mounted) return;

    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          threads: [],
          authToken: token,
          currentUserId: currentUserId,
          isVendor: true,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      await _authService.logout();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(
                top: 50,
                left: 20,
                right: 10,
                bottom: 20,
              ),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F1F1), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: const Color(0xFFFFF3E0),
                        backgroundImage:
                            (_profilePhotoUrl != null &&
                                _profilePhotoUrl!.isNotEmpty)
                            ? NetworkImage(_profilePhotoUrl!)
                            : null,
                        child:
                            (_profilePhotoUrl == null ||
                                _profilePhotoUrl!.isEmpty)
                            ? const Icon(
                                Icons.person_outline,
                                size: 45,
                                color: Color(0xFFFF7043),
                              )
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black45,
                          size: 26,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_isLoadingProfile)
                    const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF7043),
                    )
                  else ...[
                    Text(
                      _displayName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayEmail,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                    if (_businessName != null)
                      Text(
                        _businessName!,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildBadge(
                        'Vendor',
                        const Color(0xFFFF7043),
                        icon: Icons.storefront_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        _isVerified ? 'Verified' : 'Not Verified',
                        _isVerified
                            ? const Color(0xFF00C853)
                            : Colors.grey.shade400,
                        icon: _isVerified
                            ? Icons.verified_rounded
                            : Icons.pending_actions_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildMenuItem(
                    Icons.home_outlined,
                    'Home',
                    () => Navigator.pop(context),
                  ),
                  _buildMenuItem(Icons.person_outline, 'Profile', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ).then((_) => _loadProfileData());
                  }),
                  _buildMenuItem(Icons.add_box_outlined, 'Post Ad', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PostAdScreen()),
                    );
                  }),
                  _buildMenuItem(Icons.dashboard_outlined, 'Dashboard', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VendorDashboardScreen(),
                      ),
                    );
                  }),
                  _buildMenuItem(
                    Icons.chat_bubble_outline,
                    'Messages',
                    _navigateToMessages,
                  ),
                  const Divider(
                    height: 30,
                    thickness: 0.8,
                    indent: 25,
                    endIndent: 25,
                    color: Color(0xFFF1F1F1),
                  ),
                  _buildMenuItem(Icons.settings_outlined, 'Settings', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VendorSettingsScreen(),
                      ),
                    );
                  }),
                  _buildMenuItem(Icons.verified_user_outlined, 'KYC', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KYCScreen()),
                    );
                  }),
                  _isLoggingOut
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _buildMenuItem(
                          Icons.logout_outlined,
                          'Logout',
                          _handleLogout,
                          color: Colors.red.shade300,
                        ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.black26, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black45, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
