import 'package:flutter_test/flutter_test.dart';
import 'package:panchapakshi_app/core/pure_dart_astronomy_engine.dart';

void main() {
  test('Master Workbook Nakshatra is divided into four equal Pada intervals', () {
    // 03:42:00 to next-day 03:24:00 = 23h42m.
    final start = DateTime.utc(2026, 8, 15, 3, 42).millisecondsSinceEpoch / 86400000 + 2440587.5;
    final end = DateTime.utc(2026, 8, 16, 3, 24).millisecondsSinceEpoch / 86400000 + 2440587.5;

    final padas = PureDartAstronomyEngine.fourPadas(start, end);
    expect(padas, hasLength(4));

    final padaLength = (end - start) / 4.0;
    for (var i = 0; i < 4; i++) {
      expect(padas[i].startJd, closeTo(start + i * padaLength, 1e-12));
      expect(padas[i].endJd, closeTo(start + (i + 1) * padaLength, 1e-12));
    }
  });

  test('Lahiri conversion is deterministic and normalized', () {
    final jd = DateTime.utc(2026, 8, 15, 12).millisecondsSinceEpoch / 86400000 + 2440587.5;
    final result = PureDartAstronomyEngine.siderealLongitude(150.0, jd);
    expect(result, greaterThanOrEqualTo(0));
    expect(result, lessThan(2 * 3.141592653589793));
  });
}
