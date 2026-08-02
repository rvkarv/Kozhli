import 'dart:math' as math;

import 'nakshatra_calculator.dart';
import 'panchapakshi_rules.dart';

/// Real astronomical calculation of the current Lagna (ascendant) —
/// transcribed exactly from the workbook's AstroCalc sheet columns
/// AC (GMST) through AK (AscPada). Unlike the Moon's position, the
/// ascendant depends on both the exact instant AND the observer's
/// latitude/longitude, so it needs its own inputs beyond just time.
class LagnaPosition {
  final int rasiIndex1to12;
  final String rasiName;
  final int nakshatraIndex1to27;
  final String nakshatraName;
  final int pada;

  const LagnaPosition({
    required this.rasiIndex1to12,
    required this.rasiName,
    required this.nakshatraIndex1to27,
    required this.nakshatraName,
    required this.pada,
  });
}

class LagnaCalculator {
  static double _rad(double deg) => deg * math.pi / 180.0;
  static double _deg(double rad) => rad * 180.0 / math.pi;

  static double _mod360(double x) {
    final r = x % 360.0;
    return r < 0 ? r + 360.0 : r;
  }

  /// [utc] must be a true UTC instant. [latitude] in degrees (north
  /// positive). [longitudeEastPositive] in degrees (east positive, west
  /// negative) — matches the convention already used by ResolvedLocation
  /// and SunCalculator elsewhere in this app.
  static LagnaPosition computeCurrent({
    required DateTime utc,
    required double latitude,
    required double longitudeEastPositive,
  }) {
    assert(utc.isUtc, 'Pass a true UTC DateTime, not a shifted/local one.');

    final jd = utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
    final t = (jd - 2451545.0) / 36525.0;

    // Mean obliquity of the ecliptic (Meeus 22.2) + nutation correction,
    // same as AstroCalc columns N (MeanObliqEcliptic) and O (ObliqCorr).
    final meanObliq =
        23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
    final obliqCorr =
        meanObliq + 0.00256 * math.cos(_rad(125.04 - 1934.136 * t));

    // Greenwich Mean Sidereal Time (degrees) -> Local Sidereal Time.
    final gmst = _mod360(280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        (t * t * t) / 38710000.0);
    final lst = _mod360(gmst + longitudeEastPositive);

    // Ascendant (tropical), standard formula using obliquity + latitude.
    final ascTropical = _mod360(_deg(math.atan2(
      -(math.sin(_rad(obliqCorr)) * math.tan(_rad(latitude)) +
          math.cos(_rad(obliqCorr)) * math.sin(_rad(lst))),
      math.cos(_rad(lst)),
    )));

    // Same linear Lahiri ayanamsa approximation used by NakshatraCalculator.
    final year = utc.year;
    final startOfYear = DateTime.utc(year, 1, 1);
    final fracYear =
        utc.difference(startOfYear).inSeconds / (365.25 * 24 * 3600);
    final ayanamsa = ((year + fracYear) - 291) * 50.2388475 / 3600;

    final ascSidereal = _mod360(ascTropical - ayanamsa);

    final rasiIndex = (ascSidereal / 30).floor() + 1;
    final nakIndex = (ascSidereal / (40.0 / 3.0)).floor() + 1;
    final pada = ((ascSidereal % (40.0 / 3.0)) / (10.0 / 3.0)).floor() + 1;

    return LagnaPosition(
      rasiIndex1to12: rasiIndex,
      rasiName: NakshatraCalculator.rasiNames[rasiIndex - 1],
      nakshatraIndex1to27: nakIndex,
      nakshatraName: PanchapakshiRules.nakshatraNames[nakIndex - 1],
      pada: pada,
    );
  }
}
