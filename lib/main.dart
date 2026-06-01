import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// --- Internal Imports ---
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/l10n/fallback_localizations_delegate.dart';
import 'package:sbrai_solutions/providers/language_provider.dart';
import 'package:sbrai_solutions/services/translation_service.dart';
import 'package:sbrai_solutions/account_selection_screen.dart'; // ← NEW
import 'package:sbrai_solutions/vendor/screen/vendor_home_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/favorite_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/buyers_terms_page.dart';
import 'package:sbrai_solutions/vendor/screen/vendor_dashboard_screen.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';
import 'package:sbrai_solutions/screens/language_selection_screen.dart';
import 'package:sbrai_solutions/firebase_options.dart';
import 'package:sbrai_solutions/providers/favorite_provider.dart';

// --- Background Message Handler ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        Provider(create: (_) => TranslationService()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: const SbraiSolutionsApp(),
    ),
  );
}

class SbraiSolutionsApp extends StatelessWidget {
  const SbraiSolutionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sbrai Solutions',
          theme: _buildTheme(),

          locale: languageProvider.locale,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            GlobalWidgetsLocalizations.delegate,
          ],

          supportedLocales: AppLocalizations.supportedLocales,

          // ✅ Changed from VendorHomeScreen → AccountSelectionScreen
          home: const AccountSelectionScreen(),

          routes: {
            '/account-selection': (context) =>
                const AccountSelectionScreen(), // ← NEW
            '/vendor-home': (context) => const VendorHomeScreen(),
            '/favorites': (context) => const FavoriteScreen(),
            '/terms': (context) => const BuyersTermsPage(),
            '/vendor-dashboard': (context) => const VendorDashboardScreen(),
            '/post-ad': (context) => const PostAdScreen(),
            '/language-selection': (context) => const LanguageSelectionScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6B35),
        primary: const Color(0xFFFF7043),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// SSL Bypass (Development Only)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
