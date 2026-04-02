import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sbrai_solutions/buyer/screens/profile_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/favorite_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/message_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/settings_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/kyc_screen.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/buyer/screens/signin_screen.dart';

// ProfileService and Model imports
import 'package:sbrai_solutions/buyer_service/profile_service.dart' as service;
import 'package:sbrai_solutions/models/buyer/user_profile_model.dart' as model;

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
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  final service.ProfileService _profileService = service.ProfileService();

  bool _isLoggingOut = false;
  bool _isUploading = false;
  bool _isFetching = false;

  String? _fetchedName;
  String? _fetchedEmail;
  String? _fetchedPhoto;
  String? _fetchedJoinDate;

  @override
  void initState() {
    super.initState();
    _fetchedName = widget.userName;
    _fetchedEmail = widget.userEmail;
    _fetchedPhoto = widget.userPhotoUrl;
    _getLatestProfile();
  }

  Future<void> _getLatestProfile() async {
    if (!mounted) return;
    setState(() => _isFetching = true);

    try {
      model.UserProfile profile = await _profileService.fetchProfile();

      if (mounted) {
        setState(() {
          _fetchedName = profile.fullName.isNotEmpty
              ? profile.fullName
              : _fetchedName;
          _fetchedEmail = profile.email.isNotEmpty
              ? profile.email
              : _fetchedEmail;

          // --- THE "STAY ON SCREEN" FIX ---
          if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
            // 1. Server gave us a real URL!
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final connector = profile.photoUrl!.contains('?') ? '&' : '?';
            _fetchedPhoto =
                "${profile.photoUrl}$connector"
                "v=$timestamp";

            // 2. Only now do we stop showing the local File
            _imageFile = null;
          }
          // 3. If profile.photoUrl is NULL, we DO NOT change _fetchedPhoto or _imageFile.
          // This keeps the last known good image on the screen.
        });
      }
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _handleImageSelection() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUploading = true;
        });

        await _profileService.uploadAvatar(_imageFile!);

        if (mounted) {
          _showCustomToast("Profile picture updated!");
          // Wait for the fresh profile data before letting go of the local preview
          await _getLatestProfile();
        }
      }
    } catch (e) {
      debugPrint("Error updating image: $e");
      if (mounted) {
        // Reset local preview only if the actual upload fails
        setState(() => _imageFile = null);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showCustomToast(String message) {
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
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
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

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _apiService.logout();
    } catch (e) {
      await _apiService.clearToken();
    } finally {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
          (route) => false,
        );
      }
    }
  }

  void _navigateTo(Widget screen) {
    if (Navigator.canPop(context)) Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isDesktop ? 280 : MediaQuery.of(context).size.width * 0.80,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _buildUserHeader(context),
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

  Widget _buildUserHeader(BuildContext context) {
    final name =
        _fetchedName ??
        (widget.userName.isNotEmpty ? widget.userName : "Welcome Guest");
    final email =
        _fetchedEmail ??
        (widget.userEmail.isNotEmpty
            ? widget.userEmail
            : "Sign in to sync data");

    final String? photoUrl = _fetchedPhoto ?? widget.userPhotoUrl;
    final joinDate = _fetchedJoinDate ?? "---";

    ImageProvider? imageProvider;
    // We prioritize the local file during the upload/fetch cycle
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl);
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
                    child: (imageProvider == null)
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            "Joined $joinDate",
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
              ],
            ),
          ),
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
