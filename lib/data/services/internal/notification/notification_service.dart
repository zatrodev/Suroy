import 'dart:async';
import 'dart:io';

import 'package:app/data/repositories/user/user_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, like Firestore,
  // make sure you call `initializeApp` before using them.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
  print("Background Message data: ${message.data}");
  if (message.notification != null) {
    print(
      'Background Message also contained a notification: ${message.notification}',
    );
  }

  if (message.data.isNotEmpty && message.notification == null) {
    final localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // For iOS, ensure you have appropriate permissions set up.
    // requestAlertPermission, requestBadgePermission, requestSoundPermission
    // can be set to true if you want the notification to appear while app is in background.
    // However, FCM data messages are usually for silent updates or to trigger local notifications.
    const DarwinInitializationSettings
    initializationSettingsIOS = DarwinInitializationSettings(
      // defaultPresentAlert: true, // Decide if data-only messages should show an alert by default
      // defaultPresentBadge: true,
      // defaultPresentSound: true,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    // It's important this initialize call is lightweight and doesn't depend on UI.
    // Ensure this doesn't cause issues if called multiple times or if main isolate already did.
    // A common pattern is to use a flag or check if already initialized.
    try {
      await localNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print("Error initializing local_notifications in background: $e");
      // Potentially, it's already initialized by the main app instance if it was recently alive.
    }

    final int notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    final String title = message.data['title'] ?? 'New Message';
    final String body = message.data['body'] ?? 'You have a new message.';
    final String? payload = message.data['payload'];

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'your_channel_id_data_messages',
          'Data Messages',
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

  String? _currentFcmToken;
  String? get currentFcmToken => _currentFcmToken;

  final StreamController<String?> _notificationPayloadStreamController =
      StreamController<String?>.broadcast();
  Stream<String?> get onNotificationPayload =>
      _notificationPayloadStreamController.stream;

  UserRepository? _userRepository;

  Future<void> init({required UserRepository userRepository}) async {
    _userRepository = userRepository;

    await _requestPermissions();
    await _initializeLocalNotifications();
    _configureFirebaseMessagingListeners();
    await _fetchInitialTokenAndSave(); // Fetch and save the initial token

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("FCM Token Refreshed: $newToken");
      _currentFcmToken = newToken;
      if (_userRepository != null) {
        _userRepository!.updateFCMTokens(newToken);
      }
    });
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
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

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // For iOS, specify notification presentation options when app is in foreground
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission:
              true, // Directly request permission if not already handled by FCM
          requestBadgePermission: true,
          requestSoundPermission: true,
          defaultPresentAlert: true, // Show alert even if app is in foreground
          defaultPresentBadge:
              true, // Update badge count even if app is in foreground
          defaultPresentSound: true, // Play sound even if app is in foreground
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS, // Add iOS settings
        );

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

  void _configureFirebaseMessagingListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground FCM Message Received:');
      print('Message ID: ${message.messageId}');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print(
          'Message also contained a notification: ${message.notification!.title} - ${message.notification!.body}',
        );
      }
      _showLocalNotificationFromRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM Message opened app from background:');
      print('Message ID: ${message.messageId}');
      final String? payload =
          message.data['payload'] ?? message.data['travelPlanId'];
      if (payload != null) {
        print("Payload from onMessageOpenedApp: $payload");
        _notificationPayloadStreamController.add(payload);
      }
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('FCM Message opened app from terminated state:');
        print('Message ID: ${message.messageId}');
        final String? payload =
            message.data['payload'] ?? message.data['travelPlanId'];
        if (payload != null) {
          print("Payload from getInitialMessage: $payload");
          _notificationPayloadStreamController.add(payload);
        }
      }
    });
  }

  Future<void> _fetchInitialTokenAndSave() async {
    if (_userRepository == null) {
      print("UserRepository not initialized. Cannot save FCM token.");
      return;
    }

    try {
      String? token;
      token = await _firebaseMessaging.getToken();

      if (token != null) {
        print("Initial FCM Token: $token");
        _currentFcmToken = token;
        await _userRepository!.updateFCMTokens(token);
      } else {
        _currentFcmToken = null;
        print("Failed to get initial FCM token.");
      }
    } catch (e) {
      _currentFcmToken = null;
      print("Error fetching initial FCM token: $e");
    }
  }

  Future<void> _showLocalNotificationFromRemoteMessage(
    RemoteMessage message,
  ) async {
    final String title =
        message.notification?.title ??
        message.data['title'] ??
        'New Notification';
    final String body =
        message.notification?.body ??
        message.data['body'] ??
        'You have a new message.';
    final String? payload =
        message.data['payload'] ?? message.data['travelPlanId'];

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'your_channel_id_foreground',
          'Foreground Notifications',
          channelDescription:
              'Channel for notifications received while app is in foreground.',
          importance: Importance.max,
          priority: Priority.high,
        );
    // iOS will show notifications in foreground by default if permission is granted
    // and if defaultPresentAlert/Badge/Sound are true in DarwinInitializationSettings
    // or if you set these in DarwinNotificationDetails.
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, // Ensure it shows while app is foreground
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showSimpleLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'your_channel_id_generic',
          'Generic App Notifications',
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
    _notificationPayloadStreamController.close();
    // No FCM token stream controller to close anymore
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print(
    'Local Notification Tapped in Background (notificationTapBackground): ${notificationResponse.payload}',
  );
  // IMPORTANT: This function runs in a separate isolate.
  // You CANNOT directly access NotificationService._instance or its streams here.
  // If you need to pass data to the main app, consider:
  // 1. Saving to SharedPreferences and reading it when the app starts.
  // 2. Using a package like `flutter_isolate` or `IsolateNameServer` for communication (more complex).
  // For now, this payload will be handled by `onDidReceiveNotificationResponse` when the app is opened.
  // The _notificationPayloadStreamController.add() in onDidReceiveNotificationResponse
  // will handle it when the app comes to the foreground from this tap.
}
