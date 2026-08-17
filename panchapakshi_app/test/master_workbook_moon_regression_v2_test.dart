import 'package:flutter_test/flutter_test.dart';
import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';

void main() {
  test('Master Workbook V2: Rajahmundry 15-Aug-2026 Uttara Phalguni Pada 2', () {
    final window = MoonNakshatraWindow.forUtc(
      DateTime.utc(2026, 8, 15, 6, 46),
    );

    final expectedStart = DateTime.utc(2026, 8, 14, 22, 13, 18, 742000);
    final expectedEnd = DateTime.utc(2026, 8, 15, 21, 56, 3, 156000);
    final expectedPadaStart = DateTime.utc(2026, 8, 15, 4, 5, 12, 797000);
    final expectedPadaEnd = DateTime.utc(2026, 8, 15, 9, 59, 37, 906000);

    _log('start', window.startUtc, expectedStart);
    _log('end', window.endUtc, expectedEnd);
    _log('padaStart', window.padaStartUtc, expectedPadaStart);
    _log('padaEnd', window.padaEndUtc, expectedPadaEnd);

    _near(window.startUtc, expectedStart);
    _near(window.endUtc, expectedEnd);
    _near(window.padaStartUtc, expectedPadaStart);
    _near(window.padaEndUtc, expectedPadaEnd);
  });
}

void _log(String label, DateTime actual, DateTime expected) {
  final deltaMicros = actual.toUtc().microsecondsSinceEpoch -
      expected.toUtc().microsecondsSinceEpoch;
  print('$label actual=${actual.toIso8601String()} expected=${expected.toIso8601String()} deltaSeconds=${deltaMicros / Duration.microsecondsPerSecond}');
}

void _near(DateTime actual, DateTime expected) {
  final difference = actual.difference(expected).abs();
  expect(
    difference,
    lessThanOrEqualTo(const Duration(seconds: 2)),
    reason: 'Master Workbook expected $expected ±2 seconds; got $actual (difference $difference)',
  );
}
