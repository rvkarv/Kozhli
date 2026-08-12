import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';
import 'package:panchapakshi_app/core/nakshatra_calculator.dart';
import 'package:panchapakshi_app/services/timezone_service.dart';

void main() {
  setUpAll(TimezoneService.initialize);

  DateTime localFromUtc(DateTime utc, String zone) {
    return TimezoneService.fromUtc(ianaName: zone, utc: utc);
  }

  test('Rajahmundry and Lafayette represent the same Moon state', () {
    // 2026-08-12 08:41 IST == 2026-08-11 22:11 CDT.
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

    // Drik/Panchanga reference supplied for this validation case:
    // Rajahmundry Ayilyam 1 starts ~07:59 IST and ends ~06:06 IST next day.
    // The local conversion should therefore land within two minutes of the
    // reference even though the astronomical implementation is independent
    // of the display timezone.
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

    // The same UTC boundaries must appear 10h30 earlier in Lafayette.
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
