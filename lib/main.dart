import 'dart:async';

import 'package:app/config/dependencies.dart';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/data/services/internal/notification/notification_service.dart';
import 'package:app/firebase_options.dart';
import 'package:app/routing/router.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(MultiProvider(providers: providers, child: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final appTheme = AppTheme(TextTheme());
  Future<void>? _notificationServiceInitialization;
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _currentUserSubscription;
  StreamSubscription? _notificationPayloadSubscription;
  bool _hasInitializedNotificationServiceForCurrentUser = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userRepository = context.read<UserRepository>();

        _currentUserSubscription?.cancel();
        _currentUserSubscription = userRepository.currentUser.listen((user) {
          if (!mounted) return;

          if (user != null &&
              !_hasInitializedNotificationServiceForCurrentUser) {
            print(
              "MainApp: User logged in (${user.username}). Initializing NotificationService.",
            );
            _hasInitializedNotificationServiceForCurrentUser =
                true; // Mark as initialized

            _notificationPayloadSubscription?.cancel();

            setState(() {
              _notificationServiceInitialization = _notificationService.init(
                userRepository: userRepository,
              );
            });

            _notificationPayloadSubscription = _notificationService
                .onNotificationPayload
                .listen((payload) {
                  if (payload != null && payload.isNotEmpty) {
                    if (mounted) {
                      _handleNotificationTap(payload);
                    }
                  }
                });
          } else if (user == null &&
              _hasInitializedNotificationServiceForCurrentUser) {
            print(
              "MainApp: User logged out. Resetting NotificationService state.",
            );
            _hasInitializedNotificationServiceForCurrentUser = false;

            _notificationPayloadSubscription?.cancel();
            _notificationPayloadSubscription = null;

            if (mounted) {
              setState(() {
                _notificationServiceInitialization = null;
              });
            }
          }
        });
      }
    });
  }

  void _handleNotificationTap(String payload) {
    print("MyApp: Handling tapped notification payload: $payload");
    if (payload.startsWith(Routes.plans)) {
      context.go(payload);
    } else if (payload.startsWith("planId:")) {
      final planId = payload.split(":")[1];
      context.goNamed(
        'planDetails',
        pathParameters: {'id': planId},
      ); // Example named route
    } else if (payload == Routes.profile) {
      context.go(Routes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _notificationServiceInitialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Error initializing app: ${snapshot.error}. Please restart.',
                ),
              ),
            ),
          );
        }

        return MaterialApp.router(
          theme: appTheme.light(),
          darkTheme: appTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: router(context.read()),
        );
      },
    );
  }
}
