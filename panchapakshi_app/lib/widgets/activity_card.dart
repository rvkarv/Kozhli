import 'package:flutter/material.dart';
import '../models/pakshi.dart';

Color strengthColor(ActivityStrength s) {
  switch (s) {
    case ActivityStrength.best:
      return const Color(0xFF2E7D32); // green
    case ActivityStrength.good:
      return const Color(0xFF66BB6A); // light green
    case ActivityStrength.neutral:
      return const Color(0xFFFFA726); // amber
    case ActivityStrength.bad:
      return const Color(0xFFEF5350); // red
    case ActivityStrength.worst:
      return const Color(0xFFB71C1C); // dark red
  }
}

class ActivityCard extends StatelessWidget {
  final String title;
  final Thozhil activity;
  final String subtitle;
  const ActivityCard({
    super.key,
    required this.title,
    required this.activity,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = strengthColor(activity.strength);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  activity.tamil,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Text('${activity.tamil} (${activity.english})',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
