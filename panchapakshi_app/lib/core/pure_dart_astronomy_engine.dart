import 'dart:math' as math;

/// Small, dependency-free astronomical boundary engine.
///
/// This module deliberately separates astronomy from Panchapakshi rules:
/// Sun/Moon positions are converted to sidereal Lahiri longitude, while
/// Nakshatra boundaries are found by time-domain root search.  Pada timing is
/// then derived from the actual Nakshatra interval, matching the Master
/// Workbook methodology.
class PureDartAstronomyEngine {
  static const double _deg = math.pi / 180.0;
  static const double _rad = 180.0 / math.pi;

  /// Mean Lahiri ayanamsa approximation, retained as a deterministic fallback
  /// so the app has no ephemeris/license dependency.  The APP's existing
  /// astronomical constants can be substituted here without changing the
  /// boundary-search layer.
  static double lahiriAyanamsa(double jd) {
    final t = (jd - 2451545.0) / 36525.0;
    return (23.85675 + 1.396042 * t + 0.000308 * t * t) * _deg;
  }

  /// Normalize an angle to 0..2pi.
  static double norm(double x) {
    var v = x % (2 * math.pi);
    if (v < 0) v += 2 * math.pi;
    return v;
  }

  /// Sidereal longitude from a supplied tropical longitude.
  static double siderealLongitude(double tropicalLongitude, double jd) {
    return norm(tropicalLongitude - lahiriAyanamsa(jd));
  }

  /// Nakshatra index (0-based) and fractional position within it.
  static ({int index, double fraction}) nakshatraFromLongitude(
    double siderealLongitude,
  ) {
    const span = 13.0 * math.pi / 180.0 + math.pi / 180.0 / 3.0;
    final x = norm(siderealLongitude);
    final raw = x / span;
    final index = raw.floor().clamp(0, 26);
    return (index: index, fraction: raw - index);
  }

  /// Convert a Nakshatra boundary fraction to its four padas.
  static ({int pada, double fraction}) padaFromNakshatraFraction(
    double fraction,
  ) {
    final p = (fraction * 4).floor().clamp(0, 3);
    return (pada: p + 1, fraction: fraction * 4 - p);
  }

  /// Find a boundary by bisection. `value` must be a continuous angular
  /// quantity whose target is `target` in radians.  The caller supplies the
  /// Moon/Sun longitude calculation appropriate to the selected date.
  static double bisectBoundary({
    required double lowJd,
    required double highJd,
    required double Function(double jd) value,
    required double target,
    int iterations = 50,
  }) {
    double unwrap(double x) {
      var d = norm(x - target);
      if (d > math.pi) d -= 2 * math.pi;
      return d;
    }

    var lo = lowJd;
    var hi = highJd;
    var flo = unwrap(value(lo));
    for (var i = 0; i < iterations; i++) {
      final mid = (lo + hi) / 2;
      final fm = unwrap(value(mid));
      if (flo.sign == fm.sign) {
        lo = mid;
        flo = fm;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  /// Derive four equal Pada intervals from an exact Nakshatra interval.
  static List<(double startJd, double endJd)> fourPadas(
    double nakshatraStartJd,
    double nakshatraEndJd,
  ) {
    final span = (nakshatraEndJd - nakshatraStartJd) / 4.0;
    return List.generate(
      4,
      (i) => (
        nakshatraStartJd + i * span,
        nakshatraStartJd + (i + 1) * span,
      ),
    );
  }
}
