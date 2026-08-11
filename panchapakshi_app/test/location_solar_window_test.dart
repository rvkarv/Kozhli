import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/services/location_service.dart';
import 'package:panchapakshi_app/services/timezone_service.dart';

void main() {
  setUpAll(TimezoneService.initialize);

  test('Lafayette solar events use the event-specific DST offset', () {
    final window = LocationService.buildDayWindow(
      nowAtLocation: DateTime(2026, 11, 1, 12),
      lat: 30.2241,
      lng: -92.0198,
      timeZoneId: 'America/Chicago',
    );

    // On Nov 1, 2026 Chicago is still CDT at midday, while the following
    // sunrise is after the fall-back transition and must be CST. If one
    // offset is reused for the whole window, nextSunrise is one hour wrong.
    expect(window.nextSunrise.hour, greaterThanOrEqualTo(6));
    expect(window.nextSunrise.hour, lessThan(8));

    final currentOffset = LocationService.effectiveOffset(
      ResolvedLocation(
        label: 'Lafayette',
        lat: 30.2241,
        lng: -92.0198,
        timeZoneId: 'America/Chicago',
      ),
      localDateTime: DateTime(2026, 11, 1, 12),
    );
    expect(currentOffset.inHours, -5);

    final afterFallbackOffset = TimezoneService.offsetAtUtc(
      ianaName: 'America/Chicago',
      utc: DateTime.utc(2026, 11, 2, 12),
    );
    expect(afterFallbackOffset.inHours, -6);
  });
}
