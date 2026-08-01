import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import 'gowri_horai.dart';
import 'moon_phase.dart';
import 'panchapakshi_rules.dart';

class PanchapakshiEngine {
  static PanchapakshiState compute({
    required Pakshi bird,
    required DateTime nowLocal,
    required DateTime nowUtc,
    required DateTime sunrise,
    required DateTime sunset,
    required DateTime nextSunrise,
    DateTime? previousSunset,
  }) {
    final paksham = MoonPhase.paskhamFor(nowUtc);

    final isDay = nowLocal.isAfter(sunrise) && nowLocal.isBefore(sunset);
    final isBeforeTodaySunrise = nowLocal.isBefore(sunrise);
    final dayNight = isDay ? DayNight.day : DayNight.night;

    late DateTime periodStart;
    late DateTime periodEnd;
    late int rulingWeekday;

    if (isDay) {
      periodStart = sunrise;
      periodEnd = sunset;
      rulingWeekday = sunrise.weekday;
    } else if (isBeforeTodaySunrise) {
      final prevSunset = previousSunset ?? sunset.subtract(const Duration(hours: 24));
      periodStart = prevSunset;
      periodEnd = sunrise;
      rulingWeekday = sunrise.subtract(const Duration(days: 1)).weekday;
    } else {
      periodStart = sunset;
      periodEnd = nextSunrise;
      rulingWeekday = sunrise.weekday;
    }

    final periodLength = periodEnd.difference(periodStart);
    final jamamDuration = Duration(microseconds: periodLength.inMicroseconds ~/ 5);

    final elapsed = nowLocal.difference(periodStart);
    var jamamIndex = (elapsed.inMicroseconds / jamamDuration.inMicroseconds).floor();
    jamamIndex = jamamIndex.clamp(0, 4);
    final jamam = jamamIndex + 1;

    final jamamStart = periodStart.add(jamamDuration * jamamIndex);
    final jamamEnd = jamamStart.add(jamamDuration);

    final antharamDuration = Duration(microseconds: jamamDuration.inMicroseconds ~/ 5);
    final elapsedInJamam = nowLocal.difference(jamamStart);
    var antharamIndex =
        (elapsedInJamam.inMicroseconds / antharamDuration.inMicroseconds).floor();
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

    final birdCycle = PanchapakshiRules.birdOrder;
    final startBirdIdx = birdCycle.indexOf(bird);
    final antharamBird = birdCycle[(startBirdIdx + antharamIndex) % birdCycle.length];
    final antharamActivity = PanchapakshiRules.activityFor(
      bird: antharamBird,
      jamam: jamam,
      paksham: paksham,
      dayNight: dayNight,
      dateTimeWeekday: rulingWeekday,
    );

    final remaining = antharamEnd.difference(nowLocal);

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
}
