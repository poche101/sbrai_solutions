import 'package:flutter/material.dart';
import 'signin_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
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
          "Create Account",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFFFF6B35),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sign Up as Buyer",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Create your account to start shopping",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Social Logins
                _buildSocialButton(
                  "Continue with Google",
                  'assets/icons/google.png',
                  () {
                    // TODO: Implement Google Sign Up
                  },
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  "Continue with Facebook",
                  'assets/icons/facebook.png',
                  () {
                    // TODO: Implement Facebook Sign Up
                  },
                ),

                const SizedBox(height: 24),

                // OR Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black12)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR SIGN UP WITH EMAIL",
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

                // Form Fields
                _buildField("Full Name", "Full Name", Icons.person_outline),
                _buildField("Email Address", "Email", Icons.email_outlined),
                _buildField(
                  "Phone Number",
                  "Phone",
                  Icons.phone_android_outlined,
                ),
                _buildField(
                  "Address (Optional)",
                  "Address",
                  Icons.location_on_outlined,
                ),
                _buildField(
                  "Password",
                  "Enter Password",
                  Icons.lock_outline,
                  isPassword: true,
                ),
                _buildField(
                  "Confirm Password",
                  "Confirm Password",
                  Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 24),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SigninScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Social Button Helper
  Widget _buildSocialButton(String text, String assetPath, VoidCallback onTap) {
    final bool isGoogle = text.contains("Google");
    final Color brandColor = isGoogle
        ? const Color.fromARGB(255, 201, 4, 24)
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              height: 22,
              width: 22,
              errorBuilder: (context, error, stackTrace) => Icon(
                isGoogle ? Icons.g_mobiledata : Icons.facebook,
                color: brandColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    IconData icon, {
    TextEditingController? controller,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: Colors.grey, size: 20),
              filled: true,
              fillColor: const Color(0xFFEDF2F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
