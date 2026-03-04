import 'package:flutter/material.dart';
import 'buyer/screens/account_selection_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/favorite_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/buyers_terms_page.dart'; // Import your new terms page

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
        // Clean white background across the app
        scaffoldBackgroundColor: Colors.white,
        // Optional: Ensure AppBar looks consistent globally
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),

      // Starting point of the application
      home: const AccountSelectionScreen(),

      // Centralized route management
      routes: {
        '/favorites': (context) => const FavoriteScreen(),
        '/account-selection': (context) => const AccountSelectionScreen(),
        '/terms': (context) =>
            const BuyersTermsPage(), // Named route for Terms & Conditions
      },
    );
  }
}
