import '../models/pakshi.dart';
import 'day_ruler_rules.dart';
import 'panchapakshi_rules.dart';

class KozhliSuccessResult {
  final Pakshi authorityBird;
  final String authorityRelationship;
  final bool isAuthorityDay;
  final bool isPaduDay;
  final int percent;
  final String label;

  const KozhliSuccessResult({
    required this.authorityBird,
    required this.authorityRelationship,
    required this.isAuthorityDay,
    required this.isPaduDay,
    required this.percent,
    required this.label,
  });
}

class KozhliSuccessWindow {
  final DateTime start;
  final DateTime end;
  final Pakshi bird;
  final Thozhil activity;
  final int percent;
  final String label;

  const KozhliSuccessWindow({
    required this.start,
    required this.end,
    required this.bird,
    required this.activity,
    required this.percent,
    required this.label,
  });
}

class KozhliSuccessRules {
  static const Pakshi kozhli = Pakshi.kozhi;

  /// Fixed relationship of each அந்தர பட்சி to KOZHLI for the
  /// Future Prediction / அந்தர பட்சி display.
  ///
  /// IMPORTANT: this is the workbook's "உறவு" column and is NOT the same
  /// thing as the day's Table-10 roles (அதிகார பட்சி / படு பட்சி /
  /// சம பட்சி / பகை பட்சி / நட்பு பட்சி).
  ///
  /// From the KOZHLI sheets in the verified workbook:
  ///   KOZHLI    -> சுயம்
  ///   MAYIL     -> நட்பு
  ///   KAAGAM    -> நட்பு
  ///   VALLOORU -> பகை
  ///   AANDHAI  -> பகை
  ///
  /// Therefore both மயில் and காகம் can correctly appear as நட்பு for
  /// KOZHLI. They must not be replaced by their Table-10 day-role labels.
  static String relationshipToKozhli(Pakshi antarBird) {
    switch (antarBird) {
      case Pakshi.kozhi:
        return 'சுயம்';
      case Pakshi.mayil:
      case Pakshi.kaagam:
        return 'நட்பு';
      case Pakshi.vallooru:
      case Pakshi.aandhai:
        return 'பகை';
    }
  }

  /// Evaluates the current KOZHLI Panchapakshi condition.
  ///
  /// KOZHLI அதிகார பட்சி:
  ///   அரசு = 100%
  ///   ஊண்  = 75%
  ///   நடை  = 50%
  ///
  /// KOZHLI படுபட்சி:
  ///   0% / Avoid
  ///
  /// Other days:
  ///   No KOZHLI authority success percentage.
  static KozhliSuccessResult evaluate({
    required DayRulerInfo dayRuler,
    required Pakshi antharamBird,
    required Thozhil antharamActivity,
  }) {
    final authorityBird = dayRuler.ruler;

    final relationship = relationshipToKozhli(antharamBird);

    final isAuthorityDay = authorityBird == kozhli;
    final isPaduDay = dayRuler.subordinate == kozhli;

    if (isPaduDay) {
      return KozhliSuccessResult(
        authorityBird: authorityBird,
        authorityRelationship: 'படுபட்சி',
        isAuthorityDay: false,
        isPaduDay: true,
        percent: 0,
        label: 'KOZHLI படுபட்சி — தவிர்க்கவும்',
      );
    }

    if (!isAuthorityDay) {
      return KozhliSuccessResult(
        authorityBird: authorityBird,
        authorityRelationship: relationship,
        isAuthorityDay: false,
        isPaduDay: false,
        percent: 0,
        label: 'KOZHLI அதிகார பட்சி இல்லை',
      );
    }

    final percent = _successPercent(antharamBird, antharamActivity);

    return KozhliSuccessResult(
      authorityBird: authorityBird,
      authorityRelationship: 'சுயம்',
      isAuthorityDay: true,
      isPaduDay: false,
      percent: percent,
      label: _successLabel(percent, antharamActivity),
    );
  }

  static int _successPercent(
    Pakshi antharamBird,
    Thozhil activity,
  ) {
    // The KOZHLI success percentage applies to KOZHLI
    // அந்தர பட்சி தொழில்.
    if (antharamBird != kozhli) {
      return 0;
    }

    switch (activity) {
      case Thozhil.arasu:
        return 100;

      case Thozhil.oon:
        return 75;

      case Thozhil.nadai:
        return 50;

      case Thozhil.thuyil:
      case Thozhil.saavu:
        return 0;
    }
  }

  static String _successLabel(
    int percent,
    Thozhil activity,
  ) {
    switch (percent) {
      case 100:
        return 'அரசு — 100% Success';

      case 75:
        return 'ஊண் — 75% Success';

      case 50:
        return 'நடை — 50% Success';

      default:
        return '${activity.tamil} — 0% Success';
    }
  }

  /// Builds the successful KOZHLI periods within a real sunrise/sunset
  /// or sunset/next-sunrise period.
  ///
  /// The period is divided into the five real Panchapakshi ஜாமங்கள்.
  /// Each ஜாமத்தின் அந்தர timings use the location-specific actual
  /// ஜாமம் duration together with the weighted Panchapakshi minute table.
  static List<KozhliSuccessWindow> windowsForPeriod({
    required DateTime periodStart,
    required DateTime periodEnd,
    required Paksham paksham,
    required DayNight dayNight,
    required int rulingWeekday,
    required bool paduDay,
  }) {
    if (paduDay) {
      return const <KozhliSuccessWindow>[];
    }

    final totalPeriod = periodEnd.difference(periodStart);

    if (totalPeriod.inMicroseconds <= 0) {
      return const <KozhliSuccessWindow>[];
    }

    final jamamDuration = Duration(
      microseconds: totalPeriod.inMicroseconds ~/ 5,
    );

    final birdCycle = dayNight == DayNight.day
        ? PanchapakshiRules.birdOrder
        : PanchapakshiRules.birdOrder.reversed.toList();

    final weightTable =
        PanchapakshiRules.minutesTableFor(paksham, dayNight);

    final result = <KozhliSuccessWindow>[];

    for (var jamamIndex = 0; jamamIndex < 5; jamamIndex++) {
      final jamamStart =
          periodStart.add(jamamDuration * jamamIndex);

      final jamamEnd = jamamIndex == 4
          ? periodEnd
          : jamamStart.add(jamamDuration);

      final activities = birdCycle.map((bird) {
        return PanchapakshiRules.activityFor(
          bird: bird,
          jamam: jamamIndex + 1,
          paksham: paksham,
          dayNight: dayNight,
          dateTimeWeekday: rulingWeekday,
        );
      }).toList();

      final durations = _antharamDurations(
        jamamDuration: jamamDuration,
        activities: activities,
        weightTable: weightTable,
      );

      var cursor = jamamStart;

      for (var i = 0; i < 5; i++) {
        final bird = birdCycle[i];
        final activity = activities[i];

        final end = i == 4
            ? jamamEnd
            : cursor.add(durations[i]);

        if (bird == kozhli) {
          final percent = _successPercent(bird, activity);

          if (percent > 0) {
            result.add(
              KozhliSuccessWindow(
                start: cursor,
                end: end,
                bird: bird,
                activity: activity,
                percent: percent,
                label: _successLabel(percent, activity),
              ),
            );
          }
        }

        cursor = end;
      }
    }

    return result;
  }

  static List<Duration> _antharamDurations({
    required Duration jamamDuration,
    required List<Thozhil> activities,
    required Map<String, int> weightTable,
  }) {
    const standardJamam = Duration(minutes: 144);

    final extraTotal = jamamDuration - standardJamam;

    final extraPerAntharam = Duration(
      microseconds: extraTotal.inMicroseconds ~/ 5,
    );

    final roundingRemainder =
        extraTotal - (extraPerAntharam * 5);

    return List.generate(5, (i) {
      final baseMinutes =
          weightTable[activities[i].tamil] ?? 0;

      final base = Duration(minutes: baseMinutes);

      final extra = i == 4
          ? extraPerAntharam + roundingRemainder
          : extraPerAntharam;

      return base + extra;
    });
  }
}
