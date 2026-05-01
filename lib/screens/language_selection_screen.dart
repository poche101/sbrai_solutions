import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../account_selection_screen.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    // 1. Initialize the localization variable
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF7043), Color(0xFFFF8A65)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.language, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              // 2. Use the variable here to fix the "unused" warning
              Text(
                l10n?.selectLanguage ?? 'Select Language',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              _buildLanguageButton(
                context: context,
                flag: '🇬🇧',
                language: 'English',
                locale: const Locale('en'),
                onTap: () {
                  languageProvider.setLanguage(const Locale('en'));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSelectionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildLanguageButton(
                context: context,
                flag: '🇪🇸',
                language: 'Español',
                locale: const Locale('es'),
                onTap: () {
                  languageProvider.setLanguage(const Locale('es'));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSelectionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildLanguageButton(
                context: context,
                flag: '🇫🇷',
                language: 'Français',
                locale: const Locale('fr'),
                onTap: () {
                  languageProvider.setLanguage(const Locale('fr'));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSelectionScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton({
    required BuildContext context,
    required String flag,
    required String language,
    required Locale locale,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        elevation: 5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 20),
                Text(
                  language,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
