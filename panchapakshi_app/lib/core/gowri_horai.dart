import 'panchapakshi_rules.dart';

class GowriResult {
  final String name;
  final bool isGood;
  final DateTime start;
  final DateTime end;

  const GowriResult({
    required this.name,
    required this.isGood,
    required this.start,
    required this.end,
  });
}

class HoraiResult {
  final String planet;
  final DateTime start;
  final DateTime end;

  const HoraiResult({
    required this.planet,
    required this.start,
    required this.end,
  });
}

/// Gowri follows the workbook's 8 equal day slots and 8 equal night slots.
/// Day slots are sunrise -> sunset; night slots are sunset -> next sunrise.
/// This is intentionally NOT a fixed 90-minute clock table.
class GowriCalculator {
  static GowriResult forInstant({
    required DateTime local,
    required DateTime sunrise,
    required DateTime sunset,
    required DateTime nextSunrise,
    DateTime? previousSunset,
  }) {
    final isDay = !local.isBefore(sunrise) && local.isBefore(sunset);

    final periodStart = isDay
        ? sunrise
        : (local.isBefore(sunrise)
            ? (previousSunset ?? sunset.subtract(const Duration(days: 1)))
            : sunset);
    final periodEnd = isDay ? sunset : nextSunrise;

    final periodDuration = periodEnd.difference(periodStart);
    final slotDuration = Duration(
      microseconds: periodDuration.inMicroseconds ~/ 8,
    );

    var slotIndex = local
        .difference(periodStart)
        .inMicroseconds ~/ slotDuration.inMicroseconds;
    slotIndex = slotIndex.clamp(0, 7);

    final tableIndex = isDay ? slotIndex : 8 + slotIndex;
    final weekday = local.weekday % 7;
    final name = PanchapakshiRules.gowriTable[tableIndex][weekday];
    final start = periodStart.add(slotDuration * slotIndex);
    final end = slotIndex == 7 ? periodEnd : start.add(slotDuration);

    return GowriResult(
      name: name,
      isGood: PanchapakshiRules.gowriGoodSlots.contains(name),
      start: start,
      end: end,
    );
  }
}

/// Horai follows the workbook's 12 equal day slots and 12 equal night slots.
/// The planetary sequence remains the standard weekday sequence, but each
/// slot length is derived from the actual sunrise/sunset interval.
class HoraiCalculator {
  static HoraiResult forInstant({
    required DateTime local,
    required DateTime sunrise,
    required DateTime sunset,
    required DateTime nextSunrise,
    DateTime? previousSunset,
  }) {
    final isDay = !local.isBefore(sunrise) && local.isBefore(sunset);

    final periodStart = isDay
        ? sunrise
        : (local.isBefore(sunrise)
            ? (previousSunset ?? sunset.subtract(const Duration(days: 1)))
            : sunset);
    final periodEnd = isDay ? sunset : nextSunrise;

    final periodDuration = periodEnd.difference(periodStart);
    final slotDuration = Duration(
      microseconds: periodDuration.inMicroseconds ~/ 12,
    );

    var slotIndex = local
        .difference(periodStart)
        .inMicroseconds ~/ slotDuration.inMicroseconds;
    slotIndex = slotIndex.clamp(0, 11);

    final weekday = local.weekday % 7;
    final startIdx = PanchapakshiRules.horaiStartIndexByWeekday[weekday];
    final planetIdx = (startIdx + slotIndex) % 7;

    final start = periodStart.add(slotDuration * slotIndex);
    final end = slotIndex == 11 ? periodEnd : start.add(slotDuration);

    return HoraiResult(
      planet: PanchapakshiRules.horaiPlanetCycle[planetIdx],
      start: start,
      end: end,
    );
  }
}
