import '../models/pakshi.dart';

class PanchapakshiRules {
  static const List<Pakshi> birdOrder = [
    Pakshi.vallooru,
    Pakshi.aandhai,
    Pakshi.kaagam,
    Pakshi.kozhi,
    Pakshi.mayil,
  ];

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

  static Pakshi birdForStar(int starIndex, Paksham paksham) {
    return paksham == Paksham.valarpirai
        ? _waxingBirdByStar[starIndex]
        : _waningBirdByStar[starIndex];
  }

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

  /// Returns the correct standard-minute weight table for the given
  /// paksham/day-night combination — used by PanchapakshiEngine to
  /// compute the WEIGHTED (not equal-fifths) அந்தரம் durations.
  static Map<String, int> minutesTableFor(Paksham paksham, DayNight dayNight) {
    if (paksham == Paksham.valarpirai) {
      return dayNight == DayNight.day ? waxingDayMinutes : waxingNightMinutes;
    } else {
      return dayNight == DayNight.day ? waningDayMinutes : waningNightMinutes;
    }
  }

  static const List<Pakshi> waxingDayRulerByWeekday = [
    Pakshi.vallooru, Pakshi.aandhai, Pakshi.vallooru, Pakshi.aandhai,
    Pakshi.kaagam, Pakshi.kozhi, Pakshi.mayil,
  ];
  static const List<Pakshi> waningDayRulerByWeekday = [
    Pakshi.kozhi, Pakshi.mayil, Pakshi.kozhi, Pakshi.kaagam,
    Pakshi.aandhai, Pakshi.vallooru, Pakshi.mayil,
  ];

  static const _u = Thozhil.oon;
  static const _n = Thozhil.nadai;
  static const _a = Thozhil.arasu;
  static const _t = Thozhil.thuyil;
  static const _s = Thozhil.saavu;

  static const Map<int, List<List<Thozhil>>> _waxingDay = {
    0: [
      [_u, _n, _a, _t, _s],
      [_n, _a, _t, _s, _u],
      [_a, _t, _s, _u, _n],
      [_t, _s, _u, _n, _a],
      [_s, _u, _n, _a, _t],
    ],
    1: [
      [_s, _u, _n, _a, _t],
      [_u, _n, _a, _t, _s],
      [_n, _a, _t, _s, _u],
      [_a, _t, _s, _u, _n],
      [_t, _s, _u, _n, _a],
    ],
    2: [
      [_t, _s, _u, _n, _a],
      [_s, _u, _n, _a, _t],
      [_u, _n, _a, _t, _s],
      [_n, _a, _t, _s, _u],
      [_a, _t, _s, _u, _n],
    ],
    3: [
      [_a, _t, _s, _u, _n],
      [_t, _s, _u, _n, _a],
      [_s, _u, _n, _a, _t],
      [_u, _n, _a, _t, _s],
      [_n, _a, _t, _s, _u],
    ],
    4: [
      [_n, _a, _t, _s, _u],
      [_a, _t, _s, _u, _n],
      [_t, _s, _u, _n, _a],
      [_s, _u, _n, _a, _t],
      [_u, _n, _a, _t, _s],
    ],
  };

  static const Map<int, List<List<Thozhil>>> _waxingNight = {
    0: [
      [_s, _a, _u, _t, _n],
      [_n, _s, _a, _u, _t],
      [_t, _n, _s, _a, _u],
      [_u, _t, _n, _s, _a],
      [_a, _u, _t, _n, _s],
    ],
    1: [
      [_n, _s, _a, _u, _t],
      [_t, _n, _s, _a, _u],
      [_u, _t, _n, _s, _a],
      [_a, _u, _t, _n, _s],
      [_s, _a, _u, _t, _n],
    ],
    2: [
      [_t, _n, _s, _a, _u],
      [_u, _t, _n, _s, _a],
      [_a, _u, _t, _n, _s],
      [_s, _a, _u, _t, _n],
      [_n, _s, _a, _u, _t],
    ],
    3: [
      [_u, _t, _n, _s, _a],
      [_a, _u, _t, _n, _s],
      [_s, _a, _u, _t, _n],
      [_n, _s, _a, _u, _t],
      [_t, _n, _s, _a, _u],
    ],
    4: [
      [_a, _u, _t, _n, _s],
      [_s, _a, _u, _t, _n],
      [_n, _s, _a, _u, _t],
      [_t, _n, _s, _a, _u],
      [_u, _t, _n, _s, _a],
    ],
  };

  static const Map<int, List<List<Thozhil>>> _waningDay = {
    0: [
      [_u, _s, _t, _a, _n],
      [_s, _t, _a, _n, _u],
      [_t, _a, _n, _u, _s],
      [_a, _n, _u, _s, _t],
      [_n, _u, _s, _t, _a],
    ],
    1: [
      [_s, _t, _a, _n, _u],
      [_t, _a, _n, _u, _s],
      [_a, _n, _u, _s, _t],
      [_n, _u, _s, _t, _a],
      [_u, _s, _t, _a, _n],
    ],
    2: [
      [_t, _a, _n, _u, _s],
      [_a, _n, _u, _s, _t],
      [_n, _u, _s, _t, _a],
      [_u, _s, _t, _a, _n],
      [_s, _t, _a, _n, _u],
    ],
    3: [
      [_a, _n, _u, _s, _t],
      [_n, _u, _s, _t, _a],
      [_u, _s, _t, _a, _n],
      [_s, _t, _a, _n, _u],
      [_t, _a, _n, _u, _s],
    ],
    4: [
      [_n, _u, _s, _t, _a],
      [_u, _s, _t, _a, _n],
      [_s, _t, _a, _n, _u],
      [_t, _a, _n, _u, _s],
      [_a, _n, _u, _s, _t],
    ],
  };

  static const Map<int, List<List<Thozhil>>> _waningNight = {
    0: [
      [_a, _s, _n, _t, _u],
      [_u, _a, _s, _n, _t],
      [_t, _u, _a, _s, _n],
      [_n, _t, _u, _a, _s],
      [_s, _n, _t, _u, _a],
    ],
    1: [
      [_s, _n, _t, _u, _a],
      [_a, _s, _n, _t, _u],
      [_u, _a, _s, _n, _t],
      [_t, _u, _a, _s, _n],
      [_n, _t, _u, _a, _s],
    ],
    2: [
      [_n, _t, _u, _a, _s],
      [_s, _n, _t, _u, _a],
      [_a, _s, _n, _t, _u],
      [_u, _a, _s, _n, _t],
      [_t, _u, _a, _s, _n],
    ],
    3: [
      [_t, _u, _a, _s, _n],
      [_n, _t, _u, _a, _s],
      [_s, _n, _t, _u, _a],
      [_a, _s, _n, _t, _u],
      [_u, _a, _s, _n, _t],
    ],
    4: [
      [_u, _a, _s, _n, _t],
      [_t, _u, _a, _s, _n],
      [_n, _t, _u, _a, _s],
      [_s, _n, _t, _u, _a],
      [_a, _s, _n, _t, _u],
    ],
  };

  static int weekdayGroup(int dateTimeWeekday, Paksham paksham) {
    final w = dateTimeWeekday % 7;
    if (paksham == Paksham.valarpirai) {
      if (w == 0 || w == 2) return 0;
      if (w == 1 || w == 3) return 1;
      if (w == 4) return 2;
      if (w == 5) return 3;
      return 4;
    } else {
      if (w == 0 || w == 2) return 0;
      if (w == 3) return 1;
      if (w == 4) return 2;
      if (w == 5) return 3;
      return 4;
    }
  }

  static Thozhil activityFor({
    required Pakshi bird,
    required int jamam,
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

  static const List<String> gowriGoodSlots = ['உத்தி', 'லாபம்', 'அமிர்', 'சுகம்', 'தனம்'];
  static const List<String> gowriBadSlots = ['விஷம்', 'ரோகம்', 'சோரம்'];

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

  static const List<String> horaiPlanetCycle = [
    'சூரியன்', 'சுக்கிரன்', 'புதன்', 'சந்திரன்', 'சனி', 'குரு', 'செவ்வாய்',
  ];
  static const List<int> horaiStartIndexByWeekday = [0, 3, 6, 2, 5, 1, 4];
}
