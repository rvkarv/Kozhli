import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';
import 'package:panchapakshi_app/core/nakshatra_calculator.dart';
import 'package:panchapakshi_app/services/timezone_service.dart';

void main() {
  setUpAll(TimezoneService.initialize);

  test('Rajahmundry Aug 14 2026 1:42 PM is Puram Pada 2', () {
    final utc = DateTime.utc(2026, 8, 14, 8, 12);
    final moon = NakshatraCalculator.computeCurrent(utc);

    expect(moon.nakshatraName, 'பூரம்');
    expect(moon.pada, 2);
    expect(moon.rasiName, 'சிம்மம்');

    final window = MoonNakshatraWindow.forUtc(utc);
    final startLocal = TimezoneService.fromUtc(
      ianaName: 'Asia/Kolkata',
      utc: window.startUtc,
    );
    final endLocal = TimezoneService.fromUtc(
      ianaName: 'Asia/Kolkata',
      utc: window.endUtc,
    );

    // Magha ended at approximately 04:38 IST on Aug 14. The current
    // Puram window therefore starts around 04:38 IST and continues into
    // Aug 15. This is the location-independent astronomical event rendered
    // through the selected location's timezone.
    expect(startLocal.year, 2026);
    expect(startLocal.month, 8);
    expect(startLocal.day, 14);
    expect(startLocal.hour, 4);
    expect(startLocal.minute, inInclusiveRange(35, 41));

    expect(endLocal.isAfter(startLocal), isTrue);
  });

  test('the same UTC Moon state renders correctly in Lafayette CDT', () {
    final utc = DateTime.utc(2026, 8, 14, 8, 12);
    final moon = NakshatraCalculator.computeCurrent(utc);

    expect(moon.nakshatraName, 'பூரம்');
    expect(moon.pada, 2);

    final local = TimezoneService.fromUtc(
      ianaName: 'America/Chicago',
      utc: utc,
    );
    expect(local.year, 2026);
    expect(local.month, 8);
    expect(local.day, 14);
    expect(local.hour, 3);
    expect(local.minute, 12);
  });
}
