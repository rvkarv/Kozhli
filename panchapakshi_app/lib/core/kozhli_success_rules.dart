import '../models/pakshi.dart';
import 'panchapakshi_rules.dart';

/// A favourable KOZHLI time window.
///
/// The percentage is based on the KOZHLI authority-day rules:
///
///   அரசு = 100%
///   ஊண்  = 75%
///   நடை  = 50%
///
/// Other activities are not returned as success windows.
class KozhliSuccessWindow {
  final DateTime start;
  final DateTime end;
  final Thozhil activity;
  final int percent;

  const KozhliSuccessWindow({
    required this.start,
    required this.end,
    required this.activity,
    required this.percent,
  });
}

/// KOZHLI-specific success rules used by the Dashboard and
/// Future Prediction.
///
/// IMPORTANT:
/// This class does not calculate sunrise/sunset.
/// The caller supplies the actual local period start/end, so
/// the calculation automatically follows the selected place
/// and selected date.
class KozhliSuccessRules {
  static const Duration _standardJamam = Duration(minutes: 144);

  /// Returns only the favourable KOZHLI windows within the
  /// supplied day or night period.
  ///
  /// The supplied period is divided into 5 real local ஜாமங்கள்.
  /// Each ஜாமம் is then divided into 5 அந்தரங்கள் using the
  /// Panchapakshi weighted minute tables.
  ///
  /// The difference between the actual ஜாமம் length and the
  /// standard 2:24:00 is distributed equally across the five
  /// அந்தரங்கள், matching the calculation used by the
  /// Panchapakshi engine.
  static List<KozhliSuccessWindow> windowsForPeriod({
    required DateTime periodStart,
    required DateTime periodEnd,
    required Paksham paksham,
    required DayNight dayNight,
    required int rulingWeekday,
    required bool paduDay,
  }) {
    // KOZHLI படுபட்சி day has no success.
    if (paduDay) {
      return const <KozhliSuccessWindow>[];
    }

    final periodLength = periodEnd.difference(periodStart);

    if (periodLength <= Duration.zero) {
      return const <KozhliSuccessWindow>[];
    }

    final jamamDuration = Duration(
      microseconds: periodLength.inMicroseconds ~/ 5,
    );

    final results = <KozhliSuccessWindow>[];

    // KOZHLI is the selected calculation bird.
    const bird = Pakshi.kozhi;

    for (var jamamIndex = 0; jamamIndex < 5; jamamIndex++) {
      final jamamStart =
          periodStart.add(jamamDuration * jamamIndex);

      // Ensure the final ஜாமம் ends exactly at the real
      // period end, including any integer-division remainder.
      final jamamEnd = jamamIndex == 4
          ? periodEnd
          : jamamStart.add(jamamDuration);

      final jamamLength = jamamEnd.difference(jamamStart);

      final birdCycle = PanchapakshiRules.birdOrder;
      final startBirdIndex = birdCycle.indexOf(bird);

      final antharamBirds = List.generate(
        5,
        (i) => birdCycle[
            (startBirdIndex + i) % birdCycle.length],
      );

      final activities = antharamBirds
          .map(
            (b) => PanchapakshiRules.activityFor(
              bird: b,
              jamam: jamamIndex + 1,
              paksham: paksham,
              dayNight: dayNight,
              dateTimeWeekday: rulingWeekday,
            ),
          )
          .toList();

      final weightTable =
          PanchapakshiRules.minutesTableFor(
        paksham,
        dayNight,
      );

      final extraTotal = jamamLength - _standardJamam;

      final extraPerAntharam = Duration(
        microseconds: extraTotal.inMicroseconds ~/ 5,
      );

      final roundingRemainder =
          extraTotal - (extraPerAntharam * 5);

      var cumulative = Duration.zero;

      for (var i = 0; i < 5; i++) {
        final activity = activities[i];

        final baseMinutes = weightTable[activity.tamil];

        if (baseMinutes == null) {
          cumulative += _fallbackDuration(
            jamamLength,
          );
          continue;
        }

        final baseDuration =
            Duration(minutes: baseMinutes);

        final adjustment = i == 4
            ? extraPerAntharam + roundingRemainder
            : extraPerAntharam;

        var antharamDuration =
            baseDuration + adjustment;

        // Protect against an invalid negative duration in
        // unusual astronomical inputs.
        if (antharamDuration <= Duration.zero) {
          antharamDuration = Duration.zero;
        }

        final start = jamamStart.add(cumulative);

        var end = start.add(antharamDuration);

        // Never allow an antharam to extend beyond the real
        // ஜாமம் end.
        if (end.isAfter(jamamEnd)) {
          end = jamamEnd;
        }

        final percent = _successPercent(activity);

        if (percent > 0 && end.isAfter(start)) {
          results.add(
            KozhliSuccessWindow(
              start: start,
              end: end,
              activity: activity,
              percent: percent,
            ),
          );
        }

        cumulative += antharamDuration;

        // Stop if the real ஜாமம் has already been consumed.
        if (!start.isBefore(jamamEnd)) {
          break;
        }
      }
    }

    return results;
  }

  /// KOZHLI authority-day success percentages.
  static int _successPercent(Thozhil activity) {
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

  /// Defensive fallback.
  ///
  /// This should normally never be used because all five
  /// Panchapakshi activities have entries in the standard
  /// minute tables.
  static Duration _fallbackDuration(
    Duration jamamLength,
  ) {
    return Duration(
      microseconds: jamamLength.inMicroseconds ~/ 5,
    );
  }
}
