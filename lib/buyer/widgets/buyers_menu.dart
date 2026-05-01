import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Hide UserProfile and ProfileService from profile_screen to avoid collisions
// with the dedicated model and service files.
import 'package:sbrai_solutions/buyer/screens/profile_screen.dart'
    hide UserProfile, ProfileService;
import 'package:sbrai_solutions/buyer/screens/settings/favorite_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/message_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/settings_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/kyc_screen.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/buyer/screens/signin_screen.dart';
import 'package:sbrai_solutions/buyer_service/profile_service.dart';
import 'package:sbrai_solutions/models/buyer/user_profile_model.dart';

class BuyersMenu extends StatefulWidget {
  final bool isDesktop;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  const BuyersMenu({
    super.key,
    this.isDesktop = false,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  @override
  State<BuyersMenu> createState() => _BuyersMenuState();
}

class _BuyersMenuState extends State<BuyersMenu> {
  // ── Services ───────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();

  // ── State ──────────────────────────────────────────────────────────────────
  File? _imageFile; // local preview shown while upload is in-flight
  bool _isLoggingOut = false;
  bool _isUploading = false;
  bool _isFetching = false;

  // Typed profile — seeded from widget props, refreshed on init
  late String _displayName;
  late String _displayEmail;
  String? _displayPhoto;
  String _joinedLabel = '---';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Seed from props so the header is populated immediately
    _displayName = widget.userName.isNotEmpty
        ? widget.userName
        : 'Welcome Guest';
    _displayEmail = widget.userEmail.isNotEmpty
        ? widget.userEmail
        : 'Sign in to sync data';
    _displayPhoto = widget.userPhotoUrl;
    // Then refresh from the server
    _fetchProfile();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() => _isFetching = true);

    try {
      final UserProfile profile = await _profileService.fetchProfile();
      if (!mounted) return;
      setState(() {
        if (profile.displayName.isNotEmpty) _displayName = profile.displayName;
        if (profile.email.isNotEmpty) _displayEmail = profile.email;
        _joinedLabel = profile.joinedLabel;

        // Only update photo + clear local preview when server gives us a real URL
        if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
          // Cache-bust so the network image always reloads the latest version
          final ts = DateTime.now().millisecondsSinceEpoch;
          final sep = profile.photoUrl!.contains('?') ? '&' : '?';
          _displayPhoto = '${profile.photoUrl}${sep}v=$ts';
          _imageFile =
              null; // drop local preview now that server URL is confirmed
        }
        // If photoUrl is null we keep whatever is already displayed
      });
    } catch (e) {
      debugPrint("BuyersMenu — profile fetch error: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ── Image selection & upload ───────────────────────────────────────────────

  Future<void> _handleImageSelection() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      // Show local preview immediately
      setState(() {
        _imageFile = File(picked.path);
        _isUploading = true;
      });

      // uploadAvatar is the alias in ProfileService → calls uploadPhoto internally
      final UserProfile updated = await _profileService.uploadAvatar(
        _imageFile!,
      );

      if (mounted) {
        _showToast("Profile picture updated!");
        // Apply the server-confirmed URL and drop the local preview
        setState(() {
          if (updated.photoUrl != null && updated.photoUrl!.isNotEmpty) {
            final ts = DateTime.now().millisecondsSinceEpoch;
            final sep = updated.photoUrl!.contains('?') ? '&' : '?';
            _displayPhoto = '${updated.photoUrl}${sep}v=$ts';
          }
          _imageFile = null;
        });
      }
    } catch (e) {
      debugPrint("BuyersMenu — image upload error: $e");
      if (mounted) {
        setState(() => _imageFile = null); // drop broken preview
        _showToast("Upload failed. Please try again.", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _apiService.logout();
    } catch (_) {
      await _apiService.clearToken();
    } finally {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SigninScreen()),
          (route) => false,
        );
      }
    }
  }

  // ── Navigation helper ──────────────────────────────────────────────────────

  void _navigateTo(Widget screen) {
    if (Navigator.canPop(context)) Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ── Toast ──────────────────────────────────────────────────────────────────

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: isError ? Colors.redAccent : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isDesktop ? 280 : MediaQuery.of(context).size.width * 0.80,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          if (_isFetching)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Color(0xFFFF6B35),
              minHeight: 2,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(
                  Icons.home_outlined,
                  "Home",
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  Icons.person_outline,
                  "Profile",
                  onTap: () => _navigateTo(const ProfileScreen()),
                ),
                _buildMenuItem(
                  Icons.favorite_outline,
                  "Favorites",
                  onTap: () => _navigateTo(const FavoriteScreen()),
                ),
                _buildMenuItem(
                  Icons.chat_bubble_outline,
                  "Messages",
                  onTap: () => _navigateTo(const MessageScreen()),
                ),
                const Divider(
                  height: 30,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                _buildMenuItem(
                  Icons.settings_outlined,
                  "Settings",
                  onTap: () => _navigateTo(const SettingsScreen()),
                ),
                _buildMenuItem(
                  Icons.verified_user_outlined,
                  "KYC",
                  onTap: () => _navigateTo(const KYCScreen()),
                ),
                const SizedBox(height: 10),
                _buildMenuItem(
                  Icons.logout_outlined,
                  _isLoggingOut ? "Logging out..." : "Logout",
                  color: Colors.redAccent,
                  onTap: _isLoggingOut ? () {} : _handleLogout,
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Decide which image to show: local file preview > network URL > placeholder
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_displayPhoto != null && _displayPhoto!.isNotEmpty) {
      imageProvider = NetworkImage(_displayPhoto!);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 8, 30),
      decoration: const BoxDecoration(
        color: Color(0xFFFF6B35),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──────────────────────────────────────────────────────────
          GestureDetector(
            onTap: _isUploading ? null : _handleImageSelection,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white12,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          )
                        : null,
                  ),
                ),
                if (_isUploading)
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Name / email / badges ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  _displayEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "BUYER",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Join date — now populated from UserProfile.joinedLabel
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.white60,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Joined $_joinedLabel",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Close button ─────────────────────────────────────────────────────
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.white70,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, color: color ?? Colors.black54, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Opacity(
            opacity: 0.5,
            child: Image.asset(
              'assets/images/logo.png',
              height: 25,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.hub_rounded, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Version 1.1.0",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
