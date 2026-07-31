import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sun_calculator.dart';

class ResolvedLocation {
  final String label; // "Village, District, Country" etc.
  final double lat;
  final double lng;
  const ResolvedLocation({required this.label, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'label': label, 'lat': lat, 'lng': lng};
  factory ResolvedLocation.fromJson(Map<String, dynamic> j) => ResolvedLocation(
        label: j['label'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
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

  /// GPS: current device location. Throws if permission denied.
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
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        label = [p.locality, p.administrativeArea, p.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
      }
    } catch (_) {
      // Reverse geocoding is best-effort; fall back to raw lat/lng label.
      label = '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}';
    }

    final loc = ResolvedLocation(label: label, lat: pos.latitude, lng: pos.longitude);
    await _cache(loc);
    return loc;
  }

  /// Manual search: Village / Town / City / District / Country free text.
  /// Uses platform geocoding (falls back cleanly if the plugin's native
  /// backend needs a Google Maps API key configured per-platform — see
  /// README "Google Maps API key setup").
  static Future<List<ResolvedLocation>> searchPlace(String query) async {
    final locations = await locationFromAddress(query);
    final results = <ResolvedLocation>[];
    for (final loc in locations.take(5)) {
      String label = query;
      try {
        final placemarks =
            await placemarkFromCoordinates(loc.latitude, loc.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          label = [p.locality, p.subAdministrativeArea, p.administrativeArea, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .toSet() // drop dup segments
              .join(', ');
        }
      } catch (_) {}
      results.add(ResolvedLocation(label: label, lat: loc.latitude, lng: loc.longitude));
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

  static String _encode(ResolvedLocation l) =>
      '${l.label}|${l.lat}|${l.lng}';
  static ResolvedLocation? _decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    return ResolvedLocation(
      label: parts[0],
      lat: double.tryParse(parts[1]) ?? 0,
      lng: double.tryParse(parts[2]) ?? 0,
    );
  }

  /// Builds the sunrise/sunset/nextSunrise/previousSunset window needed
  /// by [PanchapakshiEngine.compute] for [date] at [lat]/[lng].
  ///
  /// NOTE ON TIME ZONES: SunCalculator returns UTC instants. This method
  /// converts them to the DEVICE's local time zone via .toLocal(). That
  /// is correct as long as the device's system time zone matches the
  /// selected place (true for GPS mode). For manual search of a place in
  /// a *different* time zone than the device, plug in a timezone lookup
  /// (e.g. the `timezone` + `flutter_timezone` packages keyed off
  /// lat/lng) before calling .toLocal() — flagged here so it isn't missed.
  static DayWindow buildDayWindow({
    required DateTime date,
    required double lat,
    required double lng,
  }) {
    final today = SunCalculator.calculate(date: date, lat: lat, lng: lng);
    final yesterday = SunCalculator.calculate(
        date: date.subtract(const Duration(days: 1)), lat: lat, lng: lng);
    final tomorrow = SunCalculator.calculate(
        date: date.add(const Duration(days: 1)), lat: lat, lng: lng);

    return DayWindow(
      sunrise: (today.sunrise ?? DateTime.utc(date.year, date.month, date.day, 6)).toLocal(),
      sunset: (today.sunset ?? DateTime.utc(date.year, date.month, date.day, 18)).toLocal(),
      nextSunrise: (tomorrow.sunrise ??
              DateTime.utc(date.year, date.month, date.day + 1, 6))
          .toLocal(),
      previousSunset: (yesterday.sunset ??
              DateTime.utc(date.year, date.month, date.day - 1, 18))
          .toLocal(),
    );
  }
}
