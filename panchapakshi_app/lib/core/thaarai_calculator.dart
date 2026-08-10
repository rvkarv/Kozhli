import 'panchapakshi_rules.dart';
import 'thaarai_rules.dart';

/// Computes the Thaarai (தாரை) relationship between the person's birth
/// star and today's transiting star.
///
/// The verified workbook defines the Thaarai category by the 1..27 ordinal
/// counted forward from the birth nakshatra. The category repeats every 9
/// stars (5/14/23 = பிரத்யக்கு, 9/18/27 = அதிமைத்ர, etc.), but the workbook
/// also contains a distinct effect for each of the 27 positions. Therefore
/// this calculator must select [ThaaraiRules.byOrdinal] using offset + 1,
/// not categories[offset % 9].
class ThaaraiResult {
  final String birthNakshatra;
  final String todayNakshatra;

  /// 0..26 — zero-based number of stars ahead today's star is from the birth
  /// star, counting forward through the 27-nakshatra cycle.
  final int offsetFromBirth;

  /// 1..27 — the workbook's ordinal counted from the birth nakshatra.
  final int ordinalFromBirth;

  final ThaaraiCategory category;

  const ThaaraiResult({
    required this.birthNakshatra,
    required this.todayNakshatra,
    required this.offsetFromBirth,
    required this.ordinalFromBirth,
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

    // Dart's % is a remainder, so normalise explicitly to 0..26.
    final offset = (todayIndex - birthIndex + names.length) % names.length;

    // Workbook numbering is 1-based: the birth star itself is 1st,
    // the next star is 2nd, ..., and the 27th star is the last position.
    final ordinal = offset + 1;
    final category = ThaaraiRules.forOrdinal(ordinal);

    return ThaaraiResult(
      birthNakshatra: birthNakshatra,
      todayNakshatra: todayNakshatra,
      offsetFromBirth: offset,
      ordinalFromBirth: ordinal,
      category: category,
    );
  }
}
