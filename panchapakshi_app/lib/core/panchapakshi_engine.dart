import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import 'gowri_horai.dart';
import 'moon_phase.dart';
import 'panchapakshi_rules.dart';
import 'sun_calculator.dart';

/// The real-time Panchapakshi calculation engine.
///
/// Implements the Excel "Standard Alignment" formula exactly:
///   Day Length          = Sunset - Sunrise
///   Jamam Duration       = Day Length / 5
///   Antara Duration      = Jamam Duration / 5
///   Night Jamam Duration = (Next Sunrise - Sunset) / 5
///   Night Antara Duration = Night Jamam Duration / 5
///
/// So every Jamam/Antharam boundary is derived from *actual* local
/// sunrise & sunset for the selected coordinates — no fixed clock
/// times are assumed for Jamam/Antharam (Gowri & Horai, by contrast,
/// are fixed-clock per the book and are handled in gowri_horai.dart).
class PanchapakshiEngine {
  /// Computes the full state for [bird] at instant [nowLocal], for a
  /// location whose local calendar date requires [sunrise]/[sunset]
  /// (today's) and [nextSunrise] (tomorrow's, needed for night-jamam
  /// math). All DateTimes must be in the SAME timezone representation
  /// (local time of the selected place — see LocationService).
  static PanchapakshiState compute({
    required Pakshi bird,
    required DateTime nowLocal,
    required DateTime sunrise, // TODAY's sunrise
    required DateTime sunset, // TODAY's sunset
    required DateTime nextSunrise, // TOMORROW's sunrise
    DateTime? previousSunset, // YESTERDAY's sunset (needed pre-sunrise)
  }) {
    final paksham = MoonPhase.paskhamFor(nowLocal.toUtc());

    final isDay = nowLocal.isAfter(sunrise) && nowLocal.isBefore(sunset);
    final isBeforeTodaySunrise = nowLocal.isBefore(sunrise);
    final dayNight = isDay ? DayNight.day : DayNight.night;

    // Determine which "day" window we're in, and its bounds + weekday
    // (the weekday that governs the Jamam table is the weekday of the
    // sunrise that started the current day/night period).
    late DateTime periodStart;
    late DateTime periodEnd;
    late int rulingWeekday;

    if (isDay) {
      periodStart = sunrise;
      periodEnd = sunset;
      rulingWeekday = sunrise.weekday;
    } else if (isBeforeTodaySunrise) {
      // still last night: yesterday's sunset -> today's sunrise
      final prevSunset = previousSunset ??
          sunset.subtract(const Duration(hours: 24)); // safe fallback
      periodStart = prevSunset;
      periodEnd = sunrise;
      rulingWeekday = sunrise.subtract(const Duration(days: 1)).weekday;
    } else {
      // tonight: today's sunset -> tomorrow's sunrise
      periodStart = sunset;
      periodEnd = nextSunrise;
      rulingWeekday = sunrise.weekday; // night "belongs" to the day just ended
    }

    final periodLength = periodEnd.difference(periodStart);
    final jamamDuration = Duration(
      microseconds: periodLength.inMicroseconds ~/ 5,
    );

    final elapsed = nowLocal.difference(periodStart);
    var jamamIndex = (elapsed.inMicroseconds / jamamDuration.inMicroseconds)
        .floor();
    jamamIndex = jamamIndex.clamp(0, 4);
    final jamam = jamamIndex + 1;

    final jamamStart = periodStart.add(jamamDuration * jamamIndex);
    final jamamEnd = jamamStart.add(jamamDuration);

    final antharamDuration = Duration(
      microseconds: jamamDuration.inMicroseconds ~/ 5,
    );
    final elapsedInJamam = nowLocal.difference(jamamStart);
    var antharamIndex =
        (elapsedInJamam.inMicroseconds / antharamDuration.inMicroseconds)
            .floor();
    antharamIndex = antharamIndex.clamp(0, 4);
    final antharam = antharamIndex + 1;

    final antharamStart = jamamStart.add(antharamDuration * antharamIndex);
    final antharamEnd = antharamStart.add(antharamDuration);

    final jamamActivity = PanchapakshiRules.activityFor(
      bird: bird,
      jamam: jamam,
      paksham: paksham,
      dayNight: dayNight,
      dateTimeWeekday: rulingWeekday,
    );

    // அதிகாரப் பட்சி (Antara Pakshi): within a Jamam, the 5 antharams
    // cycle through the 5 birds in the SAME relative order the Jamam
    // table gives for that row, starting from the ruling bird. This
    // mirrors the book's sub-division method exactly (jamam activity
    // pattern repeated at antharam granularity, one slot per bird).
    final birdCycle = PanchapakshiRules.birdOrder;
    final startBirdIdx = birdCycle.indexOf(bird);
    final antharamBird =
        birdCycle[(startBirdIdx + antharamIndex) % birdCycle.length];
    final antharamActivity = PanchapakshiRules.activityFor(
      bird: antharamBird,
      jamam: jamam,
      paksham: paksham,
      dayNight: dayNight,
      dateTimeWeekday: rulingWeekday,
    );

    final remaining = antharamEnd.difference(nowLocal);

    // Next activity: next antharam's activity (rolls into next jamam
    // automatically if this is the last antharam).
    Thozhil nextActivity;
    DateTime nextActivityStart;
    if (antharamIndex < 4) {
      final nextBird = birdCycle[(startBirdIdx + antharamIndex + 1) % 5];
      nextActivity = PanchapakshiRules.activityFor(
        bird: nextBird,
        jamam: jamam,
        paksham: paksham,
        dayNight: dayNight,
        dateTimeWeekday: rulingWeekday,
      );
      nextActivityStart = antharamEnd;
    } else if (jamamIndex < 4) {
      nextActivity = PanchapakshiRules.activityFor(
        bird: bird,
        jamam: jamam + 1,
        paksham: paksham,
        dayNight: dayNight,
        dateTimeWeekday: rulingWeekday,
      );
      nextActivityStart = jamamEnd;
    } else {
      // Last antharam of last jamam -> activity flips to the other
      // day/night half starting at periodEnd.
      final flippedDayNight = isDay ? DayNight.night : DayNight.day;
      nextActivity = PanchapakshiRules.activityFor(
        bird: bird,
        jamam: 1,
        paksham: paksham,
        dayNight: flippedDayNight,
        dateTimeWeekday: rulingWeekday,
      );
      nextActivityStart = periodEnd;
    }

    final gowri = GowriCalculator.forInstant(nowLocal);
    final horai = HoraiCalculator.forInstant(nowLocal);

    return PanchapakshiState(
      asOf: nowLocal,
      bird: bird,
      paksham: paksham,
      dayNight: dayNight,
      sunrise: sunrise,
      sunset: sunset,
      nextSunrise: nextSunrise,
      jamam: jamam,
      jamamActivity: jamamActivity,
      jamamStart: jamamStart,
      jamamEnd: jamamEnd,
      antharam: antharam,
      antharamBird: antharamBird,
      antharamActivity: antharamActivity,
      antharamStart: antharamStart,
      antharamEnd: antharamEnd,
      remaining: remaining,
      nextActivity: nextActivity,
      nextActivityStart: nextActivityStart,
      gowriName: gowri.name,
      gowriIsGood: gowri.isGood,
      horaiPlanet: horai,
    );
  }

  /// Convenience for the "tomorrow / a week ahead" forecast requirement:
  /// computes sunrise/sunset-based Jamam boundaries for any future date
  /// without needing "now" to fall inside them.
  static ({DateTime sunrise, DateTime sunset}) sunTimesFor({
    required DateTime date,
    required double lat,
    required double lng,
  }) {
    final r = SunCalculator.calculate(date: date, lat: lat, lng: lng);
    return (
      sunrise: r.sunrise ?? DateTime(date.year, date.month, date.day, 6),
      sunset: r.sunset ?? DateTime(date.year, date.month, date.day, 18),
    );
  }
}
