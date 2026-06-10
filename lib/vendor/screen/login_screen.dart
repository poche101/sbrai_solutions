import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sbrai_solutions/vendor/screen/register_screen.dart';
import 'package:sbrai_solutions/vendor/screen/vendor_home_screen.dart';
import 'package:sbrai_solutions/account_selection_screen.dart';
import '../../services/vendor/vendor_auth_service.dart';
import '../../buyer_service/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _emailKey = 'vendor_saved_email';
  static const _passwordKey = 'vendor_saved_password';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  final VendorAuthService _authService = VendorAuthService();
  final ApiService _apiService = ApiService();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Saved credentials ──────────────────────────────────────────────────────

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_emailKey);
    final savedPassword = prefs.getString(_passwordKey);

    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword ?? '';
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_emailKey, _emailController.text.trim());
      await prefs.setString(_passwordKey, _passwordController.text);
    } else {
      await prefs.remove(_emailKey);
      await prefs.remove(_passwordKey);
    }
  }

  // ── FCM ────────────────────────────────────────────────────────────────────

  Future<void> _saveFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _apiService.saveFcmToken(fcmToken);
        debugPrint('✅ Vendor FCM token saved');
      }
    } catch (e) {
      debugPrint('⚠️ FCM token save failed: $e');
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateToVendorHome() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VendorHomeScreen()),
          (route) => false,
        );
      }
    });
  }

  // ── Toast ──────────────────────────────────────────────────────────────────

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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Email Login ────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _saveCredentials();
      await _saveFcmToken();

      if (mounted) {
        _showSuccessToast('Login successful!');
        _navigateToVendorHome();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Social Login ───────────────────────────────────────────────────────────

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      http.Response? response;

      if (provider == 'google') {
        response = await _apiService.signInWithGoogle(userType: 'vendor');
      } else if (provider == 'facebook') {
        response = await _apiService.signInWithFacebook(userType: 'vendor');
      }

      // User cancelled the native sign-in sheet
      if (response == null) return;

      final responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['status'] == true) {
        // Token + user data already saved inside signInWithGoogle/Facebook
        await _saveFcmToken();
        if (!mounted) return;
        _showSuccessToast(
          responseData['message'] ??
              'Signed in with ${_providerName(provider)}',
        );
        _navigateToVendorHome();
      } else {
        throw responseData['message'] ??
            '${_providerName(provider)} sign-in failed';
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _providerName(String provider) =>
      provider[0].toUpperCase() + provider.substring(1);

  // ── Forgot Password ────────────────────────────────────────────────────────

  void _showForgotPasswordDialog() {
    final TextEditingController forgotEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: !isSending,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Forgot Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the email address linked to your vendor account and we\'ll send you a password reset link.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: forgotEmailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isSending,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'you@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF3F7FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = forgotEmailController.text.trim();
                          if (email.isEmpty) {
                            _showErrorSnackBar('Please enter your email');
                            return;
                          }
                          if (!RegExp(
                            r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(email)) {
                            _showErrorSnackBar(
                              'Please enter a valid email address',
                            );
                            return;
                          }
                          setDialogState(() => isSending = true);
                          try {
                            await _apiService.forgotPassword(email);
                            if (context.mounted) Navigator.pop(context);
                            _showForgotPasswordSuccessDialog(email);
                          } catch (e) {
                            setDialogState(() => isSending = false);
                            _showErrorSnackBar(e.toString());
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7043),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordSuccessDialog(String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFFFF7043),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Check Your Email',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'If a vendor account exists for $email, a password reset link has been sent. Check your inbox and spam folder.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back to Sign In',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showResetPasswordDialog(email);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Enter Reset Token'),
            ),
          ],
        );
      },
    );
  }

  void _showResetPasswordDialog(String email) {
    final TextEditingController tokenController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool isResetting = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Reset Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paste the reset token from your email, then enter your new password.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tokenController,
                      enabled: !isResetting,
                      decoration: InputDecoration(
                        labelText: 'Reset Token',
                        hintText: 'Paste token from email',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF3F7FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      enabled: !isResetting,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'At least 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscureNew = !obscureNew),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F7FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      enabled: !isResetting,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Repeat new password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F7FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          final token = tokenController.text.trim();
                          final newPassword = newPasswordController.text;
                          final confirmPassword =
                              confirmPasswordController.text;

                          if (token.isEmpty) {
                            _showErrorSnackBar('Please enter the reset token');
                            return;
                          }
                          if (newPassword.length < 8) {
                            _showErrorSnackBar(
                              'Password must be at least 8 characters',
                            );
                            return;
                          }
                          if (newPassword != confirmPassword) {
                            _showErrorSnackBar('Passwords do not match');
                            return;
                          }

                          setDialogState(() => isResetting = true);
                          try {
                            final response = await _apiService.resetPassword(
                              token: token,
                              email: email,
                              password: newPassword,
                              passwordConfirmation: confirmPassword,
                            );
                            final data = jsonDecode(response.body);
                            if (context.mounted) Navigator.pop(context);
                            if (data['success'] == true) {
                              _showSuccessToast(
                                'Password reset successfully. Please sign in.',
                              );
                            } else {
                              _showErrorSnackBar(
                                data['message'] ??
                                    'Reset failed. Please try again.',
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isResetting = false);
                            _showErrorSnackBar(e.toString());
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7043),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: isResetting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AccountSelectionScreen()),
            (route) => false,
          ),
        ),
        title: const Text(
          'Sign In',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
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
              // Logo Header
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store,
                        color: Colors.orange,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in to your vendor account',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Social Buttons ─────────────────────────────────────────────
              _buildSocialButton(
                'Continue with Google',
                'assets/icons/google.png',
                () => _handleSocialLogin('google'),
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                'Continue with Facebook',
                'assets/icons/facebook.png',
                () => _handleSocialLogin('facebook'),
              ),

              const SizedBox(height: 24),

              // OR Divider
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.black12)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR SIGN IN WITH EMAIL',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.black12)),
                ],
              ),
              const SizedBox(height: 24),

              // Email Field
              _buildLabel('Email Address'),
              _buildTextField(
                _emailController,
                'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password Field
              _buildLabel('Password'),
              _buildTextField(
                _passwordController,
                'Enter your password',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Remember Me + Forgot Password Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xFFFF7043),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) =>
                              setState(() => _rememberMe = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFFFF7043),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      'Sign Up',
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

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildSocialButton(String text, String assetPath, VoidCallback onTap) {
    final bool isGoogle = text.contains('Google');

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(painter: _GoogleLogoPainter()),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF1877F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'f',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: isGoogle ? Colors.black87 : const Color(0xFF1877F2),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
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
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F7FF),
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
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
      ),
    );
  }
}

// ── Google "G" logo painter ────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);

    final List<Color> colors = [
      const Color(0xFF4285F4),
      const Color(0xFFEA4335),
      const Color(0xFFFBBC05),
      const Color(0xFF34A853),
    ];
    final List<double> starts = [
      -0.05,
      0.45,
      0.70,
      0.95,
    ].map((v) => v * 2 * 3.14159).toList();
    final List<double> sweeps = [
      0.50,
      0.25,
      0.25,
      0.10,
    ].map((v) => v * 2 * 3.14159).toList();

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72);

    for (int i = 0; i < 4; i++) {
      arcPaint.color = colors[i];
      canvas.drawArc(arcRect, starts[i], sweeps[i], false, arcPaint);
    }

    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.09, r * 0.85, size.height * 0.18),
      Paint()..color = Colors.white,
    );

    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.09, r * 0.85, size.height * 0.18),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
