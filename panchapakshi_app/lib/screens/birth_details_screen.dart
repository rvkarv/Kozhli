
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/panchapakshi_rules.dart';
import '../services/app_state.dart';

class BirthDetailsScreen extends StatefulWidget {
  const BirthDetailsScreen({super.key});

  @override
  State<BirthDetailsScreen> createState() => _BirthDetailsScreenState();
}

class _BirthDetailsScreenState extends State<BirthDetailsScreen> {
  String? _rasiStar;
  String? _lagnaStar;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _rasiStar = app.birthNakshatra;
    _lagnaStar = app.birthLagnaNakshatra;
  }

  @override
  Widget build(BuildContext context) {
    final stars = PanchapakshiRules.nakshatraNames;

    return Scaffold(
      appBar: AppBar(title: const Text('பிறந்த விவரம்')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('பிறந்த ராசி நட்சத்திரம் (Birth Rasi Nakshatra)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            isExpanded: true,
            value: _rasiStar,
            hint: const Text('தேர்வு செய்யவும்'),
            items: stars.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _rasiStar = v),
          ),
          const SizedBox(height: 20),
          const Text('பிறந்த லக்னம் நட்சத்திரம் (Birth Lagna Nakshatra)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            isExpanded: true,
            value: _lagnaStar,
            hint: const Text('தேர்வு செய்யவும்'),
            items: stars.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _lagnaStar = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'இன்றைய நட்சத்திரம் தானாக கணிக்கப்படுகிறது.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              final app = context.read<AppState>();
              if (_rasiStar != null) app.setBirthNakshatra(_rasiStar!);
              if (_lagnaStar != null) app.setBirthLagnaNakshatra(_lagnaStar!);
              Navigator.pop(context);
            },
            child: const Text('சேமி (Save)'),
          ),
        ],
      ),
    );
  }
}
