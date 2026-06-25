import 'dart:convert';
import 'package:SujaCreations/pages/shop_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../main.dart'; // To access navigatorKey
import '../pages/product_details_page.dart';
import '../pages/order_tracking_page.dart';
import '../pages/cart_page.dart';
import 'woocommerce_api.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // If the message has a data payload but no notification object (or we want to override it)
  // we show our custom rich notification manually.
  if (message.data.isNotEmpty) {
    final service = NotificationService();
    await service.initialize(); // Ensure plugins are ready in this isolate
    await service.showLocalNotification(message);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    debugPrint("NotificationService.initialize() started");
    
    // Initialize timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 1. Request Permission (iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Setup Local Notifications for Foreground & Custom UI
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _handleNavigation(data);
        }
      },
    );

    // Subscribe to general topics
    await _messaging.subscribeToTopic('all_users');
    await _messaging.subscribeToTopic('offers');

    // 3. Listen for Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message.data);
    });

    // Check if app was opened from terminated state via notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage.data);
    }
  }

  Future<void> subscribeToUserTopic(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    await _messaging.subscribeToTopic('phone_$cleanPhone');
    debugPrint("Subscribed to user topic: phone_$cleanPhone");
  }

  Future<void> unsubscribeFromUserTopic(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    await _messaging.unsubscribeFromTopic('phone_$cleanPhone');
    debugPrint("Unsubscribed from user topic: phone_$cleanPhone");
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Use notification title/body if available, fallback to data
    String title = notification?.title ?? data['notification_title'] ?? "New Arrival! 🔥";
    String body = notification?.body ?? data['notification_body'] ?? "Check out our latest collection.";
    String? imageUrl = data['image'] ?? (notification?.android?.imageUrl);

    AndroidNotificationDetails androidDetails;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Big Picture Style
      try {
        final http.Response response = await http.get(Uri.parse(imageUrl));
        final BigPictureStyleInformation bigPictureStyleInformation =
            BigPictureStyleInformation(
          ByteArrayAndroidBitmap.fromBase64String(base64Encode(response.bodyBytes)),
          contentTitle: title,
          summaryText: body,
        );
        androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Main channel for app notifications',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: bigPictureStyleInformation,
        );
      } catch (e) {
        // Fallback to normal style if image fails
        androidDetails = const AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
      }
    } else {
      androidDetails = const AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
    }

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      platformDetails,
      payload: jsonEncode(data),
    );
  }

  void _handleNavigation(Map<String, dynamic> data) async {
    final type = data['type'];
    final productIdStr =
        data['productId'] ??
        data['target_id']; // Handle both legacy and new payload
    final orderIdStr = data['orderId'];
    final screen = data['screen'];
    final targetId = data['target_id'];

    debugPrint(
      "FCM DEBUG: Handling navigation - Type: $type, Screen: $screen, TargetID: $targetId",
    );

    // 1. Order Shipped Navigation
    if (type == 'order_shipped' && orderIdStr != null) {
      final orderId = int.tryParse(orderIdStr.toString());
      if (orderId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => OrderTrackingPage(orderId: orderId),
          ),
        );
      }
      return;
    }

    // 2. Manual Offer Screen Navigation
    if (screen != null) {
      switch (screen) {
        case 'home':
          // Navigate to Home tab
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
          return;
        case 'offers':
          // For now, navigate to Shop as placeholder/sale filter
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => const ShopPage()),
          );
          return;
        case 'product':
          if (targetId != null) {
            _navigateToProduct(targetId.toString());
          }
          return;
        case 'category':
          if (targetId != null) {
            final catId = int.tryParse(targetId.toString());
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ShopPage(
                  categoryId: catId,
                  categoryName: "Category Listing",
                ),
              ),
            );
          }
          return;
        case 'cart_abandonment':
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => const CartPage()),
          );
          return;
      }
    }

    // 3. Fallback / Legacy Product Navigation
    if (productIdStr != null) {
      _navigateToProduct(productIdStr.toString());
    }
  }

  Future<void> scheduleCartAbandonmentNotification(String cartDetails, int minutes) async {
    debugPrint("FCM DEBUG: scheduleCartAbandonmentNotification called with $minutes minutes.");
    
    await cancelCartAbandonmentNotification(); // Cancel existing pending

    try {
      final now = tz.TZDateTime.now(tz.local);
      
      final List<String> titles = [
        "You left something behind! 🛍️",
        "Your cart misses you! 🛒",
        "Don't miss out on these items! ✨",
        "Ready to complete your look? 💎"
      ];
      
      final List<String> bodies = [
        "You left $cartDetails in your cart. Complete your checkout now!",
        "Your beautiful jewelry ($cartDetails) is waiting for you. Grab it before it's gone!",
        "Still thinking about $cartDetails? Checkout now to make it yours.",
        "Your selected items: $cartDetails. Return to your cart to finish shopping!"
      ];
      
      // Schedule up to 10 sequential reminders to act as a "repeating" logic
      for (int i = 1; i <= 10; i++) {
        final scheduledTime = now.add(Duration(minutes: minutes * i));
        
        final title = titles[(i - 1) % titles.length];
        final body = bodies[(i - 1) % bodies.length];
        
        await _localNotifications.zonedSchedule(
          888 + i, // unique IDs: 889, 890, etc.
          title,
          body,
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'cart_abandonment',
              'Cart Reminders',
              channelDescription: 'Reminders for items left in cart',
              importance: Importance.max,
              priority: Priority.high,
              color: Color(0xFF8B5CF6),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({'screen': 'cart_abandonment'}),
        );
      }
      debugPrint("FCM DEBUG: SUCCESS! Scheduled 10 cart abandonment reminders at $minutes min intervals");
    } catch (e) {
      debugPrint("FCM ERROR: Failed to schedule cart abandonment: $e");
    }
  }

  Future<void> cancelCartAbandonmentNotification() async {
    for (int i = 1; i <= 10; i++) {
      await _localNotifications.cancel(888 + i);
    }
    debugPrint("FCM DEBUG: Cart abandonment cancelled.");
  }

  Future<void> _navigateToProduct(String id) async {
    final productId = int.tryParse(id);
    if (productId == null) return;

    try {
      debugPrint("FCM DEBUG: Fetching product details for ID: $productId");
      final api = WooCommerceApi();
      final product = await api.fetchProductById(productId);

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ProductDetailsPage(product: product),
        ),
      );
    } catch (e) {
      debugPrint("Error fetching product for navigation: $e");
    }
  }
}
