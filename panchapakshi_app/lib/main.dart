import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/timezone_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the IANA timezone database before any
  // Panchapakshi calculation requests timezone information.
  TimezoneService.initialize();

  runApp(const PanchapakshiApp());
}

class PanchapakshiApp extends StatelessWidget {
  const PanchapakshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'கோழி பட்சி',
            debugShowCheckedModeBanner: false,
            locale: app.locale,
            // Indian scheduled-language locale coverage plus English.
            supportedLocales: const [
              Locale('en'),
              Locale('ta'),
              Locale('hi'),
              Locale('te'),
              Locale('kn'),
              Locale('ml'),
              Locale('mr'),
              Locale('bn'),
              Locale('gu'),
              Locale('pa'),
              Locale('as'),
              Locale('or'),
              Locale('ur'),
              Locale('ks'),
              Locale('kok'),
              Locale('mni'),
              Locale('sa'),
              Locale('ne'),
              Locale('mai'),
              Locale('doi'),
              Locale('brx'),
              Locale('sat'),
              Locale('sd'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF6A1B9A),
              useMaterial3: true,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
