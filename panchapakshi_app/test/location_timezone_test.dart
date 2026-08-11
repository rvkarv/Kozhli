import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/services/location_service.dart';
import 'package:panchapakshi_app/services/timezone_service.dart';

void main() {
  setUpAll(() {
    TimezoneService.initialize();
  });

  group('Worldwide IANA timezone identification', () {
    test('Chicago, Illinois resolves to America/Chicago', () {
      final zone = LocationService.timezoneIdForCoordinates(
        lat: 41.8781,
        lng: -87.6298,
      );

      expect(zone, 'America/Chicago');
    });

    test('Lafayette, Louisiana resolves to America/Chicago', () {
      final zone = LocationService.timezoneIdForCoordinates(
        lat: 30.2241,
        lng: -92.0198,
      );

      expect(zone, 'America/Chicago');
    });

    test('Lafayette, Indiana resolves to an Indiana IANA timezone', () {
      final zone = LocationService.timezoneIdForCoordinates(
        lat: 40.4167,
        lng: -86.8753,
      );

      expect(zone, isNotNull);

      expect(
        <String>[
          'America/Indiana/Indianapolis',
          'America/Indiana/Knox',
          'America/Indiana/Winamac',
        ],
        contains(zone),
      );
    });

    test('Chennai, India resolves to Asia/Kolkata', () {
      final zone = LocationService.timezoneIdForCoordinates(
        lat: 13.0827,
        lng: 80.2707,
      );

      expect(zone, 'Asia/Kolkata');
    });

    test('New York resolves to America/New_York', () {
      final zone = LocationService.timezoneIdForCoordinates(
        lat: 40.7128,
        lng: -74.0060,
      );

      expect(zone, 'America/New_York');
    });

    test('London resolves to Europe/London', () {
      final zone = LocationService.timezoneIdForCoordinates(
        lat: 51.5074,
        lng: -0.1278,
      );

      expect(zone, 'Europe/London');
    });

    test('Sydney resolves to Australia/Sydney', () {
      final zone = LocationService.timezoneIdForCoordinates(
        lat: -33.8688,
        lng: 151.2093,
      );

      expect(zone, 'Australia/Sydney');
    });
  });

  group('Date-specific timezone offset', () {
    test('Lafayette uses standard time in January', () {
      final location = ResolvedLocation(
        label: 'Lafayette, Louisiana, USA',
        lat: 30.2241,
        lng: -92.0198,
        timeZoneId: 'America/Chicago',
      );

      final offset = LocationService.effectiveOffset(
        location,
        localDateTime: DateTime(2026, 1, 15, 12),
      );

      expect(offset.inHours, -6);
    });

    test('Lafayette uses daylight time on August 11, 2026', () {
      final location = ResolvedLocation(
        label: 'Lafayette, Louisiana, USA',
        lat: 30.2241,
        lng: -92.0198,
        timeZoneId: 'America/Chicago',
      );

      final offset = LocationService.effectiveOffset(
        location,
        localDateTime: DateTime(2026, 8, 11, 12),
      );

      expect(offset.inHours, -5);
    });

    test('Lafayette live UTC instant resolves to the correct local offset', () {
      final location = ResolvedLocation(
        label: 'Lafayette, Louisiana, USA',
        lat: 30.2241,
        lng: -92.0198,
        timeZoneId: 'America/Chicago',
      );

      final offset = LocationService.effectiveOffset(
        location,
        utcNow: DateTime.utc(2026, 8, 11, 12),
      );

      expect(offset.inHours, -5);
    });

    test('Lafayette local date/time comes from the selected timezone, not device timezone', () {
      final location = ResolvedLocation(
        label: 'Lafayette, Louisiana, USA',
        lat: 30.2241,
        lng: -92.0198,
        timeZoneId: 'America/Chicago',
      );

      final local = LocationService.currentLocalDateTime(
        location,
        utcNow: DateTime.utc(2026, 8, 11, 09, 0),
      );

      expect(local.year, 2026);
      expect(local.month, 8);
      expect(local.day, 11);
      expect(local.hour, 4);
      expect(local.minute, 0);
      expect(local.timeZoneOffset.inHours, -5);
    });

    test('Chicago uses standard time in January', () {
      final location = ResolvedLocation(
        label: 'Chicago, USA',
        lat: 41.8781,
        lng: -87.6298,
        timeZoneId: 'America/Chicago',
      );

      final offset = LocationService.effectiveOffset(
        location,
        localDateTime: DateTime(2026, 1, 15, 12),
      );

      expect(offset.inHours, -6);
    });

    test('Chicago uses daylight time in July', () {
      final location = ResolvedLocation(
        label: 'Chicago, USA',
        lat: 41.8781,
        lng: -87.6298,
        timeZoneId: 'America/Chicago',
      );

      final offset = LocationService.effectiveOffset(
        location,
        localDateTime: DateTime(2026, 7, 15, 12),
      );

      expect(offset.inHours, -5);
    });

    test('India remains UTC+5:30 in January', () {
      final location = ResolvedLocation(
        label: 'Chennai, India',
        lat: 13.0827,
        lng: 80.2707,
        timeZoneId: 'Asia/Kolkata',
      );

      final offset = LocationService.effectiveOffset(
        location,
        localDateTime: DateTime(2026, 1, 15, 12),
      );

      expect(offset.inMinutes, 330);
    });

    test('India remains UTC+5:30 in July', () {
      final location = ResolvedLocation(
        label: 'Chennai, India',
        lat: 13.0827,
        lng: 80.2707,
        timeZoneId: 'Asia/Kolkata',
      );

      final offset = LocationService.effectiveOffset(
        location,
        localDateTime: DateTime(2026, 7, 15, 12),
      );

      expect(offset.inMinutes, 330);
    });
  });
}
