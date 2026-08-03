import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sun_calculator.dart';

class ResolvedLocation {
  final String label;
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
      label = '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}';
    }

    final loc = ResolvedLocation(label: label, lat: pos.latitude, lng: pos.longitude);
    await _cache(loc);
    return loc;
  }

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
              .toSet()
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

  static String _encode(ResolvedLocation l) => '${l.label}|${l.lat}|${l.lng}';
  static ResolvedLocation? _decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    return ResolvedLocation(
      label: parts[0],
      lat: double.tryParse(parts[1]) ?? 0,
      lng: double.tryParse(parts[2]) ?? 0,
    );
  }

  /// Approximate local UTC offset for a place based on its longitude
  /// (15 degrees = 1 hour), rounded to the nearest whole hour.
  static Duration locationOffset(double lng) {
    final hours = (lng / 15).round();
    return Duration(hours: hours);
  }

  /// [nowAtLocation] must already be shifted into the target location's
  /// approximate local time (see AppState._recompute) so the correct
  /// CALENDAR DAY is used for sunrise/sunset lookup.
  static DayWindow buildDayWindow({
    required DateTime nowAtLocation,
    required double lat,
    required double lng,
  }) {
    final offset = locationOffset(lng);
    final today = SunCalculator.calculate(date: nowAtLocation, lat: lat, lng: lng);
    final yesterday = SunCalculator.calculate(
        date: nowAtLocation.subtract(const Duration(days: 1)), lat: lat, lng: lng);
    final tomorrow = SunCalculator.calculate(
        date: nowAtLocation.add(const Duration(days: 1)), lat: lat, lng: lng);

    DateTime shift(DateTime? utc, DateTime fallbackUtc) => (utc ?? fallbackUtc).add(offset);

    return DayWindow(
      sunrise: shift(today.sunrise,
          DateTime.utc(nowAtLocation.year, nowAtLocation.month, nowAtLocation.day, 6)),
      sunset: shift(today.sunset,
          DateTime.utc(nowAtLocation.year, nowAtLocation.month, nowAtLocation.day, 18)),
      nextSunrise: shift(tomorrow.sunrise,
          DateTime.utc(nowAtLocation.year, nowAtLocation.month, nowAtLocation.day + 1, 6)),
      previousSunset: shift(yesterday.sunset,
          DateTime.utc(nowAtLocation.year, nowAtLocation.month, nowAtLocation.day - 1, 18)),
    );
  }
}
