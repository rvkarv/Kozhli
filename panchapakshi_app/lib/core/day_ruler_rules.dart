import '../models/pakshi.dart';

class DayRulerInfo {
  final Pakshi ruler; // அதிகார பட்சி
  final Pakshi subordinate; // படு பட்சி
  final List<Pakshi> enemies; // பகை பட்சி (2)
  final Pakshi friend; // நட்பு பட்சி
  const DayRulerInfo({
    required this.ruler,
    required this.subordinate,
    required this.enemies,
    required this.friend,
  });
}

/// கோழி அதிகார நாள் / படுபட்சி நாள் table — transcribed directly from the
/// per-bird sheets ("வ"-கோழி, "தே"-கோழி etc.) in your workbook, and
/// cross-verified against LookupData's Table_PagaiFixed and the
/// Pentagon adjacency logic. All three sources agree.
class DayRulerRules {
  static const Map<int, DayRulerInfo> _waxing = {
    0: DayRulerInfo(ruler: Pakshi.vallooru, subordinate: Pakshi.mayil, enemies: [Pakshi.kaagam, Pakshi.kozhi], friend: Pakshi.aandhai), // Sun, Tue
    1: DayRulerInfo(ruler: Pakshi.aandhai, subordinate: Pakshi.vallooru, enemies: [Pakshi.kozhi, Pakshi.mayil], friend: Pakshi.kaagam), // Mon, Wed
    2: DayRulerInfo(ruler: Pakshi.kaagam, subordinate: Pakshi.aandhai, enemies: [Pakshi.mayil, Pakshi.vallooru], friend: Pakshi.kozhi), // Thu
    3: DayRulerInfo(ruler: Pakshi.kozhi, subordinate: Pakshi.kaagam, enemies: [Pakshi.vallooru, Pakshi.aandhai], friend: Pakshi.mayil), // Fri
    4: DayRulerInfo(ruler: Pakshi.mayil, subordinate: Pakshi.kozhi, enemies: [Pakshi.aandhai, Pakshi.kaagam], friend: Pakshi.vallooru), // Sat
  };

  static const Map<int, DayRulerInfo> _waning = {
    0: DayRulerInfo(ruler: Pakshi.kozhi, subordinate: Pakshi.kaagam, enemies: [Pakshi.vallooru, Pakshi.aandhai], friend: Pakshi.mayil), // Sun, Tue
    1: DayRulerInfo(ruler: Pakshi.mayil, subordinate: Pakshi.kozhi, enemies: [Pakshi.aandhai, Pakshi.kaagam], friend: Pakshi.vallooru), // Mon, Sat
    2: DayRulerInfo(ruler: Pakshi.kaagam, subordinate: Pakshi.aandhai, enemies: [Pakshi.mayil, Pakshi.vallooru], friend: Pakshi.kozhi), // Wed
    3: DayRulerInfo(ruler: Pakshi.aandhai, subordinate: Pakshi.vallooru, enemies: [Pakshi.kozhi, Pakshi.mayil], friend: Pakshi.kaagam), // Thu
    4: DayRulerInfo(ruler: Pakshi.vallooru, subordinate: Pakshi.mayil, enemies: [Pakshi.kaagam, Pakshi.kozhi], friend: Pakshi.aandhai), // Fri
  };

  /// [dateTimeWeekday] uses DateTime.weekday convention (Mon=1..Sun=7).
  static DayRulerInfo forWeekday(int dateTimeWeekday, Paksham paksham) {
    final w = dateTimeWeekday % 7; // Sun=0..Sat=6
    final group = paksham == Paksham.valarpirai
        ? (w == 0 || w == 2
            ? 0
            : w == 1 || w == 3
                ? 1
                : w == 4
                    ? 2
                    : w == 5
                        ? 3
                        : 4)
        : (w == 0 || w == 2
            ? 0
            : w == 1 || w == 6
                ? 1
                : w == 3
                    ? 2
                    : w == 4
                        ? 3
                        : 4);
    final table = paksham == Paksham.valarpirai ? _waxing : _waning;
    return table[group]!;
  }
}
