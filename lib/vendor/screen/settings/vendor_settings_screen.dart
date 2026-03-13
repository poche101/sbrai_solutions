import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Ensure this path matches your project structure
import 'package:sbrai_solutions/models/settings_model.dart';
import 'package:sbrai_solutions/vendor/screen/settings/vendors_terms_page.dart';
import 'package:sbrai_solutions/vendor/screen/settings/privacy_policy_page.dart';
import 'package:sbrai_solutions/vendor/screen/settings/vendors_help_page.dart';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  // Initializing the model with default values
  final SettingsModel _settings = SettingsModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Notifications Section
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications_none_outlined,
              iconColor: Colors.orange,
              description: 'Manage your notification preferences',
              children: [
                _buildSwitchTile(
                  'New Listings',
                  'Get notified about new items in your area',
                  _settings.newListings,
                  (val) => setState(() => _settings.newListings = val),
                ),
                _buildSwitchTile(
                  'Price Drops',
                  'Alert me when prices drop on favorited items',
                  _settings.priceDrops,
                  (val) => setState(() => _settings.priceDrops = val),
                ),
                _buildSwitchTile(
                  'Messages',
                  'Receive notifications for new messages',
                  _settings.messages,
                  (val) => setState(() => _settings.messages = val),
                ),
                _buildSwitchTile(
                  'Promotions',
                  'Receive promotional offers and deals',
                  _settings.promotions,
                  (val) => setState(() => _settings.promotions = val),
                ),
              ],
            ),

            // Privacy & Security Section
            _buildSection(
              title: 'Privacy & Security',
              icon: Icons.shield_outlined,
              iconColor: Colors.orange,
              description: 'Control your privacy and account security',
              children: [
                _buildSwitchTile(
                  'Show Online Status',
                  'Let others see when you\'re online',
                  _settings.showOnlineStatus,
                  (val) => setState(() => _settings.showOnlineStatus = val),
                ),
                _buildSwitchTile(
                  'Show Phone Number',
                  'Display phone number on profile',
                  _settings.showPhoneNumber,
                  (val) => setState(() => _settings.showPhoneNumber = val),
                ),
                _buildSwitchTile(
                  'Allow Messages',
                  'Allow users to send you messages',
                  _settings.allowMessages,
                  (val) => setState(() => _settings.allowMessages = val),
                ),
                _buildActionTile('Change Password', Icons.key_outlined, () {
                  // TODO: Navigate to Change Password Screen
                }),
              ],
            ),

            // Language & Region Section
            _buildSection(
              title: 'Language & Region',
              icon: Icons.language_outlined,
              iconColor: Colors.orange,
              titleColor: Colors.black,
              children: [
                _buildSelectionTile('Language', _settings.language, () {
                  // Example of dynamic update
                  _showLanguagePicker();
                }),
                _buildSelectionTile('Currency', _settings.currency, () {
                  // TODO: Add Currency Picker
                }),
              ],
            ),

            // Legal Section
            _buildSection(
              children: [
                _buildActionTile(
                  'Terms & Conditions',
                  Icons.description_outlined,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorTermsPage(),
                    ),
                  ),
                ),
                _buildActionTile(
                  'Privacy Policy',
                  Icons.lock_outline,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorPrivacyPolicyPage(),
                    ),
                  ),
                ),
                _buildActionTile(
                  'Help & Support',
                  Icons.help_outline,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Vendor_help_Page(),
                    ),
                  ),
                ),
              ],
            ),

            // Danger Zone
            _buildSection(
              title: 'Danger Zone',
              iconColor: Colors.redAccent,
              titleColor: Colors.redAccent,
              description: 'Irreversible and destructive actions',
              isDanger: true,
              children: [
                _buildActionTile('Logout', Icons.logout, () {
                  /* TODO: Implement Logout Logic */
                }, color: Colors.redAccent),
                _buildActionTile(
                  'Delete Account',
                  Icons.delete_outline,
                  _showDeleteConfirmation,
                  color: Colors.redAccent,
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Sbrai Hub v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Logic Helpers ---

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['English', 'French', 'Igbo', 'Hausa', 'Yoruba'].map((lang) {
          return ListTile(
            title: Text(lang),
            onTap: () {
              setState(() => _settings.language = lang);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSection({
    String? title,
    IconData? icon,
    String? description,
    required List<Widget> children,
    Color titleColor = Colors.black87,
    Color? iconColor,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger ? Colors.red.shade100 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null)
                  Icon(icon, size: 20, color: iconColor ?? titleColor),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            const Divider(height: 24),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: value,
              activeColor: const Color(0xFFFF7043),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.black87,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  Widget _buildSelectionTile(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Are you absolutely sure?',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'This action cannot be undone. This will permanently delete your account.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              /* TODO: Delete account logic */
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
