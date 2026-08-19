import 'package:flutter_test/flutter_test.dart';
import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';
import 'package:panchapakshi_app/core/nakshatra_calculator.dart';

// Authoritative Master Workbook regression for Rajahmundry, 16-Aug-2026.
// Values are transcribed from the latest refreshed Workbook, in UTC.
void main() {
  test('Master Workbook: Rajahmundry Hasta/Pada 2 boundaries', () {
    final probeUtc = DateTime.utc(2026, 8, 16, 4, 30);
    final probeMoon = NakshatraCalculator.computeCurrent(probeUtc);
    print(
      'probe: index=${probeMoon.nakshatraIndex1to27} '
      'pada=${probeMoon.pada} '
      'siderealLongitude=${probeMoon.siderealLongitude}',
    );

    final window = MoonNakshatraWindow.forUtc(probeUtc);

    final expectedStartUtc =
        DateTime.parse('2026-08-15T21:56:12.884Z');
    final expectedEndUtc =
        DateTime.parse('2026-08-16T22:21:04.425Z');
    final expectedPadaStartUtc =
        DateTime.parse('2026-08-16T03:58:26.726Z');
    final expectedPadaEndUtc =
        DateTime.parse('2026-08-16T10:03:21.647Z');

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