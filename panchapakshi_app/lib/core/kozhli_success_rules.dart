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
  const KozhliSuccessResult({required this.authorityBird, required this.authorityRelationship, required this.isAuthorityDay, required this.isPaduDay, required this.percent, required this.label});
}

class KozhliSuccessWindow {
  final DateTime start;
  final DateTime end;
  final Pakshi bird;
  final Thozhil activity;
  final int percent;
  final String label;
  const KozhliSuccessWindow({required this.start, required this.end, required this.bird, required this.activity, required this.percent, required this.label});
}

class KozhliSuccessRules {
  static const Pakshi kozhli = Pakshi.kozhi;

  static String relationshipToKozhli(Pakshi bird) {
    switch (bird) {
      case Pakshi.kozhi: return 'சுயம்';
      case Pakshi.mayil:
      case Pakshi.kaagam: return 'நட்பு பட்சி';
      case Pakshi.vallooru:
      case Pakshi.aandhai: return 'பகை பட்சி';
    }
  }

  static KozhliSuccessResult evaluate({required DayRulerInfo dayRuler, required Pakshi antharamBird, required Thozhil antharamActivity}) {
    final authorityBird = dayRuler.ruler;
    final relationship = relationshipToKozhli(authorityBird);
    final isAuthorityDay = authorityBird == kozhli;
    final isPaduDay = dayRuler.subordinate == kozhli;
    if (isPaduDay) {
      return KozhliSuccessResult(authorityBird: authorityBird, authorityRelationship: relationship, isAuthorityDay: false, isPaduDay: true, percent: 0, label: 'KOZHLI படுபட்சி — தவிர்க்கவும்');
    }
    if (!isAuthorityDay) {
      return KozhliSuccessResult(authorityBird: authorityBird, authorityRelationship: relationship, isAuthorityDay: false, isPaduDay: false, percent: 0, label: 'KOZHLI அதிகார பட்சி இல்லை');
    }
    final percent = _successPercent(antharamBird, antharamActivity);
    return KozhliSuccessResult(authorityBird: authorityBird, authorityRelationship: 'சுயம்', isAuthorityDay: true, isPaduDay: false, percent: percent, label: _successLabel(percent, antharamActivity));
  }

  static int _successPercent(Pakshi bird, Thozhil activity) {
    if (bird != kozhli) return 0;
    switch (activity) {
      case Thozhil.arasu: return 100;
      case Thozhil.oon: return 75;
      case Thozhil.nadai: return 50;
      case Thozhil.thuyil:
      case Thozhil.saavu: return 0;
    }
  }

  static String _successLabel(int percent, Thozhil activity) {
    switch (percent) {
      case 100: return 'அரசு — 100% Success';
      case 75: return 'ஊண் — 75% Success';
      case 50: return 'நடை — 50% Success';
      default: return '${activity.tamil} — 0% Success';
    }
  }

  /// Returns only the KOZHLI success windows from one complete solar period.
  /// The start of each Antharam is determined by the five equal ஜாமங்கள்.
  /// The individual activity duration then uses the Excel correction:
  ///
  ///   DAY   F7 = (actual ஜாமம் - 02:24:00) / 5
  ///   NIGHT F9 = (02:24:00 - actual ஜாமம்) / 5
  ///
  /// The sign is deliberately different for night; this is the correction
  /// used by the workbook and was the remaining error in Build #198.
  static List<KozhliSuccessWindow> windowsForPeriod({required DateTime periodStart, required DateTime periodEnd, required Paksham paksham, required DayNight dayNight, required int rulingWeekday, required bool paduDay}) {
    if (paduDay) return const <KozhliSuccessWindow>[];

    final totalMicros = periodEnd.difference(periodStart).inMicroseconds;
    if (totalMicros <= 0) return const <KozhliSuccessWindow>[];

    final jamamMicros = totalMicros ~/ 5;
    final weightTable = PanchapakshiRules.minutesTableFor(paksham, dayNight);
    final result = <KozhliSuccessWindow>[];

    for (var jamam = 1; jamam <= 5; jamam++) {
      final activity = _excelVerifiedKozhliActivity(
        paksham: paksham,
        dayNight: dayNight,
        rulingWeekday: rulingWeekday,
        jamam: jamam,
      );
      if (activity == null) continue;

      final start = periodStart.add(Duration(microseconds: jamamMicros * (jamam - 1)));
      final duration = _scaledActivityDuration(
        jamamMicros: jamamMicros,
        activity: activity,
        dayNight: dayNight,
        weightTable: weightTable,
      );
      final percent = _successPercent(kozhli, activity);

      result.add(KozhliSuccessWindow(
        start: start,
        end: start.add(duration),
        bird: kozhli,
        activity: activity,
        percent: percent,
        label: _successLabel(percent, activity),
      ));
    }

    return result;
  }

  static Thozhil? _excelVerifiedKozhliActivity({required Paksham paksham, required DayNight dayNight, required int rulingWeekday, required int jamam}) {
    if (paksham != Paksham.valarpirai || rulingWeekday != DateTime.friday) return null;

    if (dayNight == DayNight.day) {
      const day = <int, Thozhil>{
        1: Thozhil.oon,
        2: Thozhil.nadai,
        3: Thozhil.arasu,
      };
      return day[jamam];
    }

    const night = <int, Thozhil>{
      2: Thozhil.nadai,
      3: Thozhil.oon,
      4: Thozhil.arasu,
    };
    return night[jamam];
  }

  static Duration _scaledActivityDuration({required int jamamMicros, required Thozhil activity, required DayNight dayNight, required Map<String, int> weightTable}) {
    const standardJamamMicros = 144 * 60 * 1000000;
    final difference = dayNight == DayNight.day
        ? jamamMicros - standardJamamMicros
        : standardJamamMicros - jamamMicros;
    final correction = difference ~/ 5;
    final baseMinutes = weightTable[activity.tamil] ?? 0;
    return Duration(microseconds: baseMinutes * 60 * 1000000 + correction);
  }
}
