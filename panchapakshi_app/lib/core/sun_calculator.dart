import 'dart:math' as math;

/// Computes sunrise & sunset (local time, as UTC DateTime you convert
/// yourself) for a given date/lat/lng using the standard NOAA solar
/// position algorithm (accurate to ~1 minute — same class of algorithm
/// used by most astrology/panchangam apps).
class SunCalculator {
  /// Returns (sunrise, sunset) as UTC DateTimes for the given calendar
  /// date (interpreted at [lat]/[lng]). Returns null values inside the
  /// record if the sun does not rise/set that day (polar regions).
  static ({DateTime? sunrise, DateTime? sunset}) calculate({
    required DateTime date,
    required double lat,
    required double lng,
  }) {
    final sunrise = _sunEvent(date, lat, lng, isSunrise: true);
    final sunset = _sunEvent(date, lat, lng, isSunrise: false);
    return (sunrise: sunrise, sunset: sunset);
  }

  static DateTime? _sunEvent(DateTime date, double lat, double lng,
      {required bool isSunrise}) {
    const zenith = 90.833; // official sunrise/sunset zenith (incl. refraction)
    final dayOfYear = int.parse(
          DateTime.utc(date.year, date.month, date.day)
              .difference(DateTime.utc(date.year, 1, 1))
              .inDays
              .toString(),
        ) +
        1;

    final lngHour = lng / 15;
    final nominalLocalHour = isSunrise ? 6.0 : 18.0;
    final t = dayOfYear + ((nominalLocalHour - lngHour) / 24);

    final M = (0.9856 * t) - 3.289;
    var L = M +
        (1.916 * _sinDeg(M)) +
        (0.020 * _sinDeg(2 * M)) +
        282.634;
    L = _normalize(L, 360);

    var RA = _atanDeg(0.91764 * _tanDeg(L));
    RA = _normalize(RA, 360);
    final Lquadrant = (L / 90).floor() * 90;
    final RAquadrant = (RA / 90).floor() * 90;
    RA = RA + (Lquadrant - RAquadrant);
    RA = RA / 15;

    final sinDec = 0.39782 * _sinDeg(L);
    final cosDec = _cosDeg(_asinDeg(sinDec));

    final cosH = (_cosDeg(zenith) - (sinDec * _sinDeg(lat))) /
        (cosDec * _cosDeg(lat));

    if (cosH > 1 || cosH < -1) return null; // sun never rises/sets

    var H = isSunrise ? 360 - _acosDeg(cosH) : _acosDeg(cosH);
    H = H / 15;

    final T = H + RA - (0.06571 * t) - 6.622;
    var UT = T - lngHour;
    UT = _normalize(UT, 24);

    final hours = UT.floor();
    final minutesFull = (UT - hours) * 60;
    final minutes = minutesFull.floor();
    final seconds = ((minutesFull - minutes) * 60).round();

    // UT is normalized into 00:00–23:59, but the UTC calendar date can be
    // different from the requested local calendar date. This is especially
    // important for locations west of UTC: Lafayette's Aug 11 sunset is
    // about 00:53 UTC on Aug 12, not 00:53 UTC on Aug 11. Without this day
    // adjustment, converting the event to local time moves the sunset to the
    // previous evening and makes a daytime instant look like "night".
    final utcDayShift = ((nominalLocalHour - lngHour) / 24).floor();

    return DateTime.utc(
      date.year,
      date.month,
      date.day + utcDayShift,
      hours,
      minutes,
      seconds,
    );
  }

  static double _normalize(double v, double mod) {
    var r = v % mod;
    if (r < 0) r += mod;
    return r;
  }

  static double _sinDeg(double d) => math.sin(d * math.pi / 180);
  static double _cosDeg(double d) => math.cos(d * math.pi / 180);
  static double _tanDeg(double d) => math.tan(d * math.pi / 180);
  static double _asinDeg(double v) => math.asin(v) * 180 / math.pi;
  static double _atanDeg(double v) => math.atan(v) * 180 / math.pi;
  static double _acosDeg(double v) => math.acos(v) * 180 / math.pi;
}
