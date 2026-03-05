import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sign In",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ), // Optimized for Desktop & Mobile
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
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.hub_rounded,
                    color: Colors.orange,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Sign in to your account to continue",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Social Logins
                _buildSocialButton(
                  "Continue with Google",
                  'assets/icons/google.png',
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  "Continue with Facebook",
                  'assets/icons/facebook.png',
                ),

                const SizedBox(height: 24),

                // OR Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black12)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR SIGN IN WITH EMAIL",
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
                _buildInputLabel("Email Address"),
                TextField(decoration: _inputDecoration("Email Address")),
                const SizedBox(height: 20),

                // Password Field
                _buildInputLabel("Password"),
                TextField(
                  obscureText: true,
                  decoration: _inputDecoration("Password"),
                ),
                const SizedBox(height: 32),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Up Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign Up",
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

  // Social Button Helper
  Widget _buildSocialButton(String text, String assetPath) {
    // Determine brand colors based on the button text
    final bool isGoogle = text.contains("Google");
    final Color brandColor = isGoogle
        ? const Color.fromARGB(255, 154, 5, 45) // Google Blue
        : const Color(0xFF1877F2); // Facebook Blue

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        // We keep a light border for Google (as per their brand guidelines for white buttons)
        // But we can make the Facebook border match its brand color slightly
        border: Border.all(
          color: isGoogle ? Colors.black12 : brandColor.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          // Add Social Login Logic here
        },
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              height: 22,
              width: 22,
              // The errorBuilder now uses the specific brand colors
              errorBuilder: (context, error, stackTrace) => Icon(
                isGoogle ? Icons.g_mobiledata : Icons.facebook,
                color: brandColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                // Google usually uses a dark grey/black text
                // Facebook can use its own brand color for the text if you want it to pop
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
        padding: const EdgeInsets.only(bottom: 8.0),
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
