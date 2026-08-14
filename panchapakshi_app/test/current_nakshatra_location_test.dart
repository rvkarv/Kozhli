import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';
import 'package:panchapakshi_app/core/nakshatra_calculator.dart';
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

  test('Rajahmundry and Lafayette represent the same Moon state', () {
    final utc = DateTime.utc(2026, 8, 12, 3, 11);
    final moon = NakshatraCalculator.computeCurrent(utc);

    expect(moon.nakshatraName, 'ஆயில்யம்');
    expect(moon.pada, 1);

    final rajahmundry = localFromUtc(utc, 'Asia/Kolkata');
    final lafayette = localFromUtc(utc, 'America/Chicago');

    expect(rajahmundry.year, 2026);
    expect(rajahmundry.month, 8);
    expect(rajahmundry.day, 12);
    expect(rajahmundry.hour, 8);
    expect(rajahmundry.minute, 41);

    expect(lafayette.year, 2026);
    expect(lafayette.month, 8);
    expect(lafayette.day, 11);
    expect(lafayette.hour, 22);
    expect(lafayette.minute, 11);
  });

  test('current Nakshatra and Pada boundaries are real UTC events', () {
    final utc = DateTime.utc(2026, 8, 12, 3, 11);
    final window = MoonNakshatraWindow.forUtc(utc);

    expect(window.startUtc.isUtc, isTrue);
    expect(window.endUtc.isUtc, isTrue);
    expect(window.padaStartUtc.isUtc, isTrue);
    expect(window.padaEndUtc.isUtc, isTrue);

    expect(window.startUtc.isBefore(utc), isTrue);
    expect(window.padaStartUtc.isBefore(utc), isTrue);
    expect(window.padaEndUtc.isAfter(utc), isTrue);
    expect(window.endUtc.isAfter(utc), isTrue);

    // Compare timezone-aware values as selected-location wall-clock fields.
    // Directly subtracting TZDateTime from a timezone-free DateTime applies
    // the device timezone and can create a false 330-minute error.
    final startLocal = localFromUtc(window.startUtc, 'Asia/Kolkata');
    final endLocal = localFromUtc(window.endUtc, 'Asia/Kolkata');

    final expectedStart = DateTime(2026, 8, 12, 7, 59);
    final expectedEnd = DateTime(2026, 8, 13, 6, 6);

    expect(
      startLocal.difference(expectedStart).inMinutes.abs(),
      lessThanOrEqualTo(2),
    );
    expect(
      endLocal.difference(expectedEnd).inMinutes.abs(),
      lessThanOrEqualTo(2),
    );

    final lafStart = localFromUtc(window.startUtc, 'America/Chicago');
    final lafEnd = localFromUtc(window.endUtc, 'America/Chicago');

    expect(lafStart.year, 2026);
    expect(lafStart.month, 8);
    expect(lafStart.day, 11);
    expect(lafEnd.year, 2026);
    expect(lafEnd.month, 8);
    expect(lafEnd.day, 12);
  });
}
