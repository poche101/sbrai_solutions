import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sbrai_solutions/buyer/screens/profile_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/favorite_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/message_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/settings_screen.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/buyer/screens/signin_screen.dart';

// Added ProfileService (with alias) and Model imports (with alias)
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
  bool _isFetching = false; // Track profile fetching state

  // Local state for fetched profile data
  String? _fetchedName;
  String? _fetchedEmail;
  String? _fetchedPhoto;

  @override
  void initState() {
    super.initState();
    _getLatestProfile();
  }

  Future<void> _getLatestProfile() async {
    if (!mounted) return;
    setState(() => _isFetching = true);

    try {
      // 1. Get the profile from the service
      model.UserProfile profile = await _profileService.fetchProfile();

      if (mounted) {
        setState(() {
          _fetchedName = profile.fullName;
          _fetchedEmail = profile.email;
          _fetchedPhoto = profile.photoUrl;
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
          _getLatestProfile(); // Refresh header data
        }
      }
    } catch (e) {
      debugPrint("Error updating image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to upload image"),
            backgroundColor: Colors.red,
          ),
        );
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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
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
      debugPrint("Plugin failed, clearing local data manually: $e");
      await _apiService.clearToken();
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        _showCustomToast("Logged out successfully");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isDesktop ? 280 : MediaQuery.of(context).size.width * 0.75,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _buildUserHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildMenuItem(
                  Icons.home_outlined,
                  "Home",
                  onTap: () => Navigator.pop(context),
                ),
                _buildMenuItem(
                  Icons.person_outline,
                  "My Profile",
                  onTap: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.favorite_outline,
                  "Favorites",
                  onTap: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoriteScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.chat_bubble_outline,
                  "Messages",
                  onTap: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessageScreen(),
                      ),
                    );
                  },
                ),
                const Divider(
                  height: 40,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                _buildMenuItem(
                  Icons.settings_outlined,
                  "Settings",
                  onTap: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.logout_outlined,
                  _isLoggingOut ? "Logging out..." : "Logout",
                  color: Colors.red,
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
    // Show loader while fetching if we don't have local data yet
    if (_isFetching && _fetchedName == null) {
      return Container(
        height: 160,
        width: double.infinity,
        color: const Color(0xFFFF6B35),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final name =
        _fetchedName ??
        (widget.userName.isNotEmpty ? widget.userName : "No Name Found");
    final email =
        _fetchedEmail ??
        (widget.userEmail.isNotEmpty ? widget.userEmail : "No Email Found");
    final photo = _fetchedPhoto ?? widget.userPhotoUrl;

    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (photo != null && photo.isNotEmpty) {
      imageProvider = NetworkImage(photo);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 15, 25),
      color: const Color(0xFFFF6B35),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _handleImageSelection,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                    if (_isUploading)
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Buyer",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.black54, size: 24),
            ),
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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 30,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.hub_rounded, color: Colors.orange, size: 30),
          ),
          const SizedBox(height: 5),
          const Text(
            "Version 1.1",
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
