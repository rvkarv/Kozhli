import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/services/location_service.dart';
import 'package:panchapakshi_app/services/timezone_service.dart';

void main() {
  setUpAll(TimezoneService.initialize);

  test('Lafayette solar events use the event-specific DST offset', () {
    const location = ResolvedLocation(
      label: 'Lafayette',
      lat: 30.2241,
      lng: -92.0198,
      timeZoneId: 'America/Chicago',
    );

    // October 31 is still CDT (UTC-5).
    final beforeFallback = LocationService.effectiveOffset(
      location,
      localDateTime: DateTime(2026, 10, 31, 12),
    );

    expect(beforeFallback.inHours, -5);

    // November 1, 2026 contains the US fall-back transition.
    // At noon on November 1 the offset is already CST (UTC-6).
    final window = LocationService.buildDayWindow(
      nowAtLocation: DateTime(2026, 11, 1, 12),
      lat: location.lat,
      lng: location.lng,
      timeZoneId: location.timeZoneId,
    );

    expect(window.nextSunrise.hour, greaterThanOrEqualTo(6));
    expect(window.nextSunrise.hour, lessThan(8));

    // November 2 is definitely after the DST transition.
    final afterFallbackOffset = TimezoneService.offsetAtUtc(
      ianaName: 'America/Chicago',
      utc: DateTime.utc(2026, 11, 2, 12),
    );

    expect(afterFallbackOffset.inHours, -6);

    // Most importantly, verify the sunrise itself uses the offset
    // belonging to that actual UTC event.
    final eventOffset = TimezoneService.offsetAtUtc(
      ianaName: location.timeZoneId,
      utc: window.nextSunrise.toUtc(),
    );

    expect(eventOffset.inHours, -6);
  });
}
