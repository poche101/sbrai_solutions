import 'package:flutter/material.dart';
import 'screens/account_selection_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
      ),
      home: const AccountSelectionScreen(),
    );
  }
}
