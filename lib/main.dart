import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

// --- Internal Imports ---
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/l10n/fallback_localizations_delegate.dart';
import 'package:sbrai_solutions/providers/language_provider.dart';
import 'package:sbrai_solutions/services/translation_service.dart';
import 'package:sbrai_solutions/account_selection_screen.dart';
import 'package:sbrai_solutions/vendor/screen/vendor_home_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/favorite_screen.dart';
import 'package:sbrai_solutions/buyer/screens/settings/buyers_terms_page.dart';
import 'package:sbrai_solutions/vendor/screen/vendor_dashboard_screen.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';
import 'package:sbrai_solutions/screens/language_selection_screen.dart';
import 'package:sbrai_solutions/firebase_options.dart';
import 'package:sbrai_solutions/providers/favorite_provider.dart';
import 'package:sbrai_solutions/services/notification_service.dart';

// ── Background Message Handler ─────────────────────────────────────────────
// Must be a top-level function — Flutter requires this for background isolates.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Re-initialize Firebase if the background isolate doesn't have it yet
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  final localNotif = FlutterLocalNotificationsPlugin();
  await localNotif.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final data = message.data;
  final type = data['type'];
  final channelId = type == 'new_listing' ? 'listings' : 'general';
  final channelName = type == 'new_listing' ? 'New Listings' : 'General';

  await localNotif.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    data['title'] ?? 'Sbrai Hub',
    data['body'] ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      ),
    ),
  );

  debugPrint("📩 Background message handled: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase core
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Register background handler before anything else
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Request notification permissions
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  // 4. Initialize NotificationService
  await NotificationService.init();

  // 5. Initialize Facebook SDK — required on all platforms before any
  //    FacebookAuth call, otherwise you get MissingPluginException on init.
  if (kIsWeb) {
    // Web needs explicit JS SDK init; mobile handles it via native SDK
    // but webAndDesktopInitialize is safe to call on all platforms.
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: "YOUR_FACEBOOK_APP_ID", // replace with your actual app ID
      cookie: true,
      xfbml: true,
      version: "v19.0",
    );
  }

  // 6. Warm up Google Sign-In — optional but prevents a cold-start delay
  //    on first tap. Silently signs in if a previous session exists.
  try {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId:
          '247352594282-ngifekbhv3s8q078tm6cofc29l2slvmo.apps.googleusercontent.com',
    );
    await googleSignIn.signInSilently();
  } catch (_) {
    // Not signed in previously — that's fine, ignore.
  }

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

          home: const AccountSelectionScreen(),

          routes: {
            '/account-selection': (context) => const AccountSelectionScreen(),
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

// ── SSL Bypass (Development Only) ──────────────────────────────────────────
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
