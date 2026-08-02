import '../models/pakshi.dart';

/// All static reference tables transcribed from
/// "Panchapatchi_Rules_1.xlsx" -> sheet 'பஞ்சபட்சி RULES'.
///
/// Bird column order used throughout this file (matches the workbook):
/// [வல்லூறு, ஆந்தை, காகம், கோழி, மயில்]
class GowriSlot {
  final String label;
  final DateTime start;
  final DateTime end;
  const GowriSlot(this.label, this.start, this.end);
}

class HoraiSlot {
  final String planet;
  final DateTime start;
  final DateTime end;
  const HoraiSlot(this.planet, this.start, this.end);
}

class PanchapakshiRules {
  static const List<Pakshi> birdOrder = [
    Pakshi.vallooru,
    Pakshi.aandhai,
    Pakshi.kaagam,
    Pakshi.kozhi,
    Pakshi.mayil,
  ];

  // ---------------------------------------------------------------------
  // Table 5: நட்சத்திரம் -> பட்சி (which bird "owns" a person, by star
  // and by current fortnight). 27 stars, index 0 = அஸ்வினி.
  // ---------------------------------------------------------------------
  static const List<String> nakshatraNames = [
    'அஸ்வினி', 'பரணி', 'கார்த்திகை', 'ரோகிணி', 'மிருகசீரிஷம்', 'திருவாதிரை',
    'புனர்பூசம்', 'பூசம்', 'ஆயில்யம்', 'மகம்', 'பூரம்', 'உத்திரம்',
    'ஹஸ்தம்', 'சித்திரை', 'சுவாதி', 'விசாகம்', 'அனுஷம்', 'கேட்டை',
    'மூலம்', 'பூராடம்', 'உத்திராடம்', 'திருவோணம்', 'அவிட்டம்', 'சதயம்',
    'பூரட்டாதி', 'உத்திரட்டாதி', 'ரேவதி',
  ];

  static const List<Pakshi> _waxingBirdByStar = [
    Pakshi.vallooru, Pakshi.aandhai, Pakshi.kaagam, Pakshi.kozhi, Pakshi.mayil, Pakshi.mayil,
    Pakshi.kozhi, Pakshi.kaagam, Pakshi.aandhai, Pakshi.vallooru, Pakshi.vallooru, Pakshi.aandhai,
    Pakshi.kaagam, Pakshi.kozhi, Pakshi.mayil, Pakshi.mayil, Pakshi.kozhi, Pakshi.kaagam,
    Pakshi.aandhai, Pakshi.vallooru, Pakshi.vallooru, Pakshi.aandhai, Pakshi.kaagam, Pakshi.kozhi,
    Pakshi.mayil, Pakshi.mayil, Pakshi.kozhi,
  ];

  static const List<Pakshi> _waningBirdByStar = [
    Pakshi.mayil, Pakshi.kozhi, Pakshi.kaagam, Pakshi.aandhai, Pakshi.vallooru, Pakshi.vallooru,
    Pakshi.aandhai, Pakshi.kaagam, Pakshi.kozhi, Pakshi.mayil, Pakshi.mayil, Pakshi.kozhi,
    Pakshi.kaagam, Pakshi.aandhai, Pakshi.vallooru, Pakshi.vallooru, Pakshi.aandhai, Pakshi.kaagam,
    Pakshi.kozhi, Pakshi.mayil, Pakshi.mayil, Pakshi.kozhi, Pakshi.kaagam, Pakshi.aandhai,
    Pakshi.vallooru, Pakshi.vallooru, Pakshi.aandhai,
  ];

  /// Birth-star based "owner" bird (லக்னப் பட்சி usage). [starIndex] is 0-26.
  static Pakshi birdForStar(int starIndex, Paksham paksham) {
    return paksham == Paksham.valarpirai
        ? _waxingBirdByStar[starIndex]
        : _waningBirdByStar[starIndex];
  }

  // ---------------------------------------------------------------------
  // Table 4: ஒரு தொழிலின் நீள்வு (in "standard minutes", out of the
  // 5x24=120 std-minutes/ஜாமம் scale used by the book to weight unequal
  // Jamam-widths). Kept for reference / classic-method compatibility.
  // Order: ஊண் நடை அரசு துயில் சாவு
  // ---------------------------------------------------------------------
  static const Map<String, int> waxingDayMinutes = {
    'ஊண்': 48, 'நடை': 36, 'அரசு': 30, 'துயில்': 18, 'சாவு': 12,
  };
  static const Map<String, int> waxingNightMinutes = {
    'ஊண்': 12, 'அரசு': 48, 'சாவு': 36, 'நடை': 30, 'துயில்': 18,
  };
  static const Map<String, int> waningDayMinutes = {
    'ஊண்': 30, 'சாவு': 18, 'துயில்': 12, 'அரசு': 48, 'நடை': 36,
  };
  static const Map<String, int> waningNightMinutes = {
    'ஊண்': 48, 'துயில்': 36, 'நடை': 30, 'சாவு': 18, 'அரசு': 12,
  };

  // ---------------------------------------------------------------------
  // Tables 6 & 7: weekday -> ruling பட்சி for day / night (whose "reign"
  // the day belongs to under Poorva/Amara classification).
  // ---------------------------------------------------------------------
  static const List<Pakshi> waxingDayRulerByWeekday = [
    Pakshi.vallooru, // Sunday
    Pakshi.aandhai,  // Monday
    Pakshi.vallooru, // Tuesday
    Pakshi.aandhai,  // Wednesday
    Pakshi.kaagam,   // Thursday
    Pakshi.kozhi,    // Friday
    Pakshi.mayil,    // Saturday
  ];
  static const List<Pakshi> waningDayRulerByWeekday = [
    Pakshi.kozhi, Pakshi.mayil, Pakshi.kozhi, Pakshi.kaagam,
    Pakshi.aandhai, Pakshi.vallooru, Pakshi.mayil,
  ];

  // ---------------------------------------------------------------------
  // Tables 10: full Jamam->Thozhil grids, keyed by [paksham][dayNight]
  // [weekday group]. This is the authoritative table the engine uses.
  // Row = jamam (0..4), Col = bird (birdOrder above).
  // ---------------------------------------------------------------------
  static const _u = Thozhil.oon;
  static const _n = Thozhil.nadai;
  static const _a = Thozhil.arasu;
  static const _t = Thozhil.thuyil;
  static const _s = Thozhil.saavu;

  // Weekday groups used by the book (0=Sun..6=Sat):
  // group A = {Sun, Tue}, group B(waxing) = {Mon, Wed}, group C = {Thu},
  // group D = {Fri}, group E(waxing) = {Sat}
  // For waning: group B' = {Wed}, group E' = {Mon, Sat}
  static const Map<int, List<List<Thozhil>>> _waxingDay = {
    0: [ // Sun & Tue
      [_u, _n, _a, _t, _s],
      [_n, _a, _t, _s, _u],
      [_a, _t, _s, _u, _n],
      [_t, _s, _u, _n, _a],
      [_s, _u, _n, _a, _t],
    ],
    1: [ // Mon & Wed
      [_s, _u, _n, _a, _t],
      [_u, _n, _a, _t, _s],
      [_n, _a, _t, _s, _u],
      [_a, _t, _s, _u, _n],
      [_t, _s, _u, _n, _a],
    ],
    2: [ // Thu
      [_t, _s, _u, _n, _a],
      [_s, _u, _n, _a, _t],
      [_u, _n, _a, _t, _s],
      [_n, _a, _t, _s, _u],
      [_a, _t, _s, _u, _n],
    ],
    3: [ // Fri
      [_a, _t, _s, _u, _n],
      [_t, _s, _u, _n, _a],
      [_s, _u, _n, _a, _t],
      [_u, _n, _a, _t, _s],
      [_n, _a, _t, _s, _u],
    ],
    4: [ // Sat
      [_n, _a, _t, _s, _u],
      [_a, _t, _s, _u, _n],
      [_t, _s, _u, _n, _a],
      [_s, _u, _n, _a, _t],
      [_u, _n, _a, _t, _s],
    ],
  };

  static const Map<int, List<List<Thozhil>>> _waxingNight = {
    0: [ // Sun & Tue
      [_s, _a, _u, _t, _n],
      [_n, _s, _a, _u, _t],
      [_t, _n, _s, _a, _u],
      [_u, _t, _n, _s, _a],
      [_a, _u, _t, _n, _s],
    ],
    1: [ // Mon & Wed
      [_n, _s, _a, _u, _t],
      [_t, _n, _s, _a, _u],
      [_u, _t, _n, _s, _a],
      [_a, _u, _t, _n, _s],
      [_s, _a, _u, _t, _n],
    ],
    2: [ // Thu
      [_t, _n, _s, _a, _u],
      [_u, _t, _n, _s, _a],
      [_a, _u, _t, _n, _s],
      [_s, _a, _u, _t, _n],
      [_n, _s, _a, _u, _t],
    ],
    3: [ // Fri
      [_u, _t, _n, _s, _a],
      [_a, _u, _t, _n, _s],
      [_s, _a, _u, _t, _n],
      [_n, _s, _a, _u, _t],
      [_t, _n, _s, _a, _u],
    ],
    4: [ // Sat
      [_a, _u, _t, _n, _s],
      [_s, _a, _u, _t, _n],
      [_n, _s, _a, _u, _t],
      [_t, _n, _s, _a, _u],
      [_u, _t, _n, _s, _a],
    ],
  };

  static const Map<int, List<List<Thozhil>>> _waningDay = {
    0: [ // Sun & Tue
      [_u, _s, _t, _a, _n],
      [_s, _t, _a, _n, _u],
      [_t, _a, _n, _u, _s],
      [_a, _n, _u, _s, _t],
      [_n, _u, _s, _t, _a],
    ],
    1: [ // Wed
      [_s, _t, _a, _n, _u],
      [_t, _a, _n, _u, _s],
      [_a, _n, _u, _s, _t],
      [_n, _u, _s, _t, _a],
      [_u, _s, _t, _a, _n],
    ],
    2: [ // Thu
      [_t, _a, _n, _u, _s],
      [_a, _n, _u, _s, _t],
      [_n, _u, _s, _t, _a],
      [_u, _s, _t, _a, _n],
      [_s, _t, _a, _n, _u],
    ],
    3: [ // Fri
      [_a, _n, _u, _s, _t],
      [_n, _u, _s, _t, _a],
      [_u, _s, _t, _a, _n],
      [_s, _t, _a, _n, _u],
      [_t, _a, _n, _u, _s],
    ],
    4: [ // Mon & Sat
      [_n, _u, _s, _t, _a],
      [_u, _s, _t, _a, _n],
      [_s, _t, _a, _n, _u],
      [_t, _a, _n, _u, _s],
      [_a, _n, _u, _s, _t],
    ],
  };

  static const Map<int, List<List<Thozhil>>> _waningNight = {
    0: [ // Sun & Tue
      [_a, _s, _n, _t, _u],
      [_u, _a, _s, _n, _t],
      [_t, _u, _a, _s, _n],
      [_n, _t, _u, _a, _s],
      [_s, _n, _t, _u, _a],
    ],
    1: [ // Wed
      [_s, _n, _t, _u, _a],
      [_a, _s, _n, _t, _u],
      [_u, _a, _s, _n, _t],
      [_t, _u, _a, _s, _n],
      [_n, _t, _u, _a, _s],
    ],
    2: [ // Thu
      [_n, _t, _u, _a, _s],
      [_s, _n, _t, _u, _a],
      [_a, _s, _n, _t, _u],
      [_u, _a, _s, _n, _t],
      [_t, _u, _a, _s, _n],
    ],
    3: [ // Fri
      [_t, _u, _a, _s, _n],
      [_n, _t, _u, _a, _s],
      [_s, _n, _t, _u, _a],
      [_a, _s, _n, _t, _u],
      [_u, _a, _s, _n, _t],
    ],
    4: [ // Mon & Sat
      [_u, _a, _s, _n, _t],
      [_t, _u, _a, _s, _n],
      [_n, _t, _u, _a, _s],
      [_s, _n, _t, _u, _a],
      [_a, _s, _n, _t, _u],
    ],
  };

  /// Maps a weekday (DateTime.weekday: 1=Mon..7=Sun) to the workbook's
  /// weekday-group index used to pick the right grid above.
  static int weekdayGroup(int dateTimeWeekday, Paksham paksham) {
    // Normalize to 0=Sun..6=Sat
    final w = dateTimeWeekday % 7; // DateTime: Mon=1..Sun=7 -> Sun=0
    if (paksham == Paksham.valarpirai) {
      if (w == 0 || w == 2) return 0; // Sun, Tue
      if (w == 1 || w == 3) return 1; // Mon, Wed
      if (w == 4) return 2; // Thu
      if (w == 5) return 3; // Fri
      return 4; // Sat
    } else {
      if (w == 0 || w == 2) return 0; // Sun, Tue
      if (w == 3) return 1; // Wed
      if (w == 4) return 2; // Thu
      if (w == 5) return 3; // Fri
      return 4; // Mon(1), Sat(6)
    }
  }

  /// Returns the Thozhil (activity) for [bird] in [jamam] (1-5) for the
  /// given [paksham]/[dayNight] on the weekday of [date].
  static Thozhil activityFor({
    required Pakshi bird,
    required int jamam, // 1..5
    required Paksham paksham,
    required DayNight dayNight,
    required int dateTimeWeekday,
  }) {
    final group = weekdayGroup(dateTimeWeekday, paksham);
    final grid = paksham == Paksham.valarpirai
        ? (dayNight == DayNight.day ? _waxingDay : _waxingNight)
        : (dayNight == DayNight.day ? _waningDay : _waningNight);
    final row = grid[group]![jamam - 1];
    final birdIdx = birdOrder.indexOf(bird);
    return row[birdIdx];
  }

  // ---------------------------------------------------------------------
  // Gowri Panchangam — 8 fixed clock-time slots (06:00-18:00 day,
  // 18:00-06:00 night), value differs by weekday. NOT sun-adjusted;
  // this table is always read on the standard 24-hour clock.
  // ---------------------------------------------------------------------
  static const List<String> gowriGoodSlots = ['உத்தி', 'லாபம்', 'அமிர்', 'சுகம்', 'தனம்'];
  static const List<String> gowriBadSlots = ['விஷம்', 'ரோகம்', 'சோரம்'];

  /// index 0..15 = each 90-minute slot starting 06:00, wrapping through
  /// the next day's 06:00. weekdayIdx: 0=Sun..6=Sat.
  static const List<List<String>> gowriTable = [
    ['உத்தி', 'அமிர்', 'ரோகம்', 'லாபம்', 'தனம்', 'சுகம்', 'சோரம்'],
    ['அமிர்', 'விஷம்', 'தனம்', 'தனம்', 'சுகம்', 'சோரம்', 'உத்தி'],
    ['ரோகம்', 'ரோகம்', 'லாபம்', 'சுகம்', 'சோரம்', 'உத்தி', 'விஷம்'],
    ['லாபம்', 'லாபம்', 'சுகம்', 'சோரம்', 'உத்தி', 'விஷம்', 'அமிர்'],
    ['தனம்', 'தனம்', 'சோரம்', 'விஷம்', 'அமிர்', 'அமிர்', 'ரோகம்'],
    ['சுகம்', 'சுகம்', 'உத்தி', 'உத்தி', 'விஷம்', 'ரோகம்', 'லாபம்'],
    ['சோரம்', 'சோரம்', 'விஷம்', 'அமிர்', 'ரோகம்', 'லாபம்', 'தனம்'],
    ['விஷம்', 'உத்தி', 'அமிர்', 'ரோகம்', 'லாபம்', 'தனம்', 'சுகம்'],
    ['தனம்', 'சுகம்', 'சோரம்', 'உத்தி', 'அமிர்', 'ரோகம்', 'லாபம்'],
    ['சுகம்', 'சோரம்', 'விஷம்', 'அமிர்', 'விஷம்', 'லாபம்', 'தனம்'],
    ['சோரம்', 'உத்தி', 'உத்தி', 'ரோகம்', 'ரோகம்', 'தனம்', 'சுகம்'],
    ['விஷம்', 'அமிர்', 'அமிர்', 'லாபம்', 'லாபம்', 'சுகம்', 'சோரம்'],
    ['உத்தி', 'விஷம்', 'ரோகம்', 'தனம்', 'தனம்', 'சோரம்', 'உத்தி'],
    ['அமிர்', 'ரோகம்', 'லாபம்', 'சுகம்', 'சுகம்', 'உத்தி', 'விஷம்'],
    ['ரோகம்', 'லாபம்', 'தனம்', 'சோரம்', 'சோரம்', 'விஷம்', 'அமிர்'],
    ['லாபம்', 'தனம்', 'சுகம்', 'விஷம்', 'உத்தி', 'அமிர்', 'ரோகம்'],
  ];

  /// Returns the Gowri slot (label + its real start/end DateTime) that
  /// [instant] falls inside. Slots are fixed 90-minute blocks on the
  /// standard 24-hour clock starting at 06:00 (NOT sun-adjusted).
  static GowriSlot gowriSlotFor(DateTime instant) {
    var dayAnchor = DateTime(instant.year, instant.month, instant.day, 6);
    if (instant.isBefore(dayAnchor)) {
      dayAnchor = dayAnchor.subtract(const Duration(days: 1));
    }
    final elapsedMinutes = instant.difference(dayAnchor).inMinutes;
    final slotIndex = (elapsedMinutes ~/ 90).clamp(0, 15);
    final slotStart = dayAnchor.add(Duration(minutes: 90 * slotIndex));
    final slotEnd = slotStart.add(const Duration(minutes: 90));
    // DateTime.weekday: Mon=1..Sun=7 -> convert to 0=Sun..6=Sat
    final weekdayIdx = slotStart.weekday % 7;
    return GowriSlot(gowriTable[slotIndex][weekdayIdx], slotStart, slotEnd);
  }

  // ---------------------------------------------------------------------
  // Horai — hourly planetary lord, fixed clock (06:00 start), cycles
  // through a fixed 7-planet order offset per weekday.
  // ---------------------------------------------------------------------
  static const List<String> horaiPlanetCycle = [
    'சூரியன்', 'சுக்கிரன்', 'புதன்', 'சந்திரன்', 'சனி', 'குரு', 'செவ்வாய்',
  ];
  // Starting planet index (into horaiPlanetCycle) for hour-0 (06:00-07:00)
  // by weekday, 0=Sun..6=Sat.
  static const List<int> horaiStartIndexByWeekday = [0, 3, 6, 2, 5, 1, 4];

  /// Returns the Horai slot (planet + its real start/end DateTime) that
  /// [instant] falls inside. Slots are fixed 1-hour blocks on the
  /// standard 24-hour clock starting at 06:00 (NOT sun-adjusted).
  static HoraiSlot horaiSlotFor(DateTime instant) {
    var dayAnchor = DateTime(instant.year, instant.month, instant.day, 6);
    if (instant.isBefore(dayAnchor)) {
      dayAnchor = dayAnchor.subtract(const Duration(days: 1));
    }
    final elapsedHours = instant.difference(dayAnchor).inHours;
    final hourIndex = elapsedHours.clamp(0, 23);
    final slotStart = dayAnchor.add(Duration(hours: hourIndex));
    final slotEnd = slotStart.add(const Duration(hours: 1));
    final weekdayIdx = slotStart.weekday % 7;
    final startIdx = horaiStartIndexByWeekday[weekdayIdx];
    final planet = horaiPlanetCycle[(startIdx + hourIndex) % 7];
    return HoraiSlot(planet, slotStart, slotEnd);
  }
}
