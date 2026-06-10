import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/settings_model.dart';
import 'package:sbrai_solutions/buyer_service/settings_service.dart';
import 'package:sbrai_solutions/buyer/screens/settings/buyers_terms_page.dart';
import 'package:sbrai_solutions/buyer/screens/settings/privacy_policy_page.dart';
import 'package:sbrai_solutions/buyer/screens/settings/help_support_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  SettingsModel _settings = SettingsModel();
  bool _isLoading = true;
  bool _isSyncing = false; // prevents overlapping PATCH calls

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  // ── Load settings from backend on screen open ──────────────────────────────
  Future<void> _loadUserSettings() async {
    final remoteSettings = await _settingsService.fetchSettings();
    if (mounted) {
      setState(() {
        if (remoteSettings != null) _settings = remoteSettings;
        _isLoading = false;
      });
    }
  }

  // ── Optimistic update with rollback on failure ─────────────────────────────
  void _updateSetting(SettingsModel optimistic) async {
    if (_isSyncing) return; // ignore taps while a sync is in flight

    // 1. Snapshot current state in case we need to roll back
    final previous = _settings;

    // 2. Apply optimistically
    setState(() {
      _settings = optimistic;
      _isSyncing = true;
    });

    // 3. Send to backend — returns server-confirmed model or null on failure
    final confirmed = await _settingsService.updateNotificationSettings(
      optimistic,
    );

    if (!mounted) return;

    if (confirmed != null) {
      // 4a. Sync UI with exactly what the server saved
      setState(() {
        _settings = confirmed;
        _isSyncing = false;
      });
    } else {
      // 4b. Roll back to previous state and notify user
      setState(() {
        _settings = previous;
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to sync settings. Please check connection."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
        // Subtle syncing indicator in the AppBar — non-blocking
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF7043),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7043)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Notifications Section ──────────────────────────────────
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
                        (val) => _updateSetting(
                          _settings.copyWith(newListings: val),
                        ),
                      ),
                      _buildSwitchTile(
                        'Price Drops',
                        'Alert me when prices drop on favorited items',
                        _settings.priceDrops,
                        (val) =>
                            _updateSetting(_settings.copyWith(priceDrops: val)),
                      ),
                      _buildSwitchTile(
                        'Messages',
                        'Receive notifications for new messages',
                        _settings.messages,
                        (val) =>
                            _updateSetting(_settings.copyWith(messages: val)),
                      ),
                      _buildSwitchTile(
                        'Promotions',
                        'Receive promotional offers and deals',
                        _settings.promotions,
                        (val) =>
                            _updateSetting(_settings.copyWith(promotions: val)),
                      ),
                    ],
                  ),

                  // ── Privacy & Security Section ─────────────────────────────
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
                        (val) => _updateSetting(
                          _settings.copyWith(showOnlineStatus: val),
                        ),
                      ),
                      _buildSwitchTile(
                        'Show Phone Number',
                        'Display phone number on profile',
                        _settings.showPhoneNumber,
                        (val) => _updateSetting(
                          _settings.copyWith(showPhoneNumber: val),
                        ),
                      ),
                      _buildSwitchTile(
                        'Allow Messages',
                        'Allow users to send you messages',
                        _settings.allowMessages,
                        (val) => _updateSetting(
                          _settings.copyWith(allowMessages: val),
                        ),
                      ),
                      _buildActionTile(
                        'Change Password',
                        Icons.key_outlined,
                        () {},
                      ),
                    ],
                  ),

                  // ── Language & Region Section ──────────────────────────────
                  _buildSection(
                    title: 'Language & Region',
                    icon: Icons.language_outlined,
                    iconColor: Colors.orange,
                    children: [
                      _buildSelectionTile(
                        'Language',
                        _settings.language,
                        () {},
                      ),
                      _buildSelectionTile(
                        'Currency',
                        _settings.currency,
                        () {},
                      ),
                    ],
                  ),

                  // ── Legal Section ──────────────────────────────────────────
                  _buildSection(
                    children: [
                      _buildActionTile(
                        'Terms & Conditions',
                        Icons.description_outlined,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BuyersTermsPage(),
                          ),
                        ),
                      ),
                      _buildActionTile(
                        'Privacy Policy',
                        Icons.lock_outline,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyPage(),
                          ),
                        ),
                      ),
                      _buildActionTile(
                        'Help & Support',
                        Icons.help_outline,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportPage(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Danger Zone ────────────────────────────────────────────
                  _buildSection(
                    title: 'Danger Zone',
                    iconColor: Colors.redAccent,
                    titleColor: Colors.redAccent,
                    description: 'Irreversible and destructive actions',
                    isDanger: true,
                    children: [
                      _buildActionTile(
                        'Logout',
                        Icons.logout,
                        () {},
                        color: Colors.redAccent,
                      ),
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

  // ── UI Helpers (unchanged) ─────────────────────────────────────────────────

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
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
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
    String sub,
    bool val,
    Function(bool) onChg,
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
                  sub,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: val,
              activeColor: const Color(0xFFFF7043),
              onChanged: _isSyncing ? null : onChg, // disabled during sync
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
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'This action cannot be undone. This will permanently delete your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
