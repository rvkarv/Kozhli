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
    // The workbook's per-bird sheets use the forward bird cycle for day
    // and the reverse bird cycle for night.  For KOZHLI on a Saturday night
    // this gives: கோழி → காகம் → ஆந்தை → வல்லூறு → மயில்.
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

    // IMPORTANT: the workbook's night sections are keyed to the current
    // calendar weekday.  Therefore Saturday 01:50 is Saturday night, not
    // Friday night.  Do not derive this from sunrise.subtract(1 day).
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

    // Antharam durations remain weighted by the workbook's activity-minute
    // table, with the actual location's real jamam length applied through
    // the same flat adjustment used by the existing workbook formula.
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

    final antharamEnd =
        antharamStart.add(antharamDurations[antharamIndex]);
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
      horaiPlanet: horai,
    );
  }
}
