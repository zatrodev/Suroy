import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Import your navigation helper or specific screens if needed for deep linking
// import 'package:app/navigation/navigation_service.dart';
// import 'package:app/ui/travel_plan/travel_plan_detail_screen.dart';

// Must be a top-level function or static method for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(); // Ensure Firebase is initialized for background isolate

  print("Handling a background message: ${message.messageId}");
  print("Background Message data: ${message.data}");
  if (message.notification != null) {
    print(
      'Background Message also contained a notification: ${message.notification}',
    );
  }

  // OPTIONAL: If you receive a data-only message in the background
  // and want to display a local notification, do it here.
  // FCM messages with a "notification" payload are usually handled by the system
  // when the app is in the background/terminated.
  if (message.data.isNotEmpty && message.notification == null) {
    // Example: Construct and show a local notification from data payload
    final localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // Basic initialization for background - ensure icons are set up.
    // This might need more robust setup if not already done in main.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Use your app icon
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await localNotificationsPlugin.initialize(initializationSettings);

    final int notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    final String title = message.data['title'] ?? 'New Message';
    final String body = message.data['body'] ?? 'You have a new message.';
    final String? payload =
        message.data['payload']; // e.g., 'travel_plan_id:xyz'

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'your_channel_id_data_messages', // Unique channel ID
          'Data Messages', // Channel name
          channelDescription:
              'Channel for data messages received in background.',
          importance: Importance.max,
          priority: Priority.high,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    print("Displayed local notification from background data message.");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _fcmTokenStreamController =
      StreamController<String?>.broadcast();
  Stream<String?> get fcmTokenStream => _fcmTokenStreamController.stream;

  // For handling notification taps (both local and FCM that opens app)
  // The payload will typically be what you set in `message.data['payload']` or local notification payload
  final StreamController<String?> _notificationPayloadStreamController =
      StreamController<String?>.broadcast();
  Stream<String?> get onNotificationPayload =>
      _notificationPayloadStreamController.stream;

  Future<void> init(BuildContext? context) async {
    // Context is optional, for navigation
    await _requestPermissions();
    await _initializeLocalNotifications(context);
    _configureFirebaseMessagingListeners(context);
    _fetchAndStreamInitialToken();

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("FCM Token Refreshed: $newToken");
      _fcmTokenStreamController.add(newToken);
      // You should save this newToken to your backend for the user
      // E.g., yourUserRepository.updateFCMToken(newToken);
    });
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional:
          false, // Set to true if you want provisional authorization on iOS
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted FCM permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional FCM permission');
    } else {
      print('User declined or has not accepted FCM permission');
    }

    // For Android 13+, specifically request local notification permission if needed
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      print("Android local notifications permission granted: $granted");
    }
  }

  Future<void> _initializeLocalNotifications(BuildContext? context) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Replace with your app icon

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Local Notification Tapped: payload ${response.payload}");
        if (response.payload != null && response.payload!.isNotEmpty) {
          _notificationPayloadStreamController.add(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  void _configureFirebaseMessagingListeners(BuildContext? context) {
    // For messages received when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground FCM Message Received:');
      print('Message ID: ${message.messageId}');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print(
          'Message also contained a notification: ${message.notification!.title} - ${message.notification!.body}',
        );
      }

      // Display a local notification for foreground messages for consistent UX
      // Or, you could show an in-app banner.
      _showLocalNotificationFromRemoteMessage(message);
    });

    // For messages that open the app from a background state (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM Message opened app from background:');
      print('Message ID: ${message.messageId}');
      final String? payload =
          message.data['payload'] ??
          message.data['travelPlanId']; // Or however you structure it
      if (payload != null) {
        print("Payload from onMessageOpenedApp: $payload");
        _notificationPayloadStreamController.add(payload);
      }
      // Handle navigation if context is available or via a global navigator key
      // e.g., _handlePayloadNavigation(payload, context);
    });

    // Check if app was opened from a terminated state by a notification
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('FCM Message opened app from terminated state:');
        print('Message ID: ${message.messageId}');
        final String? payload =
            message.data['payload'] ?? message.data['travelPlanId'];
        if (payload != null) {
          print("Payload from getInitialMessage: $payload");
          // It's common to pass this initial payload to your first screen
          // or handle it once your app's navigation is ready.
          // For now, we'll add to stream, listening widgets can pick it up.
          _notificationPayloadStreamController.add(payload);
        }
        // e.g., _handlePayloadNavigation(payload, context);
      }
    });
  }

  Future<void> _fetchAndStreamInitialToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("Initial FCM Token: $token");
        _fcmTokenStreamController.add(token);
      } else {
        print("Failed to get initial FCM token.");
        _fcmTokenStreamController.add(null);
      }
    } catch (e) {
      print("Error fetching initial FCM token: $e");
      _fcmTokenStreamController.addError(e);
    }
  }

  Future<void> _showLocalNotificationFromRemoteMessage(
    RemoteMessage message,
  ) async {
    // Use details from FCM message if available, otherwise fallback or use data payload
    final String title =
        message.notification?.title ??
        message.data['title'] ??
        'New Notification';
    final String body =
        message.notification?.body ??
        message.data['body'] ??
        'You have a new message.';
    // Consistent payload key from your Cloud Function's data part
    final String? payload =
        message.data['payload'] ?? message.data['travelPlanId'];

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'your_channel_id_foreground', // Unique channel ID for foreground
          'Foreground Notifications', // Channel name
          channelDescription:
              'Channel for notifications received while app is in foreground.',
          importance: Importance.max,
          priority: Priority.high,
          // icon: '@mipmap/ic_launcher', // Optional: if different from default
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    ); // iOS will show if app is foreground by default with these
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      message.messageId?.hashCode ??
          DateTime.now()
              .millisecondsSinceEpoch, // Unique ID for the notification
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Optional: A helper to display a generic local notification
  Future<void> showSimpleLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'your_channel_id_generic', // Unique channel ID
          'Generic App Notifications', // Channel name
          channelDescription: 'Channel for generic app notifications.',
          importance: Importance.max,
          priority: Priority.high,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  void dispose() {
    _fcmTokenStreamController.close();
    _notificationPayloadStreamController.close();
  }
}

// Top-level function for local notification background tap handling (iOS specific for older versions, Android uses onDidReceiveBackgroundNotificationResponse)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
  print(
    'Local Notification Tapped in Background (notificationTapBackground): ${notificationResponse.payload}',
  );
  // This handler is for flutter_local_notifications.
  // You might want to unify payload handling logic or ensure it doesn't conflict
  // with FCM's onMessageOpenedApp or getInitialMessage if the origin is an FCM message
  // that was then displayed locally.
  // For simplicity, if NotificationService._notificationPayloadStreamController is accessible statically
  // or through a singleton, you could add to it here. But that's tricky from a separate isolate.
  // Better to handle the payload when the app fully starts based on the response.
}
