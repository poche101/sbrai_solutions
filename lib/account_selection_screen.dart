import 'package:flutter/material.dart';
import 'buyer/widgets/selection_card.dart';
import 'buyer/screens/signup_page.dart';
// Ensure this path is correct for your project
import 'vendor/register_screen.dart';

class AccountSelectionScreen extends StatelessWidget {
  const AccountSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.png',
                height: 50,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.store, color: Colors.orange, size: 50),
              ),
              const SizedBox(height: 12),
              const Text(
                "Building Materials • Furniture •\nProfessional Services",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 30),
              const Text(
                "Create Your Account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Choose how you want to use Store Hub",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Responsive Layout Logic
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBuyerCard(context),
                    const SizedBox(width: 24),
                    _buildVendorCard(context), // Pass context here
                  ],
                )
              else
                Column(
                  children: [
                    _buildBuyerCard(context),
                    const SizedBox(height: 20),
                    _buildVendorCard(context), // Pass context here
                  ],
                ),

              const SizedBox(height: 40),
              const Text(
                "Already have an account?",
                style: TextStyle(color: Colors.grey),
              ),
              TextButton(
                onPressed: () {
                  // You can add logic to go to a login page here later
                },
                child: const Text(
                  "Sign In to Your Account",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "By continuing, you agree to Store Hub's Terms of Service and Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerCard(BuildContext context) {
    return SelectionCard(
      title: "I'm a Buyer",
      description: "Browse products, shop for materials, and hire services",
      icon: Icons.shopping_bag_outlined,
      iconBgColor: const Color(0xFFFFF1EB),
      iconColor: const Color(0xFFFF6B35),
      buttonColor: const Color(0xFFFF6B35),
      buttonText: "Sign Up as Buyer",
      features: const [
        "Search and filter listings",
        "Chat with verified vendors",
        "Book professional services",
        "Location-based search",
      ],
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignupPage()),
        );
      },
    );
  }

  // UPDATED: Added BuildContext context
  Widget _buildVendorCard(BuildContext context) {
    return SelectionCard(
      title: "I'm a Vendor",
      description: "List products, offer services, and grow your business",
      icon: Icons.storefront_outlined,
      iconBgColor: const Color(0xFFE8EAF6),
      iconColor: const Color(0xFF1D267D),
      buttonColor: const Color(0xFF1D267D),
      buttonText: "Sign Up as Vendor",
      features: const [
        "Upload images and list items",
        "Access seller dashboard",
        "Get verified badge",
        "Manage customer chats",
      ],
      onPressed: () {
        // NAVIGATES TO THE REGISTER SCREEN
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
        );
      },
    );
  }
}
