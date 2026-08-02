import 'package:flutter/material.dart';
import '../core/day_ruler_rules.dart';
import '../models/pakshi.dart';

class DayRulerCard extends StatelessWidget {
  final Pakshi bird;
  final DayRulerInfo info;
  const DayRulerCard({super.key, required this.bird, required this.info});

  @override
  Widget build(BuildContext context) {
    final isRulerToday = info.ruler == bird;
    final isSubordinateToday = info.subordinate == bird;

    return Card(
      color: isRulerToday
          ? Colors.green.withOpacity(0.08)
          : isSubordinateToday
              ? Colors.red.withOpacity(0.08)
              : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('இன்றைய அதிகார நாள் (Day ruler)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text('அதிகார பட்சி: ${info.ruler.tamil}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('படுபட்சி: ${info.subordinate.tamil}'),
            Text('பகை: ${info.enemies.map((e) => e.tamil).join(", ")}'),
            Text('நட்பு: ${info.friend.tamil}'),
            if (isRulerToday)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('இன்று கோழியின் அதிகார நாள்! ✅',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            if (isSubordinateToday)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('இன்று கோழி படுபட்சி நிலையில் உள்ளது',
                    style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
