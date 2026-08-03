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

    final jamamActivity = PanchapakshiRules.activityFor(
      bird: bird,
      jamam: jamam,
      paksham: paksham,
      dayNight: dayNight,
      dateTimeWeekday: rulingWeekday,
    );

    final birdCycle = PanchapakshiRules.birdOrder;
    final startBirdIdx = birdCycle.indexOf(bird);
    final antharamBirds = List.generate(5, (i) => birdCycle[(startBirdIdx + i) % 5]);
    final antharamActivities = antharamBirds
        .map((b) => PanchapakshiRules.activityFor(
              bird: b,
              jamam: jamam,
              paksham: paksham,
              dayNight: dayNight,
              dateTimeWeekday: rulingWeekday,
            ))
        .toList();

    final weightTable = PanchapakshiRules.minutesTableFor(paksham, dayNight);
    final weights = antharamActivities.map((t) => weightTable[t.tamil]!.toDouble()).toList();
    final totalWeight = weights.reduce((a, b) => a + b);

    final antharamDurations = weights
        .map((w) => Duration(
            microseconds: (jamamDuration.inMicroseconds * w / totalWeight).round()))
        .toList();

    var cumulative = Duration.zero;
    var antharamIndex = 4;
    var antharamStart = jamamStart;
    for (var i = 0; i < 5; i++) {
      final start = jamamStart.add(cumulative);
      final end = start.add(antharamDurations[i]);
      if (nowLocal.isBefore(end) || i == 4) {
        antharamIndex = i;
        antharamStart = start;
        break;
      }
      cumulative += antharamDurations[i];
    }
    final antharamEnd = antharamStart.add(antharamDurations[antharamIndex]);
    final antharam = antharamIndex + 1;
    final antharamBird = antharamBirds[antharamIndex];
    final antharamActivity = antharamActivities[antharamIndex];

    final remaining = antharamEnd.difference(nowLocal);

    Thozhil nextActivity;
    DateTime nextActivityStart;
    Pakshi nextAntharamBird;
    if (antharamIndex < 4) {
      nextAntharamBird = antharamBirds[antharamIndex + 1];
      nextActivity = antharamActivities[antharamIndex + 1];
      nextActivityStart = antharamEnd;
    } else if (jamamIndex < 4) {
      final nextJamamBirds = List.generate(5, (i) => birdCycle[(startBirdIdx + i) % 5]);
      final nextJamamActivities = nextJamamBirds
          .map((b) => PanchapakshiRules.activityFor(
                bird: b,
                jamam: jamam + 1,
                paksham: paksham,
                dayNight: dayNight,
                dateTimeWeekday: rulingWeekday,
              ))
          .toList();
      nextAntharamBird = nextJamamBirds[0];
      nextActivity = nextJamamActivities[0];
      nextActivityStart = jamamEnd;
    } else {
      final flippedDayNight = isDay ? DayNight.night : DayNight.day;
      nextAntharamBird = bird;
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
      nextAntharamBird: nextAntharamBird,
      gowriName: gowri.name,
      gowriIsGood: gowri.isGood,
      horaiPlanet: horai,
    );
  }
}
