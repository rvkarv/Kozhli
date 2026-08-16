import 'dart:math' as math;

import 'panchapakshi_rules.dart';

/// Current astronomical position of the Moon.
///
/// The calculator returns:
///   - sidereal Rasi
///   - sidereal Nakshatra
///   - Pada
///   - waxing / waning phase
///   - diagnostic tropical/sidereal longitudes
///
/// IMPORTANT:
/// [utc] must be a true UTC DateTime.
///
/// The Moon longitude is calculated from the Meeus lunar periodic
/// longitude terms and then converted from tropical to sidereal
/// longitude using Lahiri ayanamsa.
///
/// The public API is intentionally kept compatible with the existing
/// application so that MoonPhase, AppState and the dashboard do not
/// require changes.
class MoonPosition {
  final int nakshatraIndex1to27;
  final String nakshatraName;
  final int pada;

  final int rasiIndex1to12;
  final String rasiName;

  final bool isWaxing;

  // Diagnostic values. These expose the values already calculated by the
  // production algorithm; they do not introduce a second calculation path.
  final double tropicalLongitude;
  final double ayanamsa;
  final double siderealLongitude;

  const MoonPosition({
    required this.nakshatraIndex1to27,
    required this.nakshatraName,
    required this.pada,
    required this.rasiIndex1to12,
    required this.rasiName,
    required this.isWaxing,
    required this.tropicalLongitude,
    required this.ayanamsa,
    required this.siderealLongitude,
  });
}

class NakshatraCalculator {
  static const List<String> rasiNames = [
    'மேஷம்',
    'ரிஷபம்',
    'மிதுனம்',
    'கடகம்',
    'சிம்மம்',
    'கன்னி',
    'துலாம்',
    'விருச்சிகம்',
    'தனுசு',
    'மகரம்',
    'கும்பம்',
    'மீனம்',
  ];

  static const double _nakshatraSize = 360.0 / 27.0;
  static const double _padaSize = _nakshatraSize / 4.0;

  // Meeus lunar longitude periodic terms.
  // Columns:
  // D  = mean elongation of Moon from Sun
  // M  = Sun's mean anomaly
  // M' = Moon's mean anomaly
  // F  = Moon's argument of latitude
  // coefficient = micro-degrees
  static const List<List<int>> _moonTerms = [
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

  static double _rad(double degrees) => degrees * math.pi / 180.0;

  static double _mod360(double value) {
    final result = value % 360.0;
    return result < 0 ? result + 360.0 : result;
  }

  /// Calculates the current Moon position.
  ///
  /// [utc] MUST be a true UTC instant.
  static MoonPosition computeCurrent(DateTime utc) {
    assert(utc.isUtc, 'Pass a true UTC DateTime, not a shifted/local one.');

    final jd = utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
    final t = (jd - 2451545.0) / 36525.0;

    final sunMeanAnomaly = _mod360(357.52911 + t * (35999.05029 - 0.0001537 * t));
    final sunGeometricMeanLongitude = _mod360(280.46646 + t * (36000.76983 + 0.0003032 * t));
    final sunEquationOfCenter =
        math.sin(_rad(sunMeanAnomaly)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(_rad(2.0 * sunMeanAnomaly)) * (0.019993 - 0.000101 * t) +
        math.sin(_rad(3.0 * sunMeanAnomaly)) * 0.000289;
    final sunTrueLongitude = sunGeometricMeanLongitude + sunEquationOfCenter;
    final sunApparentLongitude = sunTrueLongitude - 0.00569 -
        0.00478 * math.sin(_rad(125.04 - 1934.136 * t));

    final moonMeanLongitude = _mod360(
      218.3164477 + 481267.88123421 * t - 0.0015786 * t * t +
          math.pow(t, 3) / 538841.0 - math.pow(t, 4) / 65194000.0,
    );
    final moonMeanElongation = _mod360(
      297.8501921 + 445267.1114034 * t - 0.0018819 * t * t +
          math.pow(t, 3) / 545868.0 - math.pow(t, 4) / 113065000.0,
    );
    final moonMeanAnomaly = _mod360(
      134.9633964 + 477198.8675055 * t + 0.0087414 * t * t +
          math.pow(t, 3) / 69699.0 - math.pow(t, 4) / 14712000.0,
    );
    final moonArgumentOfLatitude = _mod360(
      93.272095 + 483202.0175233 * t - 0.0036539 * t * t -
          math.pow(t, 3) / 3526000.0 + math.pow(t, 4) / 863310000.0,
    );

    final e = 1.0 - 0.002516 * t - 0.0000074 * t * t;
    double sigmaL = 0.0;
    for (final term in _moonTerms) {
      final d = term[0];
      final m = term[1];
      final mp = term[2];
      final f = term[3];
      final coefficient = term[4];
      final eFactor = math.pow(e, m.abs()).toDouble();
      final argument = d * moonMeanElongation + m * sunMeanAnomaly +
          mp * moonMeanAnomaly + f * moonArgumentOfLatitude;
      sigmaL += coefficient * eFactor * math.sin(_rad(argument));
    }

    final a1 = _mod360(119.75 + 131.849 * t);
    final a2 = _mod360(53.09 + 479264.29 * t);
    sigmaL += 3958.0 * math.sin(_rad(a1)) +
        1962.0 * math.sin(_rad(moonMeanLongitude - moonArgumentOfLatitude)) +
        318.0 * math.sin(_rad(a2));

    final moonTropicalLongitude = _mod360(moonMeanLongitude + sigmaL / 1000000.0);
    final ayanamsa = _lahiriAyanamsa(utc);
    final moonSiderealLongitude = _mod360(moonTropicalLongitude - ayanamsa);

    var rasiIndex = (moonSiderealLongitude / 30.0).floor() + 1;
    if (rasiIndex < 1) rasiIndex = 1;
    if (rasiIndex > 12) rasiIndex = 12;

    var nakshatraIndex = (moonSiderealLongitude / _nakshatraSize).floor() + 1;
    if (nakshatraIndex < 1) nakshatraIndex = 1;
    if (nakshatraIndex > 27) nakshatraIndex = 27;

    final nakshatraStart = (nakshatraIndex - 1) * _nakshatraSize;
    final withinNakshatra = moonSiderealLongitude - nakshatraStart;
    var pada = (withinNakshatra / _padaSize).floor() + 1;
    if (pada < 1) pada = 1;
    if (pada > 4) pada = 4;

    final elongation = _mod360(moonTropicalLongitude - sunApparentLongitude);

    return MoonPosition(
      nakshatraIndex1to27: nakshatraIndex,
      nakshatraName: PanchapakshiRules.nakshatraNames[nakshatraIndex - 1],
      pada: pada,
      rasiIndex1to12: rasiIndex,
      rasiName: rasiNames[rasiIndex - 1],
      isWaxing: elongation < 180.0,
      tropicalLongitude: moonTropicalLongitude,
      ayanamsa: ayanamsa,
      siderealLongitude: moonSiderealLongitude,
    );
  }

  static double _lahiriAyanamsa(DateTime utc) {
    final year = utc.year;
    final startOfYear = DateTime.utc(year, 1, 1);
    final elapsedSeconds = utc.difference(startOfYear).inSeconds.toDouble();
    final secondsPerYear = 365.25 * 24.0 * 60.0 * 60.0;
    final fractionalYear = elapsedSeconds / secondsPerYear;
    const arcSecondsPerYear = 50.2388475;
    final totalYears = (year + fractionalYear) - 291.0;
    return totalYears * arcSecondsPerYear / 3600.0;
  }
}