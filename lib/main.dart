import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/cart_provider.dart';
import 'services/wishlist_provider.dart';
import 'services/user_provider.dart';
import 'services/navigation_provider.dart';
import 'pages/phone_login_page.dart';
import 'pages/main_navigation_page.dart';
import 'services/notification_service.dart';
import 'pages/splash_page.dart';
import 'services/address_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'core/app_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize server-side config
  bool configSuccess = true;
  try {
    await AppConfig.initialize();
  } catch (e) {
    configSuccess = false;
    debugPrint("App Initialization Failed: $e");
  }

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    configSuccess 
    ? MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, CartProvider>(
          create: (context) => CartProvider(),
          update: (context, user, cart) =>
              cart!..updateUser(user.currentCustomer?.id),
        ),
        ChangeNotifierProxyProvider<UserProvider, WishlistProvider>(
          create: (context) => WishlistProvider(),
          update: (context, user, wishlist) =>
              wishlist!..updateUser(user.currentCustomer?.id),
        ),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProxyProvider<UserProvider, AddressProvider>(
          create: (context) => AddressProvider(),
          update: (context, user, address) =>
              address!..updateUser(user.currentCustomer?.id, user.currentCustomer),
        ),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const MyApp(),
    )
    : const InitializationErrorApp(),
  );
}

class InitializationErrorApp extends StatelessWidget {
  const InitializationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 80, color: Colors.redAccent),
                const SizedBox(height: 24),
                const Text(
                  "Connection Error",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "We couldn't connect to the server to fetch secure settings. Please check your internet and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(), // Retry
                  child: const Text("Retry Connection"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Suja Creations',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
