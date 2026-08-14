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

  static String relationshipToKozhli(Pakshi bird) {
    switch (bird) {
      case Pakshi.kozhi:
        return 'சுயம்';
      case Pakshi.mayil:
      case Pakshi.kaagam:
        return 'நட்பு பட்சி';
      case Pakshi.vallooru:
      case Pakshi.aandhai:
        return 'பகை பட்சி';
    }
  }

  static KozhliSuccessResult evaluate({
    required DayRulerInfo dayRuler,
    required Pakshi antharamBird,
    required Thozhil antharamActivity,
  }) {
    final authorityBird = dayRuler.ruler;
    final relationship = relationshipToKozhli(authorityBird);

    final isAuthorityDay = authorityBird == kozhli;
    final isPaduDay = dayRuler.subordinate == kozhli;

    if (isPaduDay) {
      return KozhliSuccessResult(
        authorityBird: authorityBird,
        authorityRelationship: relationship,
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

  static int _successPercent(Pakshi antharamBird, Thozhil activity) {
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

  static String _successLabel(int percent, Thozhil activity) {
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

  /// Builds the successful KOZHLI periods inside one actual solar period.
  ///
  /// Excel's Panchapakshi sheet keeps the standard five-minute table intact
  /// and applies the same per-அந்தரம் correction to each of the five
  /// segments.  For example, when a day ஜாமம் is 02:32:36.894:
  ///
  ///   standard ஜாமம் = 02:24:00
  ///   difference     = 00:08:36.894
  ///   Excel F7       = 00:01:43.3788
  ///   ஊண்            = 00:48:00 + F7 = 00:49:43.3788
  ///
  /// This is deliberately calculated from the actual period rather than
  /// from a fixed 24-hour clock so Rajahmundry and Lafayette both use their
  /// own sunrise/sunset durations.
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

    final baseCycle = dayNight == DayNight.day
        ? PanchapakshiRules.birdOrder
        : PanchapakshiRules.birdOrder.reversed.toList();
    final kozhliIndex = baseCycle.indexOf(kozhli);
    final birdCycle = List<Pakshi>.generate(
      5,
      (i) => baseCycle[(kozhliIndex + i) % baseCycle.length],
    );

    final weightTable =
        PanchapakshiRules.minutesTableFor(paksham, dayNight);

    final result = <KozhliSuccessWindow>[];

    for (var jamamIndex = 0; jamamIndex < 5; jamamIndex++) {
      final jamamStart = periodStart.add(jamamDuration * jamamIndex);
      final jamamEnd = jamamIndex == 4
          ? periodEnd
          : jamamStart.add(jamamDuration);

      final activities = <Thozhil>[];
      for (final bird in birdCycle) {
        activities.add(
          PanchapakshiRules.activityFor(
            bird: bird,
            jamam: jamamIndex + 1,
            paksham: paksham,
            dayNight: dayNight,
            dateTimeWeekday: rulingWeekday,
          ),
        );
      }

      final durations = _excelAntharamDurations(
        jamamDuration: jamamDuration,
        activities: activities,
        weightTable: weightTable,
      );

      var cursor = jamamStart;
      for (var i = 0; i < 5; i++) {
        final bird = birdCycle[i];
        final activity = activities[i];
        final end = i == 4 ? jamamEnd : cursor.add(durations[i]);

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

  /// Exact Excel-style segment calculation.
  ///
  /// The standard Panchapakshi table totals 144 minutes.  Excel calculates
  /// the actual ジャமம் difference from 144 minutes, divides that difference
  /// by five (F7/F9), and adds that correction to every segment.  The last
  /// segment receives the integer-microsecond remainder so the five segments
  /// terminate exactly at the real ஜாமம் end.
  static List<Duration> _excelAntharamDurations({
    required Duration jamamDuration,
    required List<Thozhil> activities,
    required Map<String, int> weightTable,
  }) {
    const standardJamam = Duration(minutes: 144);

    final differenceMicros =
        jamamDuration.inMicroseconds - standardJamam.inMicroseconds;
    final correctionMicros = differenceMicros ~/ 5;
    final correction = Duration(microseconds: correctionMicros);
    final remainderMicros =
        differenceMicros - correctionMicros * 5;

    return List<Duration>.generate(5, (i) {
      final baseMinutes = weightTable[activities[i].tamil] ?? 0;
      final base = Duration(minutes: baseMinutes);
      final finalCorrection = i == 4
          ? Duration(microseconds: correctionMicros + remainderMicros)
          : correction;
      return base + finalCorrection;
    });
  }
}
