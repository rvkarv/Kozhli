import 'nakshatra_calculator.dart';

/// Start and end instants of the Moon's current Nakshatra.
///
/// The boundaries are found from the same Moon calculation used by
/// [NakshatraCalculator.computeCurrent]. Each boundary is bracketed and then
/// binary-searched, so the dashboard does not use a separate timing formula.
class MoonNakshatraWindow {
  final DateTime startUtc;
  final DateTime endUtc;

  const MoonNakshatraWindow({
    required this.startUtc,
    required this.endUtc,
  });

  static MoonNakshatraWindow forUtc(DateTime utc) {
    assert(utc.isUtc, 'Pass a true UTC DateTime.');

    final current = NakshatraCalculator.computeCurrent(utc);
    final currentIndex = current.nakshatraIndex1to27;

    return MoonNakshatraWindow(
      startUtc: _findBoundary(
        utc: utc,
        currentIndex: currentIndex,
        direction: -1,
      ),
      endUtc: _findBoundary(
        utc: utc,
        currentIndex: currentIndex,
        direction: 1,
      ),
    );
  }

  static DateTime _findBoundary({
    required DateTime utc,
    required int currentIndex,
    required int direction,
  }) {
    var inside = utc;
    var outside = utc.add(Duration(hours: direction * 6));

    // A Nakshatra normally lasts about two days. Six-hour steps safely
    // bracket the neighbouring boundary.
    for (var i = 0; i < 16; i++) {
      final index = NakshatraCalculator.computeCurrent(outside)
          .nakshatraIndex1to27;
      if (index != currentIndex) {
        break;
      }
      inside = outside;
      outside = outside.add(Duration(hours: direction * 6));
    }

    // Keep inside on the current-star side and outside on the neighbouring
    // star side. Thirty-six iterations reduce the bracket below one second.
    for (var i = 0; i < 36; i++) {
      final midpoint = DateTime.fromMillisecondsSinceEpoch(
        (inside.millisecondsSinceEpoch + outside.millisecondsSinceEpoch) ~/ 2,
        isUtc: true,
      );

      final midpointIndex = NakshatraCalculator.computeCurrent(midpoint)
          .nakshatraIndex1to27;

      if (midpointIndex == currentIndex) {
        inside = midpoint;
      } else {
        outside = midpoint;
      }
    }

    return outside;
  }
}
