import 'dart:math' as math;

import 'panchapakshi_rules.dart';

/// Real astronomical calculation of the Moon's current sidereal
/// position (nakshatra, rasi, pada) and lunar phase, using Jean
/// Meeus's standard low-precision solar/lunar longitude formulas
/// ("Astronomical Algorithms") with a linear Lahiri ayanamsa —
/// transcribed exactly from your "Samam_Kaala_Kanippan_corrected.xlsx"
/// workbook's AstroCalc + MoonTerms sheets. This is real astronomy,
/// not an approximation guess — accurate to roughly arc-minute level,
/// which is far more than enough to identify the correct nakshatra.
class MoonPosition {
  final int nakshatraIndex1to27;
  final String nakshatraName;
  final int pada;
  final int rasiIndex1to12;
  final String rasiName;
  final bool isWaxing;

  const MoonPosition({
    required this.nakshatraIndex1to27,
    required this.nakshatraName,
    required this.pada,
    required this.rasiIndex1to12,
    required this.rasiName,
    required this.isWaxing,
  });
}

class NakshatraCalculator {
  static const List<String> rasiNames = [
    'மேஷம்', 'ரிஷபம்', 'மிதுனம்', 'கடகம்', 'சிம்மம்', 'கன்னி',
    'துலாம்', 'விருச்சிகம்', 'தனுசு', 'மகரம்', 'கும்பம்', 'மீனம்',
  ];

  // Meeus Table 47.a (Moon's ecliptic longitude periodic terms),
  // columns: [D_mult, M_mult(sun anomaly), Mp_mult(moon anomaly),
  // F_mult(argument of latitude), coefficient in micro-degrees].
  static const List<List<double>> _moonTerms = [
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

  static double _rad(double deg) => deg * math.pi / 180.0;

  static double _mod360(double x) {
    final r = x % 360.0;
    return r < 0 ? r + 360.0 : r;
  }

  static MoonPosition computeCurrent(DateTime utc) {
    assert(utc.isUtc, 'Pass a true UTC DateTime, not a shifted/local one.');

    final jd = utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
    final t = (jd - 2451545.0) / 36525.0;

    // --- Sun (needed for eccentricity-of-Earth correction + Paksha) ---
    final meanAnomSun = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final eccentEarth = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final geomMeanLongSun =
        _mod360(280.46646 + t * (36000.76983 + t * 0.0003032));
    final sunEqCtr = math.sin(_rad(meanAnomSun)) *
            (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(_rad(2 * meanAnomSun)) * (0.019993 - 0.000101 * t) +
        math.sin(_rad(3 * meanAnomSun)) * 0.000289;
    final sunTrueLong = geomMeanLongSun + sunEqCtr;
    final sunAppLong =
        sunTrueLong - 0.00569 - 0.00478 * math.sin(_rad(125.04 - 1934.136 * t));

    // --- Moon mean elements ---
    final moonMeanLong = _mod360(218.3164477 +
        481267.88123421 * t -
        0.0015786 * t * t +
        math.pow(t, 3) / 538841 -
        math.pow(t, 4) / 65194000);

    final meanElongMoon = _mod360(297.8501921 +
        445267.1114034 * t -
        0.0018819 * t * t +
        math.pow(t, 3) / 545868 -
        math.pow(t, 4) / 113065000);

    final moonMeanAnom = _mod360(134.9633964 +
        477198.8675055 * t +
        0.0087414 * t * t +
        math.pow(t, 3) / 69699 -
        math.pow(t, 4) / 14712000);

    final moonArgLat = _mod360(93.272095 +
        483202.0175233 * t -
        0.0036539 * t * t -
        math.pow(t, 3) / 3526000 +
        math.pow(t, 4) / 863310000);

    final eCorr = 1 - 0.002516 * t - 0.0000074 * t * t;
    final a1 = _mod360(119.75 + 131.849 * t);
    final a2 = _mod360(53.09 + 479264.29 * t);

    double sigmaL = 0;
    for (final term in _moonTerms) {
      final dMul = term[0], mMul = term[1], mpMul = term[2], fMul = term[3];
      final coeff = term[4];
      final eFactor = math.pow(eCorr, mMul.abs());
      final arg = _rad(meanElongMoon * dMul +
          meanAnomSun * mMul +
          moonMeanAnom * mpMul +
          moonArgLat * fMul);
      sigmaL += coeff * eFactor * math.sin(arg);
    }
    sigmaL += 3958 * math.sin(_rad(a1)) +
        1962 * math.sin(_rad(moonMeanLong - moonArgLat)) +
        318 * math.sin(_rad(a2));

    final moonTropicalLong = _mod360(moonMeanLong + sigmaL / 1000000.0);

    // --- Lahiri ayanamsa (linear approximation, as in the workbook) ---
    final year = utc.year;
    final startOfYear = DateTime.utc(year, 1, 1);
    final fracYear =
        utc.difference(startOfYear).inSeconds / (365.25 * 24 * 3600);
    final ayanamsa = ((year + fracYear) - 291) * 50.2388475 / 3600;

    final siderealLong = _mod360(moonTropicalLong - ayanamsa);

    final rasiIndex = (siderealLong / 30).floor() + 1;
    final nakIndex = (siderealLong / (40.0 / 3.0)).floor() + 1;
    final pada = ((siderealLong % (40.0 / 3.0)) / (10.0 / 3.0)).floor() + 1;

    final elongation = _mod360(moonTropicalLong - sunAppLong);
    final isWaxing = elongation < 180;

    return MoonPosition(
      nakshatraIndex1to27: nakIndex,
      nakshatraName: PanchapakshiRules.nakshatraNames[nakIndex - 1],
      pada: pada,
      rasiIndex1to12: rasiIndex,
      rasiName: rasiNames[rasiIndex - 1],
      isWaxing: isWaxing,
    );
  }
}
