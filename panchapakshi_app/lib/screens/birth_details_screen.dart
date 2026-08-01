import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/panchapakshi_rules.dart';
import '../models/pakshi.dart';
import '../services/app_state.dart';

class BirthDetailsScreen extends StatefulWidget {
  const BirthDetailsScreen({super.key});

  @override
  State<BirthDetailsScreen> createState() => _BirthDetailsScreenState();
}

class _BirthDetailsScreenState extends State<BirthDetailsScreen> {
  String? _rasiStar;
  String? _lagnaStar;
  Paksham? _paksham;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _rasiStar = appState.birthNakshatra;
    _lagnaStar = appState.birthLagnaNakshatra;
    _paksham = appState.birthPaksham;
  }

  @override
  Widget build(BuildContext context) {
    final stars = PanchapakshiRules.nakshatraNames;

    return Scaffold(
      appBar: AppBar(title: const Text('à®ªà®¿à®±à®¨à¯à®¤ à®¨à®Ÿà¯à®šà®¤à¯à®¤à®¿à®°à®®à¯')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('à®ªà®¿à®±à®¨à¯à®¤ à®°à®¾à®šà®¿ à®¨à®Ÿà¯à®šà®¤à¯à®¤à®¿à®°à®®à¯ (Birth Rasi Nakshatra)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'à®‡à®¤à¯ à®’à®°à¯à®®à¯à®±à¯ˆ à®®à®Ÿà¯à®Ÿà¯à®®à¯ à®…à®®à¯ˆà®•à¯à®•à®µà¯à®®à¯. à®‡à®¤à®©à¯ à®…à®Ÿà®¿à®ªà¯à®ªà®Ÿà¯ˆà®¯à®¿à®²à¯ à®¤à®¾à®°à¯ˆ à®•à®£à®•à¯à®•à®¿à®Ÿà®ªà¯à®ªà®Ÿà¯à®®à¯.\n'
            '(Set this once â€” Thaarai is calculated from this.)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            isExpanded: true,
            value: _rasiStar,
            hint: const Text('à®¤à¯‡à®°à¯à®µà¯ à®šà¯†à®¯à¯à®¯à®µà¯à®®à¯'),
            items: stars
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _rasiStar = v),
          ),
          const SizedBox(height: 28),

          const Text('à®ªà®¿à®±à®¨à¯à®¤ à®²à®•à¯à®©à®®à¯ à®¨à®Ÿà¯à®šà®¤à¯à®¤à®¿à®°à®®à¯ (Birth Lagna Nakshatra)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'à®‡à®¤à¯ à®¤à®©à®¿ à®¤à®¾à®°à¯ˆ à®•à®£à®•à¯à®•à¯€à®Ÿà¯à®Ÿà®¿à®±à¯à®•à¯ à®ªà®¯à®©à¯à®ªà®Ÿà¯à®®à¯.\n'
            '(Used for a second, separate Thaarai calculation.)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            isExpanded: true,
            value: _lagnaStar,
            hint: const Text('à®¤à¯‡à®°à¯à®µà¯ à®šà¯†à®¯à¯à®¯à®µà¯à®®à¯'),
            items: stars
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _lagnaStar = v),
          ),
          const SizedBox(height: 28),

          const Text('à®ªà®¿à®±à®¨à¯à®¤ à®ªà®Ÿà¯à®šà®®à¯ (Birth Paksham)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'à®ªà®¿à®±à®¨à¯à®¤ à®¨à¯‡à®°à®¤à¯à®¤à®¿à®²à¯ à®µà®³à®°à¯à®ªà®¿à®±à¯ˆà®¯à®¾ à®¤à¯‡à®¯à¯à®ªà®¿à®±à¯ˆà®¯à®¾ à®Žà®©à¯à®ªà®¤à¯ˆ à®¤à¯‡à®°à¯à®µà¯ à®šà¯†à®¯à¯à®¯à®µà¯à®®à¯.\n'
            'à®‡à®¤à¯ à®‰à®™à¯à®•à®³à¯ à®†à®³à¯à®®à¯ à®ªà®Ÿà¯à®šà®¿ (à®•à¯‹à®´à®¿/à®†à®¨à¯à®¤à¯ˆ/à®•à®¾à®•à®®à¯/à®®à®¯à®¿à®²à¯/à®µà®²à¯à®²à¯‚à®±à¯) '
            'à®Žà®¤à¯ à®Žà®©à¯à®ªà®¤à¯ˆ à®¤à¯€à®°à¯à®®à®¾à®©à®¿à®•à¯à®•à®¿à®±à®¤à¯.\n'
            '(Was it waxing or waning at birth? This determines your ruling '
            'bird.)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<Paksham>(
                  title: const Text('à®µà®³à®°à¯à®ªà®¿à®±à¯ˆ (Waxing)'),
                  value: Paksham.valarpirai,
                  groupValue: _paksham,
                  onChanged: (v) => setState(() => _paksham = v),
                ),
              ),
              Expanded(
                child: RadioListTile<Paksham>(
                  title: const Text('à®¤à¯‡à®¯à¯à®ªà®¿à®±à¯ˆ (Waning)'),
                  value: Paksham.theipirai,
                  groupValue: _paksham,
                  onChanged: (v) => setState(() => _paksham = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: () {
              final appState = context.read<AppState>();
              if (_rasiStar != null) {
                appState.setBirthNakshatra(_rasiStar!);
              }
              if (_lagnaStar != null) {
                appState.setBirthLagnaNakshatra(_lagnaStar!);
              }
              if (_paksham != null) {
                appState.setBirthPaksham(_paksham!);
              }
              Navigator.pop(context);
            },
            child: const Text('à®šà¯‡à®®à®¿ (Save)'),
          ),
        ],
      ),
    );
  }
}
