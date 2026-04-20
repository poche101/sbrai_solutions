import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// --- Internal Imports ---
import 'account_selection_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/favorite_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/buyers_terms_page.dart';
import 'package:sbrai_solutions/vendor/screen/vendor_dashboard_screen.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';

// 1. Import your generated firebase_options file
// Run 'flutterfire configure' in your terminal to generate this file
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background process
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // Ensure Flutter is ready for async calls before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with platform-specific options
  // This is the line that fixes the [core/no-app] error
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Set up Background Notification Listener
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. Request Permissions for Push Notifications
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // 5. SSL Bypass for local Laravel development
  HttpOverrides.global = MyHttpOverrides();

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
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const AccountSelectionScreen(),
      routes: {
        '/account-selection': (context) => const AccountSelectionScreen(),
        '/favorites': (context) => const FavoriteScreen(),
        '/terms': (context) => const BuyersTermsPage(),
        '/vendor-dashboard': (context) => const VendorDashboardScreen(),
        '/post-ad': (context) => const PostAdScreen(),
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
