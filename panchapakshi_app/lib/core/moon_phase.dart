import 'nakshatra_calculator.dart';
import '../models/pakshi.dart';

/// Waxing (வளர்பிறை) vs Waning (தேய்பிறை), now computed from the real
/// lunar-solar elongation via NakshatraCalculator — no more mean-motion
/// approximation. [dateUtc] must be a true UTC instant.
class MoonPhase {
  static Paksham paskhamFor(DateTime dateUtc) {
    final pos = NakshatraCalculator.computeCurrent(dateUtc);
    return pos.isWaxing ? Paksham.valarpirai : Paksham.theipirai;
  }
}
