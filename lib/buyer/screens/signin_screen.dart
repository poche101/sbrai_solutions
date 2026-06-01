import 'dart:convert';
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
      // Non-fatal — calls/notifications just won't work until next login
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
        // Save credentials if remember me is checked
        await _saveCredentials();
        // Save FCM token for push notifications and calls
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

  // ── Social Login ───────────────────────────────────────────────────────────
  // ── Social Login ───────────────────────────────────────────────────────────
  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      if (provider == 'google') {
        final response = await _apiService.signInWithGoogle(userType: 'buyer');
        if (response == null) return;

        final responseData = jsonDecode(response.body);

        // Backend returns 'status: true' not 'success: true'
        if ((response.statusCode == 200 || response.statusCode == 201) &&
            responseData['status'] == true) {
          // Token is already saved inside signInWithGoogle → socialLogin
          // Just save user data if present
          if (responseData['data']?['user'] != null) {
            await _apiService.saveUserData(responseData['data']['user']);
          }

          await _saveFcmToken();
          if (!mounted) return;
          _showCustomToast(responseData['message'] ?? 'Signed in with Google');
          _navigateToHome();
        } else {
          throw responseData['message'] ?? 'Google sign-in failed';
        }
      } else if (provider == 'facebook') {
        _showErrorSnackBar('Facebook login is coming soon');
      }
    } catch (e) {
      _showErrorSnackBar('Social login error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                // Logo
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
                // Social buttons
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
                // Divider
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
                // Email field
                _buildInputLabel('Email Address'),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email Address'),
                ),
                const SizedBox(height: 20),
                // Password field
                _buildInputLabel('Password'),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password'),
                ),
                const SizedBox(height: 8),
                // Remember Me Row (Forgot Password Button Removed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                  ],
                ),
                const SizedBox(height: 16),
                // Sign In button
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
                // Sign up link
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
