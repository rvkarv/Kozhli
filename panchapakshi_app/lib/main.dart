import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/app_state.dart';

void main() {
  runApp(const PanchapakshiApp());
}

class PanchapakshiApp extends StatelessWidget {
  const PanchapakshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, app, _) => MaterialApp(
          title: 'கோழி பட்சி',
          debugShowCheckedModeBanner: false,
          locale: app.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF6A1B9A),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
