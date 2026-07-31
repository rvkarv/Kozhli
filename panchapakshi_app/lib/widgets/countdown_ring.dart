import 'package:flutter/material.dart';

class CountdownRing extends StatelessWidget {
  final Duration remaining;
  final Duration totalAntharamDuration;
  final String label;

  const CountdownRing({
    super.key,
    required this.remaining,
    required this.totalAntharamDuration,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final total = totalAntharamDuration.inMilliseconds == 0
        ? 1
        : totalAntharamDuration.inMilliseconds;
    final progress =
        (remaining.inMilliseconds.clamp(0, total)) / total;
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: 1 - progress,
              strokeWidth: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6A1B9A)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                h > 0
                    ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                    : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
