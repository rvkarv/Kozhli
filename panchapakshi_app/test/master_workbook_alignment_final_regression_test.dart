import 'package:flutter_test/flutter_test.dart';
import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';

// Authoritative Master Workbook regression for Rajahmundry, 16-Aug-2026.
// Values are transcribed from the latest refreshed Workbook, in UTC.
// Keep the expected instants as explicit constants so CI cannot accidentally
// substitute an older generated workbook value.
void main() {
  test('Master Workbook: Rajahmundry Hasta/Pada 2 boundaries', () {
    final window = MoonNakshatraWindow.forUtc(
      DateTime.utc(2026, 8, 16, 4, 30),
    );

    const expectedStartUtc = DateTime.utc(2026, 8, 15, 21, 56, 12, 884000);
    const expectedEndUtc = DateTime.utc(2026, 8, 16, 22, 21, 4, 425000);
    const expectedPadaStartUtc = DateTime.utc(2026, 8, 16, 3, 58, 26, 726000);
    const expectedPadaEndUtc = DateTime.utc(2026, 8, 16, 10, 3, 21, 647000);

    _near(window.startUtc, expectedStartUtc);
    _near(window.endUtc, expectedEndUtc);
    _near(window.padaStartUtc, expectedPadaStartUtc);
    _near(window.padaEndUtc, expectedPadaEndUtc);
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
