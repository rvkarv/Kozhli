import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Central IANA timezone service for the KOZHLI PANCHAPAKSHI app.
///
/// This service provides:
/// - IANA timezone lookup
/// - Date-specific UTC offsets
/// - Automatic DST handling
/// - UTC/local timezone conversion
/// - DST status
///
/// The application must NOT use a fixed country UTC offset.
/// The IANA timezone database determines the applicable offset
/// for the actual timezone and selected date/time.
class TimezoneService {
  TimezoneService._();

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  static void _ensureInitialized() {
    if (!_initialized) initialize();
  }

  static tz.Location location(String ianaName) {
    _ensureInitialized();
    return tz.getLocation(ianaName);
  }

  /// Return the UTC offset applicable to a UTC instant.
  ///
  /// IMPORTANT: timezone's TimeZone.offset is expressed in milliseconds.
  /// Converting it as seconds produces values such as -5000 hours for
  /// America/Chicago instead of the correct -5 hours.
  static Duration offsetAtUtc({
    required String ianaName,
    required DateTime utc,
  }) {
    _ensureInitialized();
    final zone = tz.getLocation(ianaName);
    final period = zone.timeZone(utc.toUtc().millisecondsSinceEpoch);
    return Duration(milliseconds: period.offset);
  }

  static tz.TZDateTime fromUtc({
    required String ianaName,
    required DateTime utc,
  }) {
    _ensureInitialized();
    final zone = tz.getLocation(ianaName);
    return tz.TZDateTime.from(utc.toUtc(), zone);
  }

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
    return tz.TZDateTime(zone, year, month, day, hour, minute, second);
  }

  static String abbreviationAtUtc({
    required String ianaName,
    required DateTime utc,
  }) {
    final local = fromUtc(ianaName: ianaName, utc: utc);
    return local.timeZoneName;
  }

  static bool isDaylightSavingAtUtc({
    required String ianaName,
    required DateTime utc,
  }) {
    _ensureInitialized();
    final zone = tz.getLocation(ianaName);
    final period = zone.timeZone(utc.toUtc().millisecondsSinceEpoch);
    return period.isDst;
  }
}
