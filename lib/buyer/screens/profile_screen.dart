import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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

    String displayName =
        json['full_name'] ??
        userData['name'] ??
        userData['email']?.split('@')[0] ??
        'User';

    return UserProfile(
      fullName: displayName,
      email: userData['email'] ?? 'Not provided',
      phone: json['phone'] ?? userData['phone'] ?? '',
      address: json['address'] ?? userData['address'] ?? '',
      joinDate: formattedDate,
      photoUrl: json['profile_photo'] != null
          ? "https://sbraisolutions.com/storage/${json['profile_photo']}"
          : null,
    );
  }
}

// --- Updated Service ---
class ProfileService {
  final ApiService _api = ApiService();

  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _api.get(
        'buyers/profile', // Removed leading slash
        isProtected: true,
        userType: 'buyer',
      );
      final decoded = jsonDecode(response.body);
      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;
      return UserProfile.fromJson(profileData);
    } catch (e) {
      rethrow;
    }
  }

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
      rethrow;
    }
  }

  Future<UserProfile> uploadAvatar(File imageFile) async {
    try {
      final response = await _api.upload(
        'buyers/profile/upload-photo',
        {},
        filePath: imageFile.path,
        fileField: 'profile_photo',
        isProtected: true,
        userType: 'buyer',
      );

      final decoded = jsonDecode(response.body);
      final profileData = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;

      return UserProfile.fromJson(profileData);
    } catch (e) {
      rethrow;
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
        _showError(e.toString());
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
        _showError(e.toString());
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError("Name cannot be empty");
      return;
    }

    setState(() => _isLoading = true);

    // FIX: Changed 'fullName' to 'name' to match Laravel validation keys
    final updateData = {
      'name': _nameController.text.trim(),
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
        _showError(e.toString());
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
        content: Text(message.replaceFirst('Exception: ', '')),
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
