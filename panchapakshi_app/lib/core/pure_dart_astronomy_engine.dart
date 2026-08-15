import 'dart:math' as math;

/// Dependency-free astronomical calculations used by the boundary layer.
///
/// The Moon longitude follows the existing Meeus lunar periodic model, but is
/// now isolated from the production Panchapakshi calculator so it can be
/// validated independently before replacement.
class PureDartAstronomyEngine {
  static const double _deg = math.pi / 180.0;

  static double _rad(double degrees) => degrees * _deg;

  static double norm(double x) {
    var v = x % (2 * math.pi);
    if (v < 0) v += 2 * math.pi;
    return v;
  }

  static double _mod360(double x) {
    final v = x % 360.0;
    return v < 0 ? v + 360.0 : v;
  }

  static double julianDate(DateTime utc) =>
      utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;

  /// Lahiri sidereal correction, deterministic and dependency-free.
  static double lahiriAyanamsa(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    return (23.85675 + 1.396042 * t + 0.000308 * t * t) * _deg;
  }

  static double siderealLongitude(double tropicalLongitude, double jd) =>
      norm(tropicalLongitude - lahiriAyanamsa(jd));

  /// Tropical apparent solar longitude in radians.
  static double sunLongitude(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final m = _mod360(357.52911 + t * (35999.05029 - 0.0001537 * t));
    final l0 = _mod360(280.46646 + t * (36000.76983 + 0.0003032 * t));
    final c = math.sin(_rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(_rad(2 * m)) * (0.019993 - 0.000101 * t) +
        math.sin(_rad(3 * m)) * 0.000289;
    final trueLongitude = l0 + c;
    return _rad(_mod360(trueLongitude - 0.00569 -
        0.00478 * math.sin(_rad(125.04 - 1934.136 * t))));
  }

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

  /// Tropical Moon ecliptic longitude in radians.
  static double moonLongitude(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    final l = _mod360(218.3164477 + 481267.88123421 * t -
        0.0015786 * t * t + math.pow(t, 3) / 538841.0 -
        math.pow(t, 4) / 65194000.0);
    final d = _mod360(297.8501921 + 445267.1114034 * t -
        0.0018819 * t * t + math.pow(t, 3) / 545868.0 -
        math.pow(t, 4) / 113065000.0);
    final m = _mod360(357.52911 + t * (35999.05029 - 0.0001537 * t));
    final mp = _mod360(134.9633964 + 477198.8675055 * t +
        0.0087414 * t * t + math.pow(t, 3) / 69699.0 -
        math.pow(t, 4) / 14712000.0);
    final f = _mod360(93.272095 + 483202.0175233 * t -
        0.0036539 * t * t - math.pow(t, 3) / 3526000.0 +
        math.pow(t, 4) / 863310000.0);
    final e = 1.0 - 0.002516 * t - 0.0000074 * t * t;

    var sigma = 0.0;
    for (final term in _moonTerms) {
      final ef = math.pow(e, term[1].abs()).toDouble();
      final a = term[0] * d + term[1] * m + term[2] * mp + term[3] * f;
      sigma += term[4] * ef * math.sin(_rad(a));
    }
    final a1 = _mod360(119.75 + 131.849 * t);
    final a2 = _mod360(53.09 + 479264.29 * t);
    sigma += 3958 * math.sin(_rad(a1)) +
        1962 * math.sin(_rad(l - f)) +
        318 * math.sin(_rad(a2));
    return _rad(_mod360(l + sigma / 1000000.0));
  }

  static double moonSiderealLongitude(double jd) =>
      siderealLongitude(_radToDeg(moonLongitude(jd)), jd);

  static double _radToDeg(double r) => r / _deg;

  static ({int index, double fraction}) nakshatraFromLongitude(double longitude) {
    const span = 2 * math.pi / 27.0;
    final raw = norm(longitude) / span;
    final index = raw.floor().clamp(0, 26);
    return (index: index, fraction: raw - index);
  }

  static ({int pada, double fraction}) padaFromNakshatraFraction(double fraction) {
    final p = (fraction * 4).floor().clamp(0, 3);
    return (pada: p + 1, fraction: fraction * 4 - p);
  }

  static List<(double startJd, double endJd)> fourPadas(double startJd, double endJd) {
    final span = (endJd - startJd) / 4.0;
    return List.generate(4, (i) => (startJd + i * span, startJd + (i + 1) * span));
  }

  static double bisectBoundary({
    required double lowJd,
    required double highJd,
    required double Function(double jd) value,
    required double target,
    int iterations = 50,
  }) {
    double signed(double x) {
      var d = norm(x - target);
      if (d > math.pi) d -= 2 * math.pi;
      return d;
    }
    var lo = lowJd;
    var hi = highJd;
    var flo = signed(value(lo));
    for (var i = 0; i < iterations; i++) {
      final mid = (lo + hi) / 2;
      final fm = signed(value(mid));
      if (flo.sign == fm.sign) {
        lo = mid;
        flo = fm;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }
}
