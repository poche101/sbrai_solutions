import 'package:flutter/material.dart';
import 'account_selection_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/favorite_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/buyers_terms_page.dart';
// Ensure these paths match your project structure
import 'package:sbrai_solutions/vendor/screen/vendor_dashboard_screen.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';

void main() {
  runApp(const SbraiSolutionsApp());
}

class SbraiSolutionsApp extends StatelessWidget {
  const SbraiSolutionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sbrai Solutions',
      theme: ThemeData(
        useMaterial3: true,
        // Using the specific orange branding for Sbrai Solutions
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          primary: const Color(0xFFFF7043),
        ),
        // Fix for "Large UI": Standardize visual density
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),

      // Starting point: User chooses between Buyer or Vendor
      home: const AccountSelectionScreen(),

      // Centralized route management
      routes: {
        '/account-selection': (context) => const AccountSelectionScreen(),
        '/favorites': (context) => const FavoriteScreen(),
        '/terms': (context) => const BuyersTermsPage(),

        // --- Added Vendor Routes ---
        '/vendor-dashboard': (context) => const VendorDashboardScreen(),
        '/post-ad': (context) => const PostAdScreen(),
      },
    );
  }
}
