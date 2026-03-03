import 'package:flutter/material.dart';
import 'buyer/screens/account_selection_screen.dart';
import 'package:sbrai_solutions/buyer/screens/favorite_screen.dart'; // Ensure this matches your file path

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
        // Using the specific orange from your screenshot button
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          primary: const Color(0xFFFF7043),
        ),
        // Ensuring scaffolds default to the clean white background
        scaffoldBackgroundColor: Colors.white,
      ),
      // Set this to FavoriteScreen() if you want to see the favorites page immediately on launch
      home: const AccountSelectionScreen(),

      // Adding routes so you can navigate using Navigator.pushNamed(context, '/favorites')
      routes: {
        '/favorites': (context) => const FavoriteScreen(),
        '/account-selection': (context) => const AccountSelectionScreen(),
      },
    );
  }
}
