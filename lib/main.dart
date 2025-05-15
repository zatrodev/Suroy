import 'package:app/config/dependencies.dart';
import 'package:app/firebase_options.dart';
import 'package:app/routing/router.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final appTheme = AppTheme(TextTheme());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: appTheme.light(),
      darkTheme: appTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router(context.read()),
    );
  }
}
