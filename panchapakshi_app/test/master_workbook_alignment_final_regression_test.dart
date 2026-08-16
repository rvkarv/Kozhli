import 'package:flutter_test/flutter_test.dart';
import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';

// Final authoritative Master Workbook boundary regression.
void main() {
  test('Master Workbook: Rajahmundry 15-Aug-2026 four Moon boundaries', () {
    final window = MoonNakshatraWindow.forUtc(
      DateTime.utc(2026, 8, 15, 6, 46),
    );

    _near(window.startUtc, DateTime.utc(2026, 8, 14, 22, 13, 18, 742000));
    _near(window.endUtc, DateTime.utc(2026, 8, 15, 21, 56, 3, 156000));
    _near(window.padaStartUtc, DateTime.utc(2026, 8, 15, 4, 5, 12, 797000));
    _near(window.padaEndUtc, DateTime.utc(2026, 8, 15, 9, 59, 37, 906000));
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
