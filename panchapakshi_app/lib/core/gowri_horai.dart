import 'panchapakshi_rules.dart';

class GowriResult {
  final String name;
  final bool isGood;
  final DateTime start;
  final DateTime end;
  const GowriResult(this.name, this.isGood, this.start, this.end);
}

/// Gowri Panchangam runs on the fixed 24-hour clock (not sun-adjusted):
/// 8 slots of 90 minutes from 06:00 to next-day 06:00.
class GowriCalculator {
  static GowriResult forInstant(DateTime local) {
    // Anchor the 06:00 boundary for "today" relative to local time.
    var anchor = DateTime(local.year, local.month, local.day, 6, 0, 0);
    if (local.isBefore(anchor)) {
      anchor = anchor.subtract(const Duration(days: 1));
    }
    final minutesSinceAnchor = local.difference(anchor).inMinutes;
    final slotIndex = (minutesSinceAnchor / 90).floor().clamp(0, 15);
    final weekday = anchor.weekday % 7; // Sun..Sat -> 0..6
    final name = PanchapakshiRules.gowriTable[slotIndex][weekday];
    final isGood = PanchapakshiRules.gowriGoodSlots.contains(name);
    final start = anchor.add(Duration(minutes: slotIndex * 90));
    final end = start.add(const Duration(minutes: 90));
    return GowriResult(name, isGood, start, end);
  }
}

/// Horai runs on the fixed clock too: 24 one-hour slots from 06:00,
/// planet order cycling with a weekday-dependent start offset.
class HoraiCalculator {
  static String forInstant(DateTime local) {
    var anchor = DateTime(local.year, local.month, local.day, 6, 0, 0);
    if (local.isBefore(anchor)) {
      anchor = anchor.subtract(const Duration(days: 1));
    }
    final hourIndex = local.difference(anchor).inHours.clamp(0, 23);
    final weekday = anchor.weekday % 7;
    final startIdx = PanchapakshiRules.horaiStartIndexByWeekday[weekday];
    final planetIdx = (startIdx + hourIndex) % 7;
    return PanchapakshiRules.horaiPlanetCycle[planetIdx];
  }
}
