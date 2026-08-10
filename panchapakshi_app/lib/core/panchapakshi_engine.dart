import '../models/pakshi.dart';
import '../models/panchapakshi_state.dart';
import 'day_ruler_rules.dart';
import 'gowri_horai.dart';
import 'kozhli_success_rules.dart';
import 'moon_phase.dart';
import 'panchapakshi_rules.dart';

class PanchapakshiEngine {
  static List<Pakshi> _antharamBirds({
    required Pakshi bird,
    required DayNight dayNight,
  }) {
    final cycle = dayNight == DayNight.day
        ? PanchapakshiRules.birdOrder
        : PanchapakshiRules.birdOrder.reversed.toList();
    final start = cycle.indexOf(bird);
    return List.generate(5, (i) => cycle[(start + i) % 5]);
  }

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

    if (isDay) {
      periodStart = sunrise;
      periodEnd = sunset;
    } else if (isBeforeTodaySunrise) {
      final prevSunset = previousSunset ?? sunset.subtract(const Duration(hours: 24));
      periodStart = prevSunset;
      periodEnd = sunrise;
    } else {
      periodStart = sunset;
      periodEnd = nextSunrise;
    }

    final rulingWeekday = nowLocal.weekday;
    final dayRuler = DayRulerRules.forWeekday(rulingWeekday, paksham);

    final periodLength = periodEnd.difference(periodStart);
    final jamamDuration = Duration(
      microseconds: periodLength.inMicroseconds ~/ 5,
    );

    final elapsed = nowLocal.difference(periodStart);
    var jamamIndex =
        (elapsed.inMicroseconds / jamamDuration.inMicroseconds).floor();
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

    final antharamBirds = _antharamBirds(
      bird: bird,
      dayNight: dayNight,
    );
    final antharamActivities = antharamBirds
        .map(
          (b) => PanchapakshiRules.activityFor(
            bird: b,
            jamam: jamam,
            paksham: paksham,
            dayNight: dayNight,
            dateTimeWeekday: rulingWeekday,
          ),
        )
        .toList();

    final weightTable = PanchapakshiRules.minutesTableFor(paksham, dayNight);
    const standardJamam = Duration(minutes: 144);
    final extraTotal = jamamDuration - standardJamam;
    final extraPerAntharam = Duration(
      microseconds: extraTotal.inMicroseconds ~/ 5,
    );
    final roundingRemainder = extraTotal - (extraPerAntharam * 5);

    final antharamDurations = List.generate(5, (i) {
      final base = Duration(
        minutes: weightTable[antharamActivities[i].tamil]!,
      );
      final extra = i == 4
          ? extraPerAntharam + roundingRemainder
          : extraPerAntharam;
      return base + extra;
    });

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

    late Thozhil nextActivity;
    late DateTime nextActivityStart;
    late Pakshi nextAntharamBird;

    if (antharamIndex < 4) {
      nextAntharamBird = antharamBirds[antharamIndex + 1];
      nextActivity = antharamActivities[antharamIndex + 1];
      nextActivityStart = antharamEnd;
    } else if (jamamIndex < 4) {
      final nextBirds = _antharamBirds(
        bird: bird,
        dayNight: dayNight,
      );
      final nextActivities = nextBirds
          .map(
            (b) => PanchapakshiRules.activityFor(
              bird: b,
              jamam: jamam + 1,
              paksham: paksham,
              dayNight: dayNight,
              dateTimeWeekday: rulingWeekday,
            ),
          )
          .toList();
      nextAntharamBird = nextBirds[0];
      nextActivity = nextActivities[0];
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

    final success = KozhliSuccessRules.evaluate(
      dayRuler: dayRuler,
      antharamBird: antharamBird,
      antharamActivity: antharamActivity,
    );

    final gowri = GowriCalculator.forInstant(
      local: nowLocal,
      sunrise: sunrise,
      sunset: sunset,
      nextSunrise: nextSunrise,
      previousSunset: previousSunset,
    );

    final horai = HoraiCalculator.forInstant(
      local: nowLocal,
      sunrise: sunrise,
      sunset: sunset,
      nextSunrise: nextSunrise,
      previousSunset: previousSunset,
    );

    return PanchapakshiState(
      asOf: nowLocal,
      sunrise: sunrise,
      sunset: sunset,
      nextSunrise: nextSunrise,
      bird: bird,
      paksham: paksham,
      dayNight: dayNight,
      rulingWeekday: rulingWeekday,
      authorityBird: success.authorityBird,
      authorityRelationship: success.authorityRelationship,
      isKozhliAuthorityDay: success.isAuthorityDay,
      isKozhliPaduDay: success.isPaduDay,
      successPercent: success.percent,
      successLabel: success.label,
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
      gowriStart: gowri.start,
      gowriEnd: gowri.end,
      horaiPlanet: horai.planet,
      horaiStart: horai.start,
      horaiEnd: horai.end,
    );
  }
}
