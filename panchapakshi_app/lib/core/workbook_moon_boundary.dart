import 'dart:math' as math;

/// Pure-Dart implementation of the Moon sidereal longitude formula used by
/// the Master Workbook.
///
/// This is intentionally isolated from the UI-facing NakshatraCalculator so
/// the Workbook boundary solver can reproduce the established two-step
/// boundary calculation exactly.
class WorkbookMoonBoundary {
  static const List<List<int>> _terms = [
    [0, 0, 1, 0, 6288774], [2, 0, -1, 0, 1274027], [2, 0, 0, 0, 658314],
    [0, 0, 2, 0, 213618], [0, 1, 0, 0, -185116], [0, 0, 0, 2, -114332],
    [2, 0, -2, 0, 58793], [2, -1, -1, 0, 57066], [2, 0, 1, 0, 53322],
    [2, -1, 0, 0, 45758], [0, 1, -1, 0, -40923], [1, 0, 0, 0, -34720],
    [0, 1, 1, 0, -30383], [2, 0, 0, -2, 15327], [0, 0, 1, 2, -12528],
    [0, 0, 1, -2, 10980], [4, 0, -1, 0, 10675], [0, 0, 3, 0, 10034],
    [4, 0, -2, 0, 8548], [2, 1, -1, 0, -7888], [2, 1, 0, 0, -6766],
    [1, 0, -1, 0, -5163], [1, 1, 0, 0, 4987], [2, -1, 1, 0, 4036],
    [2, 0, 2, 0, 3994], [4, 0, 0, 0, 3861], [2, 0, -3, 0, 3665],
    [0, 1, -2, 0, -2689], [2, 0, -1, 2, -2602], [2, -1, -2, 0, 2390],
    [1, 0, 1, 0, -2348], [2, -2, 0, 0, 2236], [0, 1, 2, 0, -2120],
    [0, 2, 0, 0, -2069], [2, -2, -1, 0, 2048], [2, 0, 1, -2, -1773],
    [2, 0, 0, 2, -1595], [4, -1, -1, 0, 1215], [0, 0, 2, 2, -1110],
    [3, 0, -1, 0, -892], [2, 1, 1, 0, -810], [4, -1, -2, 0, 759],
    [0, 2, -1, 0, -713], [2, 2, -1, 0, -700], [2, 1, -2, 0, 691],
    [2, -1, 0, -2, 596], [4, 0, 1, 0, 549], [0, 0, 4, 0, 537],
    [4, -1, 0, 0, 520], [1, 0, -2, 0, -487], [2, 1, 0, -2, -399],
    [0, 0, 2, -2, -381], [1, 1, 1, 0, 351], [3, 0, -2, 0, -340],
    [4, 0, -3, 0, 330], [2, -1, 2, 0, 327], [0, 2, 1, 0, -323],
    [1, 1, -1, 0, 299], [2, 0, 3, 0, 294], [2, 0, -1, -2, 0],
  ];

  static double _rad(double value) => value * math.pi / 180.0;
  static double _mod360(double value) => ((value % 360.0) + 360.0) % 360.0;

  static double siderealLongitude(DateTime utc) {
    final jd = utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
    final t = (jd - 2451545.0) / 36525.0;

    final meanLongitude = _mod360(
      218.3164477 + 481267.88123421 * t - 0.0015786 * t * t +
          math.pow(t, 3) / 538841.0 - math.pow(t, 4) / 65194000.0,
    );
    final elongation = _mod360(
      297.8501921 + 445267.1114034 * t - 0.0018819 * t * t +
          math.pow(t, 3) / 545868.0 - math.pow(t, 4) / 113065000.0,
    );
    final sunAnomaly = _mod360(
      357.52911 + t * (35999.05029 - 0.0001537 * t),
    );
    final moonAnomaly = _mod360(
      134.9633964 + 477198.8675055 * t + 0.0087414 * t * t +
          math.pow(t, 3) / 69699.0 - math.pow(t, 4) / 14712000.0,
    );
    final argumentLatitude = _mod360(
      93.272095 + 483202.0175233 * t - 0.0036539 * t * t -
          math.pow(t, 3) / 3526000.0 + math.pow(t, 4) / 863310000.0,
    );
    final e = 1.0 - 0.002516 * t - 0.0000074 * t * t;

    var sigmaL = 0.0;
    for (final term in _terms) {
      final d = term[0];
      final m = term[1];
      final mp = term[2];
      final f = term[3];
      final coefficient = term[4];
      final argument = d * elongation + m * sunAnomaly + mp * moonAnomaly +
          f * argumentLatitude;
      sigmaL += coefficient * math.pow(e, m.abs()).toDouble() *
          math.sin(_rad(argument));
    }

    sigmaL += 3958.0 * math.sin(_rad(_mod360(119.75 + 131.849 * t)));
    sigmaL += 1962.0 * math.sin(_rad(meanLongitude - argumentLatitude));
    sigmaL += 318.0 * math.sin(_rad(_mod360(53.09 + 479264.29 * t)));

    final tropical = _mod360(meanLongitude + sigmaL / 1000000.0);
    final ayanamsa = _lahiriAyanamsa(utc);
    return _mod360(tropical - ayanamsa);
  }

  static double _lahiriAyanamsa(DateTime utc) {
    final year = utc.year;
    final startOfYear = DateTime.utc(year, 1, 1);
    final elapsedSeconds = utc.difference(startOfYear).inSeconds.toDouble();
    final fractionalYear = elapsedSeconds / (365.25 * 24.0 * 60.0 * 60.0);
    const arcSecondsPerYear = 50.2388475;
    final totalYears = (year + fractionalYear) - 291.0;
    return totalYears * arcSecondsPerYear / 3600.0;
  }

  static double wrappedDegrees(double value) {
    var result = value % 360.0;
    if (result > 180.0) result -= 360.0;
    if (result <= -180.0) result += 360.0;
    return result;
  }

  static DateTime workbookBoundary({
    required DateTime utc,
    required double targetSiderealLongitude,
  }) {
    final now = siderealLongitude(utc);
    final plus12 = siderealLongitude(utc.add(const Duration(hours: 12)));
    final minus12 = siderealLongitude(utc.subtract(const Duration(hours: 12)));
    final velocity = wrappedDegrees(plus12 - minus12);
    if (velocity.abs() < 1e-9) {
      throw StateError('Moon longitude velocity is too small.');
    }

    final firstCorrectionDays = wrappedDegrees(now - targetSiderealLongitude) / velocity;
    final first = utc.subtract(Duration(microseconds:
        (firstCorrectionDays * Duration.microsecondsPerDay).round()));

    final firstLongitude = siderealLongitude(first);
    final secondCorrectionDays = wrappedDegrees(firstLongitude - targetSiderealLongitude) / velocity;
    return first.subtract(Duration(microseconds:
        (secondCorrectionDays * Duration.microsecondsPerDay).round()));
  }
}
