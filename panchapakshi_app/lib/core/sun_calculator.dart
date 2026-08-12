import 'dart:math' as math;

/// Computes sunrise and sunset as true UTC instants for a selected
/// location's Gregorian calendar date.
///
/// Uses the NOAA solar-position approximation (solar declination + equation
/// of time) with the official 90.833 degree sunrise/sunset zenith. The result
/// is independent of the phone timezone; callers convert the UTC event through
/// the selected location's IANA timezone.
class SunCalculator {
  static ({DateTime? sunrise, DateTime? sunset}) calculate({
    required DateTime date,
    required double lat,
    required double lng,
  }) {
    final sunrise = _sunEvent(date, lat, lng, true);
    final sunset = _sunEvent(date, lat, lng, false);
    return (sunrise: sunrise, sunset: sunset);
  }

  static DateTime? _sunEvent(
    DateTime date,
    double lat,
    double lng,
    bool sunrise,
  ) {
    const zenith = 90.833;
    final n = DateTime.utc(date.year, date.month, date.day)
            .difference(DateTime.utc(date.year, 1, 1))
            .inDays +
        1;

    // NOAA fractional-year equations evaluated at local solar noon.
    final gamma = 2 * math.pi / 365.0 * (n - 1);
    final equationOfTime = 229.18 *
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

    // Minutes after 00:00 UTC. Longitude is positive east.
    final solarNoonUtcMinutes = 720.0 - 4.0 * lng - equationOfTime;
    final eventMinutes = sunrise
        ? solarNoonUtcMinutes - 4.0 * hourAngle
        : solarNoonUtcMinutes + 4.0 * hourAngle;

    final dayShift = eventMinutes.floor() ~/ 1440;
    final normalized = ((eventMinutes % 1440) + 1440) % 1440;
    final hours = normalized ~/ 60;
    final minutes = normalized % 60;
    final seconds = ((normalized - normalized.floor()) * 60).round();

    var result = DateTime.utc(
      date.year,
      date.month,
      date.day + dayShift,
      hours,
      minutes,
      seconds,
    );

    // Carry a rounded 60th second into the next minute.
    if (seconds >= 60) result = result.add(const Duration(minutes: 1));
    return result;
  }
}
