import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
// Ensure these paths match your project structure
import 'package:sbrai_solutions/buyer_service/api_service.dart';

// --- Updated Data Model ---
class UserProfile {
  String fullName;
  String email;
  String phone;
  String address;
  String joinDate;
  String? photoUrl;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.joinDate,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Check for nested user object or direct fields
    final userData = json['user'] ?? json;

    String formattedDate = "Joined recently";
    String? dateStr = json['created_at'] ?? userData['created_at'];

    if (dateStr != null) {
      try {
        DateTime dt = DateTime.parse(dateStr);
        formattedDate = DateFormat('MMM yyyy').format(dt);
      } catch (e) {
        formattedDate = "N/A";
      }
    }

    // Logic for Dynamic Name:
    String displayName =
        json['full_name'] ??
        json['fullName'] ?? // Added camelCase check based on your debug log
        userData['name'] ??
        userData['email']?.split('@')[0] ??
        'User';

    // Build photo URL safely
    String? rawPhoto = json['profile_photo'] ?? json['photo'];
    String? finalPhotoUrl;
    if (rawPhoto != null && rawPhoto.isNotEmpty) {
      finalPhotoUrl = rawPhoto.startsWith('http')
          ? rawPhoto
          : "https://sbraisolutions.com/storage/$rawPhoto";
    }

    return UserProfile(
      fullName: displayName,
      email: userData['email'] ?? 'Not provided',
      phone: json['phone'] ?? userData['phone'] ?? '',
      address: json['address'] ?? userData['address'] ?? '',
      joinDate: formattedDate,
      photoUrl: finalPhotoUrl,
    );
  }
}

// --- Updated Service ---
class ProfileService {
  final ApiService _api = ApiService();

  /// GET: buyers/profile
  Future<UserProfile> fetchProfile() async {
    try {
      // FIX: Added userType and ensured correct path
      final response = await _api.get(
        'buyers/profile',
        isProtected: true,
        userType: 'buyer',
      );

      final decoded = jsonDecode(response.body);
      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;
      return UserProfile.fromJson(profileData);
    } catch (e) {
      throw Exception("Failed to load profile data: $e");
    }
  }

  /// POST: buyers/profile/update
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(
        'buyers/profile/update',
        data,
        isProtected: true,
        userType: 'buyer',
      );
      final decoded = jsonDecode(response.body);
      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;
      return UserProfile.fromJson(profileData);
    } catch (e) {
      throw Exception("Update failed: $e");
    }
  }

  /// POST (Multipart): buyers/profile/upload-photo
  Future<UserProfile> uploadAvatar(File imageFile) async {
    try {
      // FIX: Added required 'userType' parameter
      final response = await _api.postMultipart(
        'buyers/profile/upload-photo',
        imageFile,
        'profile_photo',
        isProtected: true,
        userType: 'buyer', // <--- FIX HERE
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(decoded['message'] ?? "Server rejected the image");
      }

      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;
      return UserProfile.fromJson(profileData);
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }
}

// --- UI ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  UserProfile _user = UserProfile(
    fullName: "Loading...",
    email: "",
    phone: "",
    address: "",
    joinDate: "",
  );

  final ProfileService _service = ProfileService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadProfile();
  }

  void _updateControllers() {
    _nameController.text = _user.fullName;
    _phoneController.text = _user.phone;
    _addressController.text = _user.address;
  }

  Future<void> _loadProfile() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      final data = await _service.fetchProfile();
      if (mounted) {
        setState(() {
          _user = data;
          _updateControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Connection error: Could not fetch profile.");
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final updatedUser = await _service.uploadAvatar(File(pickedFile.path));

      if (mounted) {
        setState(() {
          _user = updatedUser;
          _isLoading = false;
        });
        _showSuccess("Profile picture updated!");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString().replaceAll("Exception:", ""));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError("Name cannot be empty");
      return;
    }

    setState(() => _isLoading = true);

    final updateData = {
      'fullName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    try {
      final updatedUser = await _service.updateProfile(updateData);
      if (mounted) {
        setState(() {
          _user = updatedUser;
          _updateControllers();
          _isEditing = false;
          _isLoading = false;
        });
        _showSuccess("Profile updated successfully");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Save failed. Please check your internet.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(
                Icons.edit_note,
                color: Color(0xFFFF7043),
                size: 28,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadProfile,
            color: const Color(0xFFFF7043),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildProfileHeaderCard(),
                  const SizedBox(height: 12),
                  _isEditing ? _buildEditForm() : _buildInfoList(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7043)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFF5F2), width: 4),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFFFFF5F2),
                  backgroundImage:
                      _user.photoUrl != null && _user.photoUrl!.isNotEmpty
                      ? NetworkImage(_user.photoUrl!)
                      : null,
                  child: (_user.photoUrl == null || _user.photoUrl!.isEmpty)
                      ? const Icon(
                          Icons.person_outline_rounded,
                          size: 60,
                          color: Color(0xFFFF7043),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7043),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _user.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E267A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Buyer",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                "Joined ${_user.joinDate}",
                style: const TextStyle(color: Color(0xFF757575), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account Information",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _infoTile(Icons.mail_outline_rounded, "Email", _user.email),
          _infoTile(Icons.phone_outlined, "Phone", _user.phone),
          _infoTile(Icons.location_on_outlined, "Address", _user.address),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Edit Information",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _editField("Full Name", _nameController),
          _editField(
            "Phone Number",
            _phoneController,
            keyboardType: TextInputType.phone,
          ),
          _editField("Address", _addressController),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _updateControllers();
                    setState(() => _isEditing = false);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7043),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? "Not provided" : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
