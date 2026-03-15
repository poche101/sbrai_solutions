import 'package:flutter/material.dart';
// Ensure these match your actual file names
import 'screen/profile_screen.dart';
import 'screen/vendor_dashboard_screen.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';

// Import your newly created KYC screen here
import 'package:sbrai_solutions/vendor/screen/settings/kyc_screen.dart';

import 'package:sbrai_solutions/vendor/screen/vendor_favorite_screen.dart'
    as vendor;
import 'package:sbrai_solutions/vendor/screen/message_screen.dart';
import 'package:sbrai_solutions/vendor/screen/settings/vendor_settings_screen.dart';

class VendorMenu extends StatelessWidget {
  const VendorMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // --- HEADER SECTION ---
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
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(
                          Icons.person_outline,
                          size: 45,
                          color: Color(0xFFFF7043),
                        ),
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
                  const Text(
                    'Igwe',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                        'Not Verified',
                        Colors.grey.shade400,
                        icon: Icons.pending_actions_rounded,
                        isVerified: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- MENU ITEMS ---
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
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          joinedDate: DateTime(2026, 1, 1),
                          isVerified: false,
                        ),
                      ),
                    );
                  }),
                  _buildMenuItem(Icons.add_box_outlined, 'Post Ad', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostAdScreen(),
                      ),
                    );
                  }),
                  _buildMenuItem(Icons.dashboard_outlined, 'Dashboard', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorDashboardScreen(),
                      ),
                    );
                  }),

                  _buildMenuItem(Icons.favorite_outline, 'Favorites', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const vendor.FavoriteScreen(),
                      ),
                    );
                  }),

                  _buildMenuItem(Icons.chat_bubble_outline, 'Messages', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessageScreen(),
                      ),
                    );
                  }),

                  const Divider(
                    height: 30,
                    thickness: 0.8,
                    indent: 25,
                    endIndent: 25,
                    color: Color(0xFFF1F1F1),
                  ),

                  _buildMenuItem(Icons.settings_outlined, 'Settings', () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => const VendorSettingsScreen(),
                      ),
                    );
                  }),

                  // --- UPDATED: KYC NAVIGATION ---
                  _buildMenuItem(Icons.verified_user_outlined, 'KYC', () {
                    final navigator = Navigator.of(context);
                    navigator.pop(); // Close drawer
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const KYCScreen(), // Navigates to your KYC Screen
                      ),
                    );
                  }),

                  _buildMenuItem(
                    Icons.logout_outlined,
                    'Logout',
                    () {},
                    color: Colors.red.shade300,
                  ),
                ],
              ),
            ),

            // --- FOOTER ---
            Padding(
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  Image.asset(
                    'images/logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.storefront_rounded,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),
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

  Widget _buildBadge(
    String label,
    Color color, {
    required IconData icon,
    bool isVerified = true,
  }) {
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
