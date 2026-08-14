import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/sun_calculator.dart';
import 'package:panchapakshi_app/services/timezone_service.dart';

void main() {
  setUpAll(TimezoneService.initialize);

  DateTime wallClock(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  DateTime localFromUtc(DateTime utc, String zone) {
    return wallClock(
      TimezoneService.fromUtc(ianaName: zone, utc: utc),
    );
  }

  test('Rajahmundry sunrise and sunset use the selected local date', () {
    final sun = SunCalculator.calculate(
      date: DateTime(2026, 8, 12),
      lat: 16.9891,
      lng: 81.7810,
    );

    expect(sun.sunrise, isNotNull);
    expect(sun.sunset, isNotNull);

    final sunrise = localFromUtc(sun.sunrise!, 'Asia/Kolkata');
    final sunset = localFromUtc(sun.sunset!, 'Asia/Kolkata');

    expect(
      DateTime(sunrise.year, sunrise.month, sunrise.day),
      DateTime(2026, 8, 12),
    );
    expect(sunrise.hour, 5);
    expect(sunrise.minute, inInclusiveRange(43, 47));
    expect(sunset.hour, 18);
    expect(sunset.minute, inInclusiveRange(28, 33));
  });

  test('Lafayette sunrise and sunset use CDT for the 2026 date', () {
    final sun = SunCalculator.calculate(
      date: DateTime(2026, 8, 12),
      lat: 30.2241,
      lng: -92.0198,
    );

    expect(sun.sunrise, isNotNull);
    expect(sun.sunset, isNotNull);

    final sunrise = localFromUtc(sun.sunrise!, 'America/Chicago');
    final sunset = localFromUtc(sun.sunset!, 'America/Chicago');

    // NOAA-style calculation used by the app gives approximately
    // 06:33 CDT / 19:50 CDT for Lafayette on 12-Aug-2026.
    expect(
      DateTime(sunrise.year, sunrise.month, sunrise.day),
      DateTime(2026, 8, 12),
    );
    expect(sunrise.hour, 6);
    expect(sunrise.minute, inInclusiveRange(31, 35));
    expect(sunset.hour, 19);
    expect(sunset.minute, inInclusiveRange(47, 53));
  });
}
