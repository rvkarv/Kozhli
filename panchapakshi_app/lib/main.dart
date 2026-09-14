import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/earth_view_screen.dart';
import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/timezone_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
            supportedLocales: const [
              Locale('en'), Locale('ta'), Locale('hi'), Locale('te'), Locale('kn'),
              Locale('ml'), Locale('mr'), Locale('bn'), Locale('gu'), Locale('pa'),
              Locale('as'), Locale('or'), Locale('ur'), Locale('ks'), Locale('kok'),
              Locale('mni'), Locale('sa'), Locale('ne'), Locale('mai'), Locale('doi'),
              Locale('brx'), Locale('sat'), Locale('sd'),
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
            home: const _EarthAwareHome(),
            routes: {
              '/earth-view': (_) => const EarthViewScreen(),
            },
          );
        },
      ),
    );
  }
}

class _EarthAwareHome extends StatefulWidget {
  const _EarthAwareHome();
  @override
  State<_EarthAwareHome> createState() => _EarthAwareHomeState();
}

class _EarthAwareHomeState extends State<_EarthAwareHome> {
  bool earth = false;

  @override
  Widget build(BuildContext context) {
    if (earth) {
      return Stack(
        children: [
          const EarthViewScreen(),
          Positioned(
            left: 14,
            bottom: 14,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'earth-back',
                onPressed: () => setState(() => earth = false),
                child: const Icon(Icons.home),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        const HomeScreen(),
        Positioned(
          right: 14,
          bottom: 74,
          child: SafeArea(
            child: FloatingActionButton.extended(
              heroTag: 'earth-open',
              onPressed: () => setState(() => earth = true),
              icon: const Icon(Icons.public),
              label: const Text('பூமி 0°'),
            ),
          ),
        ),
      ],
    );
  }
}
