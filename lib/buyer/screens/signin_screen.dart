import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_page.dart';
import 'home_screen.dart';
import 'package:sbrai_solutions/account_selection_screen.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  static const _emailKey = 'buyer_saved_email';
  static const _passwordKey = 'buyer_saved_password';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
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
        debugPrint('✅ Buyer FCM token saved');
      }
    } catch (e) {
      debugPrint('⚠️ FCM token save failed: $e');
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    });
  }

  // ── Toasts ─────────────────────────────────────────────────────────────────
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
            mainAxisSize: MainAxisSize.min,
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
        duration: const Duration(seconds: 3),
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
      ),
    );
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter both email and password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.loginBuyer({
        'email': email,
        'password': password,
      });
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        final token =
            responseData['data']['access_token'] ??
            responseData['data']['token'];
        if (token != null) {
          await _apiService.saveToken(token, userType: 'buyer');
        }
        if (responseData['data']['user'] != null) {
          await _apiService.saveUserData(responseData['data']['user']);
        }
        await _saveCredentials();
        await _saveFcmToken();
        if (!mounted) return;
        _showCustomToast(responseData['message'] ?? 'Signed in successfully');
        _navigateToHome();
      } else {
        throw responseData['message'] ?? 'Login failed. Please try again.';
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                    'Enter the email address linked to your account and we\'ll send you a password reset link.',
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
                      fillColor: const Color(0xFFEDF2F9),
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
                    backgroundColor: const Color(0xFFFF6B35),
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
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFFFF6B35),
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
                'If an account exists for $email, a password reset link has been sent. Check your inbox and spam folder.',
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
                backgroundColor: const Color(0xFFFF6B35),
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
                        fillColor: const Color(0xFFEDF2F9),
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
                        fillColor: const Color(0xFFEDF2F9),
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
                        fillColor: const Color(0xFFEDF2F9),
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
                              _showCustomToast(
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
                    backgroundColor: const Color(0xFFFF6B35),
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

  // ── Social Login ───────────────────────────────────────────────────────────
  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      http.Response? response;

      if (provider == 'google') {
        response = await _apiService.signInWithGoogle(userType: 'buyer');
      } else if (provider == 'facebook') {
        response = await _apiService.signInWithFacebook(userType: 'buyer');
      }

      // User cancelled the native sign-in sheet
      if (response == null) return;

      final responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['status'] == true) {
        // Token is already saved inside signInWithGoogle/signInWithFacebook
        if (responseData['data']?['user'] != null) {
          await _apiService.saveUserData(responseData['data']['user']);
        }
        await _saveFcmToken();
        if (!mounted) return;
        _showCustomToast(
          responseData['message'] ??
              'Signed in with ${_providerName(provider)}',
        );
        _navigateToHome();
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AccountSelectionScreen()),
          ),
        ),
        title: const Text(
          'Sign In',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 50,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.hub_rounded,
                    color: Colors.orange,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Sign in to your account to continue',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                _buildSocialButton(
                  'Continue with Google',
                  'assets/icons/google.png',
                  onTap: () => _handleSocialLogin('google'),
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  'Continue with Facebook',
                  'assets/icons/facebook.png',
                  onTap: () => _handleSocialLogin('facebook'),
                ),
                const SizedBox(height: 24),
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
                _buildInputLabel('Email Address'),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email Address'),
                ),
                const SizedBox(height: 20),
                _buildInputLabel('Password'),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password'),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xFFFF6B35),
                          onChanged: (val) =>
                              setState(() => _rememberMe = val ?? false),
                        ),
                        const Text(
                          'Remember me',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showForgotPasswordDialog,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
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
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────
  Widget _buildSocialButton(
    String text,
    String assetPath, {
    required VoidCallback onTap,
  }) {
    final bool isGoogle = text.contains('Google');
    final Color brandColor = isGoogle
        ? const Color(0xFF9A052D)
        : const Color(0xFF1877F2);
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: isGoogle ? Colors.black12 : brandColor.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              height: 22,
              width: 22,
              errorBuilder: (_, __, ___) => Icon(
                isGoogle ? Icons.g_mobiledata : Icons.facebook,
                color: brandColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: isGoogle ? Colors.black87 : brandColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFEDF2F9),
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
