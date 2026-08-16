import 'package:flutter_test/flutter_test.dart';
import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';

// Authoritative Master Workbook regression for Rajahmundry, 16-Aug-2026.
// Values are transcribed from the latest refreshed Workbook, in UTC.
void main() {
  test('Master Workbook: Rajahmundry Hasta/Pada 2 boundaries', () {
    // 10:00 IST = 04:30 UTC, safely inside Hasta Pada 2.
    final window = MoonNakshatraWindow.forUtc(
      DateTime.utc(2026, 8, 16, 4, 30),
    );

    _near(window.startUtc, DateTime.utc(2026, 8, 15, 21, 56, 12, 884000));
    _near(window.endUtc, DateTime.utc(2026, 8, 16, 22, 21, 4, 425000));
    _near(window.padaStartUtc, DateTime.utc(2026, 8, 16, 3, 58, 26, 726000));
    _near(window.padaEndUtc, DateTime.utc(2026, 8, 16, 10, 3, 21, 647000));
  });
}

void _near(DateTime actual, DateTime expected) {
  final difference = actual.difference(expected).abs();
  expect(
    difference,
    lessThanOrEqualTo(const Duration(seconds: 2)),
    reason: 'Expected $expected ±2 seconds; got $actual (difference $difference)',
  );
}
