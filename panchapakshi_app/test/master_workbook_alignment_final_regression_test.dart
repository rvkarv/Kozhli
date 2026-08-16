import 'package:flutter_test/flutter_test.dart';
import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';

// Authoritative Master Workbook regression for Rajahmundry, 16-Aug-2026.
// Values are transcribed from the latest refreshed Workbook, in UTC.
void main() {
  test('Master Workbook: Rajahmundry Hasta/Pada 2 boundaries', () {
    final window = MoonNakshatraWindow.forUtc(
      DateTime.utc(2026, 8, 16, 4, 30),
    );

    final expectedStartUtc =
        DateTime.utc(2026, 8, 15, 21, 56, 12, 884000);
    final expectedEndUtc =
        DateTime.utc(2026, 8, 16, 22, 21, 4, 425000);
    final expectedPadaStartUtc =
        DateTime.utc(2026, 8, 16, 3, 58, 26, 726000);
    final expectedPadaEndUtc =
        DateTime.utc(2026, 8, 16, 10, 3, 21, 647000);

    _logTimestamp('actual.startUtc', window.startUtc);
    _logTimestamp('expected.startUtc', expectedStartUtc);
    _logTimestamp('actual.endUtc', window.endUtc);
    _logTimestamp('expected.endUtc', expectedEndUtc);
    _logTimestamp('actual.padaStartUtc', window.padaStartUtc);
    _logTimestamp('expected.padaStartUtc', expectedPadaStartUtc);
    _logTimestamp('actual.padaEndUtc', window.padaEndUtc);
    _logTimestamp('expected.padaEndUtc', expectedPadaEndUtc);

    _near(window.startUtc, expectedStartUtc);
    _near(window.endUtc, expectedEndUtc);
    _near(window.padaStartUtc, expectedPadaStartUtc);
    _near(window.padaEndUtc, expectedPadaEndUtc);
  });
}

void _logTimestamp(String label, DateTime value) {
  print(
    '$label: iso=${value.toIso8601String()} '
    'isUtc=${value.isUtc} '
    'offset=${value.timeZoneOffset} '
    'micros=${value.microsecondsSinceEpoch}',
  );
}

void _near(DateTime actual, DateTime expected) {
  final actualUtc = actual.toUtc();
  final expectedUtc = expected.toUtc();
  final deltaMicros =
      actualUtc.microsecondsSinceEpoch - expectedUtc.microsecondsSinceEpoch;
  print(
    'deltaMicros=$deltaMicros '
    'deltaSeconds=${deltaMicros / Duration.microsecondsPerSecond}',
  );
  final difference = actualUtc.difference(expectedUtc).abs();
  expect(
    difference,
    lessThanOrEqualTo(const Duration(seconds: 2)),
    reason:
        'Expected $expectedUtc ±2 seconds; got $actualUtc '
        '(difference $difference; deltaMicros=$deltaMicros)',
  );
}
