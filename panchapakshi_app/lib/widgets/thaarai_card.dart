import 'package:flutter/material.dart';
import '../core/thaarai_calculator.dart';

class ThaaraiCard extends StatelessWidget {
  final String title;
  final ThaaraiResult? thaarai;
  final VoidCallback onSetup;
  const ThaaraiCard({
    super.key,
    required this.title,
    required this.thaarai,
    required this.onSetup,
  });

  @override
  Widget build(BuildContext context) {
    if (thaarai == null) {
      return Card(
        child: ListTile(
          title: Text(title),
          subtitle: const Text('பிறந்த நட்சத்திரம் இன்னும் அமைக்கப்படவில்லை'),
          trailing: TextButton(onPressed: onSetup, child: const Text('அமை')),
        ),
      );
    }
    final t = thaarai!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$title (${t.birthNakshatra} → ${t.todayNakshatra})',
                    style: Theme.of(context).textTheme.titleSmall),
                TextButton(onPressed: onSetup, child: const Text('மாற்று')),
              ],
            ),
            const SizedBox(height: 6),
            Text(t.category.tamil,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(t.category.effect, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
