import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Central IANA timezone service for the KOZHLI PANCHAPAKSHI app.
///
/// This service provides:
/// - IANA timezone lookup
/// - Date-specific UTC offsets
/// - Automatic DST handling
/// - Conversion between UTC and local timezone
/// - DST status
///
/// IMPORTANT:
/// The application must NOT use a fixed country UTC offset.
/// The IANA timezone database determines the applicable offset
/// for the actual selected location and date.
class TimezoneService {
  TimezoneService._();

  static bool _initialized = false;

  /// Initialize the embedded IANA timezone database.
  ///
  /// Safe to call multiple times.
  static void initialize() {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    _initialized = true;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  /// Return the IANA timezone location.
  ///
  /// Example:
  /// America/Chicago
  /// America/Indiana/Indianapolis
  /// Asia/Kolkata
  static tz.Location location(String ianaName) {
    _ensureInitialized();
    return tz.getLocation(ianaName);
  }

  /// Return the UTC offset applicable to the supplied UTC instant.
  ///
  /// The IANA database automatically applies the correct DST rule
  /// for the supplied date.
  static Duration offsetAtUtc({
    required String ianaName,
    required DateTime utc,
  }) {
    _ensureInitialized();

    final zone = tz.getLocation(ianaName);
    final instant = utc.toUtc();

    final period = zone.timeZone(
      instant.millisecondsSinceEpoch,
    );

    return period.offsetAsDuration;
  }

  /// Convert a UTC instant to the selected IANA timezone.
  static tz.TZDateTime fromUtc({
    required String ianaName,
    required DateTime utc,
  }) {
    _ensureInitialized();

    final zone = tz.getLocation(ianaName);

    return tz.TZDateTime.from(
      utc.toUtc(),
      zone,
    );
  }

  /// Create a timezone-aware local date/time.
  ///
  /// This will be used later for Future/Past calculations.
  static tz.TZDateTime localDateTime({
    required String ianaName,
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
  }) {
    _ensureInitialized();

    final zone = tz.getLocation(ianaName);

    return tz.TZDateTime(
      zone,
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
  }

  /// Return the timezone abbreviation applicable at the supplied
  /// UTC instant.
  ///
  /// Examples:
  /// CST
  /// CDT
  /// EST
  /// EDT
  static String abbreviationAtUtc({
    required String ianaName,
    required DateTime utc,
  }) {
    final local = fromUtc(
      ianaName: ianaName,
      utc: utc,
    );

    return local.timeZoneName;
  }

  /// Return true when the selected UTC instant is observing DST.
  static bool isDaylightSavingAtUtc({
    required String ianaName,
    required DateTime utc,
  }) {
    _ensureInitialized();

    final zone = tz.getLocation(ianaName);
    final instant = utc.toUtc();

    final period = zone.timeZone(
      instant.millisecondsSinceEpoch,
    );

    return period.isDst;
  }
}
