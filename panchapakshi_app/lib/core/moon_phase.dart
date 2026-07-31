import '../models/pakshi.dart';

/// Determines வளர்பிறை (waxing) vs தேய்பிறை (waning) fortnight for a date.
///
/// IMPORTANT — accuracy note for whoever maintains this:
/// True Panchapakshi Sastra determines Paksham from the Tamil lunar
/// Thithi (which requires precise Sun-Moon longitude difference, not
/// just a mean synodic-month estimate). The formula below is a
/// standard mean-synodic-month approximation anchored to a known new
/// moon, accurate to within ~1 day in most cases, which is adequate
/// for a first working build. For production-grade accuracy, replace
/// [paskhamFor] with a call to a proper Panchangam/Thithi engine or a
/// drik-ganita ephemeris (e.g. Swiss Ephemeris) — the rest of the app
/// (rules, engine, UI) does not need to change; only this function
/// does, since everything downstream just consumes the enum value.
class MoonPhase {
  // A known new moon (amavasai) reference instant, UTC.
  static final DateTime _referenceNewMoon =
      DateTime.utc(2000, 1, 6, 18, 14);
  static const double _synodicMonthDays = 29.530588853;

  static Paksham paskhamFor(DateTime dateUtc) {
    final daysSinceRef = dateUtc.difference(_referenceNewMoon).inHours / 24.0;
    var age = daysSinceRef % _synodicMonthDays;
    if (age < 0) age += _synodicMonthDays;
    // 0..14.77 days after new moon = waxing (வளர்பிறை, building to full moon)
    // 14.77..29.53 days = waning (தேய்பிறை, shrinking back to new moon)
    return age < (_synodicMonthDays / 2) ? Paksham.valarpirai : Paksham.theipirai;
  }

  /// Approximate moon age in days (0 = new moon, ~14.77 = full moon).
  static double moonAgeDays(DateTime dateUtc) {
    final daysSinceRef = dateUtc.difference(_referenceNewMoon).inHours / 24.0;
    var age = daysSinceRef % _synodicMonthDays;
    if (age < 0) age += _synodicMonthDays;
    return age;
  }
}
