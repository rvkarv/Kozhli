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

  @override
  void initState() {
    super.initState();
    _rasiStar = context.read<AppState>().birthNakshatra;
  }

  @override
  Widget build(BuildContext context) {
    final stars = PanchapakshiRules.nakshatraNames;

    return Scaffold(
      appBar: AppBar(title: const Text('பிறந்த நட்சத்திரம்')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('பிறந்த ராசி நட்சத்திரம் (Birth Rasi Nakshatra)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'இன்றைய நட்சத்திரம் தானாக கணிக்கப்படுகிறது — இது மட்டும் ஒருமுறை அமைக்கவும்.\n'
            "(Today's transiting star is now calculated automatically — "
            'you only need to set your birth star, once.)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            isExpanded: true,
            value: _rasiStar,
            hint: const Text('தேர்வு செய்யவும்'),
            items: stars
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _rasiStar = v),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              if (_rasiStar != null) {
                context.read<AppState>().setBirthNakshatra(_rasiStar!);
              }
              Navigator.pop(context);
            },
            child: const Text('சேமி (Save)'),
          ),
        ],
      ),
    );
  }
}
