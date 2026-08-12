import 'nakshatra_calculator.dart';

/// UTC start/end instants for the Moon's current Nakshatra and Pada.
///
/// All astronomical boundaries are kept as UTC instants. The selected
/// location's IANA timezone must be applied only when displaying them. This
/// prevents the phone timezone (or today's offset) from leaking into the
/// calculation, including across DST transitions.
class MoonNakshatraWindow {
  final DateTime startUtc;
  final DateTime endUtc;
  final DateTime padaStartUtc;
  final DateTime padaEndUtc;

  const MoonNakshatraWindow({
    required this.startUtc,
    required this.endUtc,
    required this.padaStartUtc,
    required this.padaEndUtc,
  });

  static MoonNakshatraWindow forUtc(DateTime utc) {
    assert(utc.isUtc, 'Pass a true UTC DateTime.');

    final current = NakshatraCalculator.computeCurrent(utc);
    final currentIndex = current.nakshatraIndex1to27;
    final currentPada = current.pada;

    final startUtc = _findBoundary(
      utc: utc,
      currentIndex: currentIndex,
      direction: -1,
    );
    final endUtc = _findBoundary(
      utc: utc,
      currentIndex: currentIndex,
      direction: 1,
    );

    // A Pada is exactly one quarter of a Nakshatra's 13°20' sidereal span.
    // Find the current Pada boundary using the same Moon calculation as the
    // star boundary. For Pada 1/4 the Nakshatra boundary is the corresponding
    // edge, so no second astronomical formula is introduced.
    final padaStartUtc = currentPada == 1
        ? startUtc
        : _findPadaBoundary(
            utc: utc,
            currentIndex: currentIndex,
            currentPada: currentPada,
            direction: -1,
          );
    final padaEndUtc = currentPada == 4
        ? endUtc
        : _findPadaBoundary(
            utc: utc,
            currentIndex: currentIndex,
            currentPada: currentPada,
            direction: 1,
          );

    return MoonNakshatraWindow(
      startUtc: startUtc,
      endUtc: endUtc,
      padaStartUtc: padaStartUtc,
      padaEndUtc: padaEndUtc,
    );
  }

  static DateTime _findBoundary({
    required DateTime utc,
    required int currentIndex,
    required int direction,
  }) {
    var inside = utc;
    var outside = utc.add(Duration(hours: direction * 6));

    for (var i = 0; i < 16; i++) {
      final index = NakshatraCalculator.computeCurrent(outside)
          .nakshatraIndex1to27;
      if (index != currentIndex) {
        break;
      }
      inside = outside;
      outside = outside.add(Duration(hours: direction * 6));
    }

    return _bisect(
      inside: inside,
      outside: outside,
      isInside: (value) =>
          NakshatraCalculator.computeCurrent(value).nakshatraIndex1to27 ==
          currentIndex,
    );
  }

  static DateTime _findPadaBoundary({
    required DateTime utc,
    required int currentIndex,
    required int currentPada,
    required int direction,
  }) {
    var inside = utc;
    var outside = utc.add(Duration(hours: direction * 2));

    // A Pada normally lasts roughly 13 hours. Two-hour steps give a safe
    // bracket while remaining efficient.
    for (var i = 0; i < 24; i++) {
      final moon = NakshatraCalculator.computeCurrent(outside);
      if (moon.nakshatraIndex1to27 != currentIndex ||
          moon.pada != currentPada) {
        break;
      }
      inside = outside;
      outside = outside.add(Duration(hours: direction * 2));
    }

    return _bisect(
      inside: inside,
      outside: outside,
      isInside: (value) {
        final moon = NakshatraCalculator.computeCurrent(value);
        return moon.nakshatraIndex1to27 == currentIndex &&
            moon.pada == currentPada;
      },
    );
  }

  static DateTime _bisect({
    required DateTime inside,
    required DateTime outside,
    required bool Function(DateTime) isInside,
  }) {
    // For a backward search, inside > outside; for a forward search,
    // inside < outside. In both cases the endpoint whose midpoint remains on
    // the current-star/current-pada side is moved toward the boundary.
    for (var i = 0; i < 42; i++) {
      final midpoint = DateTime.fromMillisecondsSinceEpoch(
        (inside.millisecondsSinceEpoch + outside.millisecondsSinceEpoch) ~/ 2,
        isUtc: true,
      );
      if (isInside(midpoint)) {
        inside = midpoint;
      } else {
        outside = midpoint;
      }
    }

    return outside;
  }
}
