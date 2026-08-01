import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      child: MaterialApp(
        title: 'கோழி பட்சி',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF6A1B9A),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
