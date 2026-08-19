import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cabme/core/constant/constant.dart';
import 'package:cabme/core/constant/show_toast_dialog.dart';
import 'package:cabme/features/home/controller/dash_board_controller.dart';
import 'package:cabme/features/home/view/dashboard.dart';
import 'package:cabme/features/home/view/limousine_booking_screen.dart';
import 'package:cabme/features/home/view/limousine_bookings_screen.dart';
import 'package:cabme/features/home/view/limousine_review_screen.dart';
import 'package:cabme/features/home/view/ride_payment_selection_screen.dart';
import 'package:cabme/features/settings/profile/controller/settings_controller.dart';
import 'package:cabme/features/ride/ride/model/ride_model.dart';
import 'package:cabme/features/ride/chat/view/conversation_screen.dart';
import 'package:cabme/features/ride/ride/view/trip_history_screen.dart';
import 'package:cabme/common/screens/botton_nav_bar.dart';
import 'package:cabme/features/ride/ride/view/route_view_screen.dart';
import 'package:cabme/features/ride/ride/widget/driver_notification_popup.dart';
import 'package:cabme/features/splash/splash_screen.dart';
import 'package:cabme/service/localization_service.dart';
import 'package:cabme/service/api.dart';
import 'package:cabme/core/themes/styles.dart';
import 'package:cabme/core/utils/Preferences.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cabme/common/widget/notification_dialog.dart';
import 'package:cabme/features/home/view/limousine_payment_screen.dart';
import 'package:cabme/features/home/controller/limousine_controller.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final DarkThemeProvider themeChangeProvider = DarkThemeProvider();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  // Initialize with locale from preferences (synchronously)
  late Locale _currentLocale = LocalizationService.getCurrentLocale();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getCurrentAppTheme();
    setupFCM(context);
    _loadLocale();
    // Listen to locale changes from GetX
    _listenToLocaleChanges();
  }

  void _listenToLocaleChanges() {
    // No listener needed - locale will be reloaded on app restart
  }

  Future<void> _loadLocale() async {
    final locale = LocalizationService.getCurrentLocale();
    if (mounted) {
      setState(() {
        _currentLocale = locale;
      });
      // Always update GetX locale to ensure it's in sync
      Get.updateLocale(locale);
    }
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  Future<void> setupFCM(BuildContext context) async {
    await initializeNotifications();

    // Request notification permissions
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('✅ User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log('⚠️ User granted provisional permission');
    } else {
      log('❌ User declined or has not accepted permission');
    }

    // For iOS, wait for APNS token before subscribing to topics
    if (Platform.isIOS) {
      try {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          // Retry getting APNS token with a delay
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }
        if (apnsToken != null) {
          log('✅ APNS token obtained: $apnsToken');
        } else {
          log('⚠️ APNS token still not available, but proceeding...');
        }
      } catch (e) {
        log('⚠️ Error getting APNS token: $e');
      }
    }

    // Subscribe to topic after ensuring APNS token is available (iOS) or directly (Android)
    try {
      await FirebaseMessaging.instance.subscribeToTopic("cabme_customer");
      log('✅ Subscribed to topic: cabme_customer');
    } catch (e) {
      log('❌ Error subscribing to topic: $e');
      // Retry after a delay if it fails
      await Future.delayed(const Duration(seconds: 2));
      try {
        await FirebaseMessaging.instance.subscribeToTopic("cabme_customer");
        log('✅ Subscribed to topic after retry: cabme_customer');
      } catch (retryError) {
        log('❌ Error subscribing to topic after retry: $retryError');
      }
    }

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Store the notification to show dialog after splash screen
      String title = initialMessage.notification?.title ??
          initialMessage.data['title'] ??
          'Notification';
      String body = initialMessage.notification?.body ??
          initialMessage.data['body'] ??
          initialMessage.data['message'] ??
          '';
      NotificationDialog.setPendingNotification(title, body);
      _handleNotificationTap(initialMessage);
    }

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   log('📨 Foreground message received');
    //   log('🔍 Data: ${jsonEncode(message.data)}');
    //   log('🔍 Notification: ${message.notification?.title} - ${message.notification?.body}');
    //   log('🔍 Type: ${message.data['type'] ?? 'none'}');

    //   if (message.notification != null) {
    //     displayNotification(message);
    //   } else if (message.data.isNotEmpty) {
    //     // Handle data-only messages (for broadcast or other types)
    //     log('📨 Data-only message received, displaying notification');
    //     displayNotification(message);
    //   }
    // });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📨 Foreground message received');
      log('🔍 Data: ${jsonEncode(message.data)}');
      log('🔍 Notification: ${message.notification?.title} - ${message.notification?.body}');
      log('🔍 Type: ${message.data['type'] ?? 'none'}');

      // ===== Handle limousine_approved in foreground =====
      final tag = message.data['tag'] ?? '';
      if (tag == 'limousine_approved') {
        final bookingId = int.tryParse(message.data['booking_id'] ?? '0') ?? 0;
        if (bookingId > 0) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _openLimousinePaymentScreen(bookingId);
          });
        }
        return;
      }
      // ===== End limousine handling =====

      if (message.notification != null) {
        displayNotification(message);
      } else if (message.data.isNotEmpty) {
        // Handle data-only messages (for broadcast or other types)
        log('📨 Data-only message received, displaying notification');
        displayNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Listen for token refresh and update it automatically
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      print('═══════════════════════════════════════════════════════');
      print('🔄 FCM TOKEN REFRESHED');
      print('═══════════════════════════════════════════════════════');
      print('New Token: $newToken');
      print('═══════════════════════════════════════════════════════');
      log('🔄 FCM Token refreshed: $newToken', name: 'FCM_TOKEN');
      _updateTokenToBackend(newToken);
    });

    // Get initial token and update it
    _getAndUpdateToken();
  }

  Future<void> _getAndUpdateToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('═══════════════════════════════════════════════════════');
        print('📱 FCM TOKEN RETRIEVED (App Initialization)');
        print('═══════════════════════════════════════════════════════');
        print('Token: $token');
        print('═══════════════════════════════════════════════════════');
        log('📱 Initial FCM Token: $token', name: 'FCM_TOKEN');
        _updateTokenToBackend(token);
      } else {
        print('⚠️ FCM Token is null');
        log('FCM Token is null');
      }
    } catch (e) {
      print('❌ Error getting initial FCM token: $e');
      log('❌ Error getting initial FCM token: $e');
    }
  }

  Future<void> _updateTokenToBackend(String token) async {
    try {
      // Check if user is logged in
      final userId = Preferences.getInt(Preferences.userId);
      if (userId == 0) {
        log('⚠️ User not logged in, skipping token update');
        return;
      }

      // Try to get dashboard controller if it exists, otherwise update directly
      try {
        if (Get.isRegistered<DashBoardController>()) {
          final dashBoardController = Get.find<DashBoardController>();
          await dashBoardController.updateFCMToken(token);
          log('✅ FCM Token updated successfully via controller');
        } else {
          // Controller not initialized yet, update directly
          await _updateFCMTokenDirectly(token);
          log('✅ FCM Token updated successfully (direct)');
        }
      } catch (e) {
        // Fallback to direct update if controller access fails
        log('⚠️ Controller access failed, trying direct update: $e');
        await _updateFCMTokenDirectly(token);
      }
    } catch (e) {
      log('❌ Error updating FCM token to backend: $e');
    }
  }

  Future<void> _updateFCMTokenDirectly(String token) async {
    try {
      final userModel = Constant.getUserData();
      if (userModel.data == null) {
        log('⚠️ User data not available, skipping token update');
        return;
      }

      final Map<String, dynamic> bodyParams = {
        'user_id': Preferences.getInt(Preferences.userId),
        'fcm_id': token,
        'device_id': "",
        'user_cat': userModel.data!.userCat
      };

      final response = await http.post(
        Uri.parse(API.updateToken),
        headers: API.header,
        body: jsonEncode(bodyParams),
      );

      log('📤 Token update API response: ${response.statusCode}');
      if (response.statusCode == 200) {
        log('✅ FCM Token updated successfully');
      }
    } catch (e) {
      log('❌ Error in direct token update: $e');
    }
  }

  Future<void> initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        // Optional: Handle tap from system tray
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Notifications for important updates and broadcasts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void displayNotification(RemoteMessage message) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Get title and body from notification or data payload
    String title =
        message.notification?.title ?? message.data['title'] ?? 'Notification';
    String body = message.notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        '';

    // Always show system notification with sound for audio feedback
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Show system notification with sound (even if dialog is shown)
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );

    // Also show beautiful dialog if app is in foreground
    if (navigatorKey.currentContext != null) {
      NotificationDialog.show(
        context: navigatorKey.currentContext!,
        title: title,
        message: body,
      );
    }

    log('✅ Notification displayed: $title - $body');
  }

  

  void _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    log('🖱️ Notification tapped: ${jsonEncode(data)}');

    // ===== Limousine approved — open payment screen =====
    // if (data['tag'] == 'limousine_approved') {
    //   final bookingId = int.tryParse(data['booking_id'] ?? '0') ?? 0;
    //   if (bookingId > 0) {
    //     Future.delayed(const Duration(milliseconds: 500), () {
    //       _openLimousinePaymentScreen(bookingId);
    //     });
    //   }
    //   return;
    // }
    if (data['tag'] == 'limousine_approved') {
  final bookingId = int.tryParse(data['booking_id'] ?? '0') ?? 0;
  if (bookingId > 0) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _openLimousinePaymentScreen(bookingId);
    });
  } else {
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.to(() => const LimousineBookingsScreen());
    });
  }
  return;
}
    // Get title and body for dialog
    String title =
        message.notification?.title ?? data['title'] ?? 'Notification';
    String body =
        message.notification?.body ?? data['body'] ?? data['message'] ?? '';

    // Handle broadcast notifications - show dialog and navigate to dashboard
    if (data['type'] == 'broadcast') {
      log('📢 Broadcast notification tapped');

      // Store pending notification to show after app is ready
      NotificationDialog.setPendingNotification(title, body);

      try {
        Get.put(DashBoardController()).selectedDrawerIndex.value = 0;
        await Get.to(() => BottomNavBar());

        // Show dialog after navigation
        Future.delayed(const Duration(milliseconds: 800), () {
          if (navigatorKey.currentContext != null) {
            NotificationDialog.showPendingNotification(
                navigatorKey.currentContext!);
          }
        });
      } catch (e) {
        log('⚠️ Error navigating to dashboard: $e');
      }
      return;
    }

    // For other notification types, also show dialog
    NotificationDialog.setPendingNotification(title, body);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (navigatorKey.currentContext != null) {
        NotificationDialog.showPendingNotification(
            navigatorKey.currentContext!);
      }
    });

    if (data['status'] == "done") {
      await Get.to(
        () => ConversationScreen(),
        arguments: {
          'receiverId': int.parse(
            json.decode(data['message'])['senderId'].toString(),
          ),
          'orderId': int.parse(
            json.decode(data['message'])['orderId'].toString(),
          ),
          'receiverName': json.decode(data['message'])['senderName'].toString(),
          'receiverPhoto':
              json.decode(data['message'])['senderPhoto'].toString(),
        },
      );
    } else if (data['tag'] == 'driver_on_way' ||
        data['tag'] == 'driver_arrived' ||
        data['tag'] == 'driver_arrived_manual') {
      // Handle driver notification taps - navigate to route screen if available
      final rideId = data['ride_id'];
      if (rideId != null) {
        try {
          Get.put(DashBoardController()).selectedDrawerIndex.value = 1;
          await Get.to(() => BottomNavBar());
        } catch (e) {
          log('⚠️ Error navigating to route screen: $e');
        }
      }
    } else if (data['statut'] == "confirmed" ||
        data['statut'] == "driver_rejected") {
      Get.put(DashBoardController()).selectedDrawerIndex.value = 1;
      await Get.to(() => BottomNavBar());
    } else if (data['statut'] == "on ride") {
      var argumentData = {
        'type': 'on_ride'.tr,
        'data': RideData.fromJson(data),
      };
      Get.to(() => const RouteViewScreen(), arguments: argumentData);
    } else if (data['statut'] == "completed") {
      Get.to(
        () => TripHistoryScreen(),
        arguments: {"rideData": RideData.fromJson(data)},
      );
    }
  }

  // Show driver notification popup
  void _showDriverNotificationPopup(
    BuildContext context,
    RemoteMessage message,
    String notificationType,
  ) {
    final data = message.data;
    final title =
        message.notification?.title ?? data['title'] ?? 'Driver Update';
    final body = message.notification?.body ?? data['body'] ?? '';
    final driverName = data['driver_name'] ?? '';
    final eta = data['eta'] ?? data['eta_minutes'] ?? '';

    // Only show driver name if it's not empty (respects admin setting)
    final displayDriverName = driverName.isNotEmpty ? driverName : null;

    DriverNotificationPopup.show(
      context: context,
      title: title,
      message: body,
      driverName: displayDriverName,
      eta: eta.isNotEmpty ? eta : null,
      notificationType: notificationType,
    );
  }


void _schedulePaymentReminder(
    int bookingId, double totalPrice, String vehicleName, int durationHours) {
  showDateTimePicker(bookingId, totalPrice, vehicleName, durationHours);
}

Future<void> showDateTimePicker(
    int bookingId, double totalPrice, String vehicleName, int durationHours) async {
  final picked = await showDatePicker(
    context: navigatorKey.currentContext!,
    initialDate: DateTime.now().add(const Duration(hours: 1)),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 30)),
  );

  if (picked != null && navigatorKey.currentContext != null) {
    final time = await showTimePicker(
      context: navigatorKey.currentContext!,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final scheduled = DateTime(
          picked.year, picked.month, picked.day, time.hour, time.minute);

      Get.to(() => LimousinePaymentScreen(
            bookingId: bookingId,
            totalPrice: totalPrice,
            vehicleName: vehicleName,
            durationHours: durationHours,
          ));

      ShowToastDialog.showToast(
          'تم جدولة الدفع في ${scheduled.day}/${scheduled.month} الساعة ${time.format(navigatorKey.currentContext!)}');
    }
  }
}

//   Future<void> _openLimousinePaymentScreen(int bookingId) async {
//   try {
//     final response = await http.get(
//       Uri.parse('${API.limousineBookingStatus}?booking_id=$bookingId'),
//       headers: API.header,
//     );
//     final body = json.decode(response.body);

//     if (body['success'] == 'Success') {
//       final data = body['data'];
//       final totalPrice = double.tryParse(
//               data['total_price']?.toString() ?? '0') ?? 0.0;
//       final vehicleName = data['vehicle_name']?.toString() ?? '';
//       final durationHours = int.tryParse(
//               data['duration_hours']?.toString() ?? '8') ?? 8;
//       final startDate = data['start_date']?.toString() ?? '';
//       final startTime = data['start_time']?.toString() ?? '';

//       if (navigatorKey.currentContext != null) {
//         // Show dialog first then navigate to payment
//         showDialog(
//           context: navigatorKey.currentContext!,
//           builder: (ctx) => AlertDialog(
//             title: Text('تم قبول طلب الليموزين'),
//             content: Text(
//                 'تم قبول حجز رحلتك، يرجى إتمام الدفع لتأكيد الحجز.\n\nالسيارة: $vehicleName\nالمدة: $durationHours ساعات\nالسعر: $totalPrice د.ك'),
//             actions: [
//               TextButton(
//   onPressed: () {
//     Navigator.of(ctx).pop();
//     _schedulePaymentReminder(bookingId, totalPrice, vehicleName, durationHours);
//   },
//   child: const Text('جدولة الرحلة'),
// ),
//               ElevatedButton(
//   onPressed: () {
//     Navigator.of(ctx).pop();
//     final pickupLocation = data['pickup_location']?.toString() ?? '';
//     Get.to(() => LimousineReviewScreen(
//           bookingId: bookingId,
//           totalPrice: totalPrice,
//           vehicleName: vehicleName,
//           durationHours: durationHours,
//           pickupLocation: pickupLocation,
//           startDate: startDate,
//           startTime: startTime,
//         ));
//   },
//   child: const Text('ادفع الآن'),
// ),
//             ],
//           ),
//         );
//       }
//     }
//   } catch (e) {
//     log('Error opening limousine payment: $e');
//   }
// }


  Future<void> _openLimousinePaymentScreen(int bookingId) async {
  try {
    final response = await http.get(
      Uri.parse('${API.limousineBookingStatus}?booking_id=$bookingId'),
      headers: API.header,
    );
    final body = json.decode(response.body);

    if (body['success'] == 'Success') {
      final data = body['data'];
      final totalPrice =
          double.tryParse(data['total_price']?.toString() ?? '0') ?? 0.0;
      final vehicleName = data['vehicle_name']?.toString() ?? '';
      final durationHours =
          int.tryParse(data['duration_hours']?.toString() ?? '8') ?? 8;
      final startDate = data['start_date']?.toString() ?? '';
      final startTime = data['start_time']?.toString() ?? '';

      // عرض system notification
      final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await flutterLocalNotificationsPlugin.show(
        notifId,
        'limousine_approved_title'.tr,
        '${'vehicle_type'.tr}: $vehicleName | ${'total_label'.tr}: ${totalPrice.toStringAsFixed(3)} ${'KWD'.tr}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );

      if (navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (ctx) => AlertDialog(
            title: Text('limousine_approved_title'.tr),
            content: Text(
              '${'limousine_approved_body'.tr}\n\n'
              '${'vehicle_type'.tr}: $vehicleName\n'
              '${'booking_duration'.tr}: $durationHours ${'hours'.tr}\n'
              '${'total_label'.tr}: ${totalPrice.toStringAsFixed(3)} ${'KWD'.tr}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('later'.tr),
              ),
              ElevatedButton(
  onPressed: () {
    Navigator.of(ctx).pop();
    Get.to(() => RidePaymentSelectionScreen(
          isLimousine: true,
          limousineBookingId: bookingId,
          limousineAmount: totalPrice,
          limousineVehicleName: vehicleName,
          limousineDurationHours: durationHours,
          limousineStartDate: startDate,
          limousineStartTime: startTime,
        ));
  },
  child: Text('pay_now'.tr),
),
            ],
          ),
        );
      }
    }
  } catch (e) {
    log('Error opening limousine payment: $e');
  }
}


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getCurrentAppTheme();
  }

  // void getCurrentAppTheme() async {
  //   themeChangeProvider.darkTheme = await themeChangeProvider.darkThemePreference.getTheme();
  // }

  Future<void> setupInteractedMessage(BuildContext context) async {
    initialize(context);

    // Request notification permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // For iOS, wait for APNS token before subscribing to topics
    if (Platform.isIOS) {
      try {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }
      } catch (e) {
        log('⚠️ Error getting APNS token: $e');
      }
    }

    // Subscribe to topic after ensuring APNS token is available
    try {
      await FirebaseMessaging.instance.subscribeToTopic("cabme_customer");
    } catch (e) {
      log('❌ Error subscribing to topic: $e');
      await Future.delayed(const Duration(seconds: 2));
      try {
        await FirebaseMessaging.instance.subscribeToTopic("cabme_customer");
      } catch (retryError) {
        log('❌ Error subscribing to topic after retry: $retryError');
      }
    }

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {}

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        display(message);

        // Handle driver notification popups
        final data = message.data;
        final tag = data['tag'] ?? '';

        if (tag == 'driver_on_way' ||
            tag == 'driver_arrived' ||
            tag == 'driver_arrived_manual') {
          // Show popup for driver notifications
          _showDriverNotificationPopup(
            context,
            message,
            tag == 'driver_arrived' || tag == 'driver_arrived_manual'
                ? 'arrived'
                : 'on_way',
          );
        }
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.notification != null) {
        if (message.data['status'] == "done") {
          await Get.to(
            ConversationScreen(),
            arguments: {
              'receiverId': int.parse(
                json.decode(message.data['message'])['senderId'].toString(),
              ),
              'orderId': int.parse(
                json.decode(message.data['message'])['orderId'].toString(),
              ),
              'receiverName':
                  json.decode(message.data['message'])['senderName'].toString(),
              'receiverPhoto': json
                  .decode(message.data['message'])['senderPhoto']
                  .toString(),
            },
          );
        } else if (message.data['tag'] == 'driver_on_way' ||
            message.data['tag'] == 'driver_arrived' ||
            message.data['tag'] == 'driver_arrived_manual') {
          // Handle driver notification taps - navigate to route screen if available
          final rideId = message.data['ride_id'];
          if (rideId != null) {
            try {
              DashBoardController dashBoardController = Get.put(
                DashBoardController(),
              );
              dashBoardController.selectedDrawerIndex.value = 1;
              await Get.to(DashBoard());
            } catch (e) {
              log('⚠️ Error navigating to route screen: $e');
            }
          }
        } else if (message.data['statut'] == "confirmed" ||
            message.data['statut'] == "driver_rejected") {
          DashBoardController dashBoardController = Get.put(
            DashBoardController(),
          );
          dashBoardController.selectedDrawerIndex.value = 1;
          await Get.to(DashBoard());
        } else if (message.data['statut'] == "on ride") {
          var argumentData = {
            'type': 'on_ride'.tr,
            'data': RideData.fromJson(message.data),
          };

          Get.to(const RouteViewScreen(), arguments: argumentData);
        } else if (message.data['statut'] == "completed") {
          Get.to(
            TripHistoryScreen(),
            arguments: {"rideData": RideData.fromJson(message.data)},
          );
        }
      }
    });
  }

  Future<void> initialize(BuildContext context) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'Notifications for important updates and broadcasts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: iosInitializationSettings,
    );
    await FlutterLocalNotificationsPlugin().initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) async {},
    );

    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Get title and body from notification or data payload
      String title = message.notification?.title ??
          message.data['title'] ??
          'Notification';
      String body = message.notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          '';

      // Always show system notification with sound for audio feedback
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Show system notification with sound (even if dialog is shown)
      await FlutterLocalNotificationsPlugin().show(
        id,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      log('✅ Notification displayed: $title - $body');
    } on Exception catch (e) {
      log('❌ Error displaying notification: $e');
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Use Get.locale if available, otherwise use _currentLocale
    final currentLocale = Get.locale ?? _currentLocale;
    final isRTL = LocalizationService.isRTL(currentLocale);

    return ChangeNotifierProvider(
      create: (_) => themeChangeProvider,
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          return GetMaterialApp(
            navigatorKey: navigatorKey,
            title: 'Mshwar',
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
              themeChangeProvider.darkTheme == 0
                  ? true
                  : themeChangeProvider.darkTheme == 1
                      ? false
                      : themeChangeProvider.getSystemThem(),
              context,
            ),
            locale: currentLocale,
            fallbackLocale: LocalizationService.locale,
            translations: LocalizationService(),
            // Add Material localizations for date picker, time picker, etc.
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('ar', 'AE'),
              Locale('ur', 'PK'),
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: EasyLoading.init()(context, child),
              );
            },
            home: GetBuilder(
              init: SettingsController(),
              builder: (controller) {
                return const SplashScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
