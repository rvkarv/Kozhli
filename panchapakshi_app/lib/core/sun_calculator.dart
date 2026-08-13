import 'dart:math' as math;

/// Computes sunrise and sunset as true UTC instants for the requested
/// calendar date at the supplied latitude/longitude.
///
/// The calculation is independent of the phone timezone. Callers convert the
/// resulting UTC instants through the selected location's IANA timezone.
class SunCalculator {
  /// Returns sunrise and sunset as UTC DateTimes for the requested local
  /// calendar date. Returns null for an event only in polar regions where
  /// the sun does not rise/set.
  static ({DateTime? sunrise, DateTime? sunset}) calculate({
    required DateTime date,
    required double lat,
    required double lng,
  }) {
    final sunrise = _sunEvent(date, lat, lng, isSunrise: true);
    final sunset = _sunEvent(date, lat, lng, isSunrise: false);
    return (sunrise: sunrise, sunset: sunset);
  }

  /// NOAA-style solar calculation using the equation of time and solar
  /// declination. The returned DateTime is a UTC instant.
  ///
  /// The UTC event is allowed to cross the UTC calendar boundary. This is
  /// essential for western locations such as Lafayette, Louisiana, where an
  /// evening sunset can occur on the next UTC date while remaining on the
  /// same local calendar date.
  static DateTime? _sunEvent(
    DateTime date,
    double lat,
    double lng, {
    required bool isSunrise,
  }) {
    const zenith = 90.833;

    final n = DateTime.utc(date.year, date.month, date.day)
            .difference(DateTime.utc(date.year, 1, 1))
            .inDays +
        1;

    final gamma = 2 * math.pi / 365.0 * (n - 1);

    final equationOfTime =
        229.18 *
        (0.000075 +
            0.001868 * math.cos(gamma) -
            0.032077 * math.sin(gamma) -
            0.014615 * math.cos(2 * gamma) -
            0.040849 * math.sin(2 * gamma));

    final declination =
        0.006918 -
        0.399912 * math.cos(gamma) +
        0.070257 * math.sin(gamma) -
        0.006758 * math.cos(2 * gamma) +
        0.000907 * math.sin(2 * gamma) -
        0.002697 * math.cos(3 * gamma) +
        0.001480 * math.sin(3 * gamma);

    final latitudeRad = lat * math.pi / 180.0;
    final cosHourAngle =
        (math.cos(zenith * math.pi / 180.0) -
                math.sin(latitudeRad) * math.sin(declination)) /
            (math.cos(latitudeRad) * math.cos(declination));

    if (cosHourAngle > 1 || cosHourAngle < -1) return null;

    final hourAngle = math.acos(cosHourAngle) * 180.0 / math.pi;
    final solarNoonUtcMinutes = 720.0 - 4.0 * lng - equationOfTime;
    final eventMinutes = isSunrise
        ? solarNoonUtcMinutes - 4.0 * hourAngle
        : solarNoonUtcMinutes + 4.0 * hourAngle;

    // Work in whole UTC seconds so negative values and UTC date crossings
    // are handled correctly. Dart's ~/ operator truncates toward zero, which
    // is not floor division for negative event times.
    final totalSeconds = (eventMinutes * 60.0).round();
    final dayShift = (totalSeconds / 86400).floor();
    final secondsOfDay = totalSeconds - dayShift * 86400;

    final hours = secondsOfDay ~/ 3600;
    final minutes = (secondsOfDay % 3600) ~/ 60;
    final seconds = secondsOfDay % 60;

    return DateTime.utc(
      date.year,
      date.month,
      date.day + dayShift,
      hours,
      minutes,
      seconds,
    );
  }
}
