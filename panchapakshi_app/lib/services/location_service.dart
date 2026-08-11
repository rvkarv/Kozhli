import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tz_mapper;
import 'package:timezone/timezone.dart' as tz;

import '../core/sun_calculator.dart';
import 'timezone_service.dart';

class ResolvedLocation {
  final String label;
  final double lat;
  final double lng;
  final bool isDeviceLocal;
  final String? timeZoneId;

  const ResolvedLocation({
    required this.label,
    required this.lat,
    required this.lng,
    this.isDeviceLocal = false,
    this.timeZoneId,
  });
}

class DayWindow {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime nextSunrise;
  final DateTime previousSunset;

  const DayWindow({
    required this.sunrise,
    required this.sunset,
    required this.nextSunrise,
    required this.previousSunset,
  });
}

class LocationService {
  static const _prefsKey = 'panchapakshi_last_location';
  static bool _timezoneMapperInitialized = false;

  static void _ensureTimezoneMapperInitialized() {
    if (_timezoneMapperInitialized) return;
    tz_mapper.initPolyArray();
    _timezoneMapperInitialized = true;
  }

  static String? timezoneIdForCoordinates({
    required double lat,
    required double lng,
  }) {
    try {
      _ensureTimezoneMapperInitialized();
      final result = tz_mapper.latLngToTimezoneString(lat, lng).trim();
      if (result.isEmpty ||
          result.toLowerCase() == 'unknown' ||
          result.toLowerCase() == 'uninhabited') {
        return null;
      }
      TimezoneService.location(result);
      return result;
    } catch (_) {
      return null;
    }
  }

  static String? timezoneIdForLocation(ResolvedLocation loc) {
    final stored = loc.timeZoneId?.trim();
    if (stored != null && stored.isNotEmpty) {
      try {
        TimezoneService.location(stored);
        return stored;
      } catch (_) {}
    }
    return timezoneIdForCoordinates(lat: loc.lat, lng: loc.lng);
  }

  static Future<ResolvedLocation> getGpsLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String label = 'Current location';
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        label = [p.locality, p.administrativeArea, p.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
      }
    } catch (_) {
      label = '${pos.latitude.toStringAsFixed(3)}, '
          '${pos.longitude.toStringAsFixed(3)}';
    }

    final timeZoneId = timezoneIdForCoordinates(
      lat: pos.latitude,
      lng: pos.longitude,
    );

    final loc = ResolvedLocation(
      label: label,
      lat: pos.latitude,
      lng: pos.longitude,
      isDeviceLocal: true,
      timeZoneId: timeZoneId,
    );
    await _cache(loc);
    return loc;
  }

  static Future<List<ResolvedLocation>> searchPlace(String query) async {
    final locations = await locationFromAddress(query);
    final results = <ResolvedLocation>[];

    for (final loc in locations.take(5)) {
      String label = query;
      try {
        final placemarks = await placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          label = [
            p.locality,
            p.subAdministrativeArea,
            p.administrativeArea,
            p.country,
          ].where((s) => s != null && s.isNotEmpty).toSet().join(', ');
        }
      } catch (_) {}

      final timeZoneId = timezoneIdForCoordinates(
        lat: loc.latitude,
        lng: loc.longitude,
      );
      results.add(
        ResolvedLocation(
          label: label,
          lat: loc.latitude,
          lng: loc.longitude,
          isDeviceLocal: false,
          timeZoneId: timeZoneId,
        ),
      );
    }
    return results;
  }

  static Future<void> _cache(ResolvedLocation loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _encode(loc));
  }

  static Future<ResolvedLocation?> lastKnown() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return null;
    return _decode(raw);
  }

  static String _encode(ResolvedLocation l) => [
        l.label,
        l.lat.toString(),
        l.lng.toString(),
        l.isDeviceLocal.toString(),
        l.timeZoneId ?? '',
      ].join('|');

  static ResolvedLocation? _decode(String raw) {
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    final lat = double.tryParse(parts[1]);
    final lng = double.tryParse(parts[2]);
    if (lat == null || lng == null) return null;

    String? timeZoneId;
    if (parts.length > 4 && parts[4].trim().isNotEmpty) {
      timeZoneId = parts[4].trim();
    } else {
      timeZoneId = timezoneIdForCoordinates(lat: lat, lng: lng);
    }

    return ResolvedLocation(
      label: parts[0],
      lat: lat,
      lng: lng,
      isDeviceLocal: parts.length > 3 && parts[3] == 'true',
      timeZoneId: timeZoneId,
    );
  }

  /// Resolve the UTC offset for the selected place at a specific date/time.
  /// IANA rules, including DST and historical changes, are always preferred.
  static Duration effectiveOffset(
    ResolvedLocation loc, {
    DateTime? localDateTime,
    DateTime? utcNow,
  }) {
    final timeZoneId = timezoneIdForLocation(loc);
    if (timeZoneId != null) {
      try {
        if (localDateTime != null) {
          final localZoneDateTime = tz.TZDateTime(
            TimezoneService.location(timeZoneId),
            localDateTime.year,
            localDateTime.month,
            localDateTime.day,
            localDateTime.hour,
            localDateTime.minute,
            localDateTime.second,
          );
          return Duration(seconds: localZoneDateTime.timeZoneOffset.inSeconds);
        }

        final instant = (utcNow ?? DateTime.now().toUtc()).toUtc();
        return TimezoneService.offsetAtUtc(
          ianaName: timeZoneId,
          utc: instant,
        );
      } catch (_) {}
    }

    if (loc.isDeviceLocal) return DateTime.now().timeZoneOffset;
    return Duration.zero;
  }

  static tz.TZDateTime currentLocalDateTime(
    ResolvedLocation loc, {
    DateTime? utcNow,
  }) {
    final timeZoneId = timezoneIdForLocation(loc);
    if (timeZoneId == null) {
      throw StateError('Unable to resolve an IANA timezone for ${loc.label}');
    }
    return TimezoneService.fromUtc(
      ianaName: timeZoneId,
      utc: (utcNow ?? DateTime.now().toUtc()).toUtc(),
    );
  }

  /// Legacy compatibility helper. New calculations must provide a location
  /// and date to effectiveOffset(), because longitude alone cannot represent
  /// political timezone boundaries or historical DST.
  static Duration locationOffset(double lng) {
    final timezoneId = timezoneIdForCoordinates(lat: 0, lng: lng);
    if (timezoneId != null) {
      try {
        return TimezoneService.offsetAtUtc(
          ianaName: timezoneId,
          utc: DateTime.now().toUtc(),
        );
      } catch (_) {}
    }
    return Duration(hours: (lng / 15).round());
  }

  /// Build sunrise/sunset as selected-location wall-clock DateTimes.
  ///
  /// Each solar event is converted with the IANA offset applicable to that
  /// event's actual UTC instant. We deliberately do NOT reuse today's offset
  /// for tomorrow's sunrise or yesterday's sunset, because a DST transition
  /// can occur between those events.
  static DayWindow buildDayWindow({
    required DateTime nowAtLocation,
    required double lat,
    required double lng,
    Duration? offsetOverride,
    String? timeZoneId,
  }) {
    final location = ResolvedLocation(
      label: '',
      lat: lat,
      lng: lng,
      timeZoneId: timeZoneId,
    );
    final resolvedTimeZone = timezoneIdForLocation(location);

    final today = SunCalculator.calculate(
      date: nowAtLocation,
      lat: lat,
      lng: lng,
    );
    final yesterday = SunCalculator.calculate(
      date: nowAtLocation.subtract(const Duration(days: 1)),
      lat: lat,
      lng: lng,
    );
    final tomorrow = SunCalculator.calculate(
      date: nowAtLocation.add(const Duration(days: 1)),
      lat: lat,
      lng: lng,
    );

    DateTime localEvent(DateTime? utc, DateTime fallbackUtc) {
      final instant = (utc ?? fallbackUtc).toUtc();

      Duration eventOffset;
      if (resolvedTimeZone != null) {
        eventOffset = TimezoneService.offsetAtUtc(
          ianaName: resolvedTimeZone,
          utc: instant,
        );
      } else {
        // Only use the explicitly supplied offset when no IANA timezone can
        // be resolved. The normal app path always resolves an IANA zone.
        eventOffset = offsetOverride ?? Duration.zero;
      }

      final local = instant.add(eventOffset);
      return DateTime(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
        local.second,
        local.millisecond,
        local.microsecond,
      );
    }

    return DayWindow(
      sunrise: localEvent(
        today.sunrise,
        DateTime.utc(nowAtLocation.year, nowAtLocation.month, nowAtLocation.day, 6),
      ),
      sunset: localEvent(
        today.sunset,
        DateTime.utc(nowAtLocation.year, nowAtLocation.month, nowAtLocation.day, 18),
      ),
      nextSunrise: localEvent(
        tomorrow.sunrise,
        DateTime.utc(nowAtLocation.year, nowAtLocation.month, nowAtLocation.day + 1, 6),
      ),
      previousSunset: localEvent(
        yesterday.sunset,
        DateTime.utc(nowAtLocation.year, nowAtLocation.month, nowAtLocation.day - 1, 18),
      ),
    );
  }
}
