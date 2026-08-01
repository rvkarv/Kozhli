import 'panchapakshi_rules.dart';
import 'thaarai_rules.dart';

/// Computes the Thaarai (தாரை) relationship between the person's birth
/// star and today's transiting star. The 9-fold cycle repeats every 9
/// stars across all 27 nakshatras: offset 0 is always ஜென்ம தாரை,
/// offset 1 is சம்பத்து தாரை, and so on (offset mod 9 selects the
/// category from [ThaaraiRules.categories]).
class ThaaraiResult {
  final String birthNakshatra;
  final String todayNakshatra;

  /// 0..26 — how many stars ahead today's star is from the birth star,
  /// counting forward through the 27-nakshatra cycle.
  final int offsetFromBirth;

  final ThaaraiCategory category;

  const ThaaraiResult({
    required this.birthNakshatra,
    required this.todayNakshatra,
    required this.offsetFromBirth,
    required this.category,
  });
}

class ThaaraiCalculator {
  /// Returns null if either star hasn't been determined yet (e.g. birth
  /// star not set, or today's Moon position not computed yet).
  static ThaaraiResult? compute({
    required String? birthNakshatra,
    required String? todayNakshatra,
  }) {
    if (birthNakshatra == null || todayNakshatra == null) return null;

    final names = PanchapakshiRules.nakshatraNames;
    final birthIndex = names.indexOf(birthNakshatra);
    final todayIndex = names.indexOf(todayNakshatra);
    if (birthIndex == -1 || todayIndex == -1) return null;

    final offset = (todayIndex - birthIndex) % names.length;
    final category = ThaaraiRules.categories[offset % 9];

    return ThaaraiResult(
      birthNakshatra: birthNakshatra,
      todayNakshatra: todayNakshatra,
      offsetFromBirth: offset,
      category: category,
    );
  }
}
