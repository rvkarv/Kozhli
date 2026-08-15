import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';

void main() {
  test('Rajahmundry 15-Aug-2026 Moon window matches Master Workbook', () {
    // Master Workbook reference (local IST):
    // Nakshatra: Uttara Phalguni, Pada 2
    // Nakshatra: 03:43:18.742 -> next day 03:26:03.156 IST
    // Pada 2:       09:35:12.797 -> 15:29:37.906 IST
    // The astronomical engine uses the same sidereal calculation, but its
    // numerical boundary can differ from the workbook by a small sub-2-second
    // floating-point/ephemeris rounding amount. Do not alter the calculation
    // logic to force an exact millisecond match to Excel.
    final window = MoonNakshatraWindow.forUtc(
      DateTime.utc(2026, 8, 15, 6, 46),
    );

    _expectNear(window.startUtc, DateTime.utc(2026, 8, 14, 22, 13, 18, 742000));
    _expectNear(window.endUtc, DateTime.utc(2026, 8, 15, 21, 56, 3, 156000));
    _expectNear(window.padaStartUtc, DateTime.utc(2026, 8, 15, 4, 5, 12, 797000));
    _expectNear(window.padaEndUtc, DateTime.utc(2026, 8, 15, 9, 59, 37, 906000));
  });
}

void _expectNear(DateTime actual, DateTime expected) {
  final difference = (actual.difference(expected)).abs();
  expect(
    difference,
    lessThanOrEqualTo(const Duration(seconds: 2)),
    reason: 'Expected $expected ±2 seconds, got $actual',
  );
}
