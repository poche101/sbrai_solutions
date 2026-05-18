import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../services/vendor/vendor_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessCategoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Business category options
  static const List<String> _businessCategories = [
    'Sharp Sand',
    'Granite',
    'Blocks',
    'Cement',
    'Iron Rods',
    'Paints',
    'Furniture',
    'Scaffolding',
    'Logistics',
    'Borehole',
    'Cleaning',
    'Fumigation',
    'Apartments',
    'Houses',
    'Commercial',
    'Land',
  ];

  String? _selectedCategory;

  final VendorAuthService _authService = VendorAuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessCategoryController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint("🚀 UI: Initiating registration for ${_emailController.text}");

      final response = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(), // ✅ fixed: was 'phone:'
        businessName: _businessNameController.text.trim(),
        businessCategory: _selectedCategory!,
        address: _addressController.text.trim(),
        state: _stateController.text.trim(),
        city: _cityController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        // Success: token is nested under data.token, or success flag is true
        final bool isSuccess =
            response['success'] == true ||
            response['status'] == 'success' ||
            response['data']?['token'] != null;

        if (isSuccess) {
          _showSuccessToast(
            response['message']?.toString() ??
                'Registration successful! Please login.',
          );
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          });
        } else {
          throw response['message'] ?? 'Unknown registration error';
        }
      }
    } catch (e) {
      debugPrint("❌ UI ERROR: $e");
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign Up as Vendor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create your business account to\nstart selling',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Personal Info ────────────────────────────────────────────────
              _buildLabel("Full Name"),
              _buildTextField(
                _nameController,
                "Enter your name",
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Full name is required" : null,
              ),

              _buildLabel("Email Address"),
              _buildTextField(
                _emailController,
                "Enter email",
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Email is required";
                  if (!v.contains('@')) return "Enter a valid email";
                  return null;
                },
              ),

              _buildLabel("Phone Number"),
              _buildTextField(
                _phoneController,
                "Enter phone number",
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Phone is required" : null,
              ),

              // ── Business Info ────────────────────────────────────────────────
              _buildLabel("Business Name"),
              _buildTextField(
                _businessNameController,
                "Enter business name",
                validator: (v) => (v == null || v.isEmpty)
                    ? "Business name is required"
                    : null,
              ),

              _buildLabel("Business Category"),
              _buildCategoryDropdown(),

              _buildLabel("Business Address"),
              _buildTextField(
                _addressController,
                "Enter business address",
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Address is required" : null,
              ),

              // State & City side by side
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("State"),
                        _buildTextField(
                          _stateController,
                          "e.g. Lagos",
                          validator: (v) => (v == null || v.isEmpty)
                              ? "State is required"
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("City"),
                        _buildTextField(
                          _cityController,
                          "e.g. Ikeja",
                          validator: (v) => (v == null || v.isEmpty)
                              ? "City is required"
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Password ─────────────────────────────────────────────────────
              _buildLabel("Password"),
              _buildTextField(
                _passwordController,
                "********",
                isPassword: true,
                validator: (v) =>
                    (v != null && v.length < 8) ? "Min 8 characters" : null,
              ),

              _buildLabel("Confirm Password"),
              _buildTextField(
                _confirmPasswordController,
                "********",
                isPassword: true,
                validator: (v) {
                  if (v != _passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // ── Submit ───────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7043),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "Or sign up with",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(Icons.g_mobiledata, Colors.red, () {}),
                  const SizedBox(width: 20),
                  _socialButton(Icons.facebook, Colors.blueAccent, () {}),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    ),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        color: Color(0xFFFF7043),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dropdown for business category ──────────────────────────────────────────
  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        hint: const Text("Select category"),
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFE8F0FE),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        items: _businessCategories
            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
            .toList(),
        onChanged: (val) => setState(() => _selectedCategory = val),
        validator: (v) =>
            (v == null || v.isEmpty) ? "Business category is required" : null,
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        validator:
            validator ??
            (value) =>
                (value == null || value.isEmpty) ? "Required field" : null,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFE8F0FE),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
        ),
      ),
    );
  }
}
