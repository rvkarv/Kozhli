import 'package:flutter_test/flutter_test.dart';
import 'package:panchapakshi_app/core/pure_dart_astronomy_engine.dart';

void main() {
  test('Rajahmundry Master Workbook V2 boundary and four Pada timestamps', () {
    final start = PureDartAstronomyEngine.boundaryNear(
      DateTime.utc(2026, 8, 14, 22, 13, 18, 742000),
      11,
    );
    final end = PureDartAstronomyEngine.boundaryNear(
      DateTime.utc(2026, 8, 15, 21, 56, 3, 156000),
      12,
    );
    expect(start.difference(DateTime.utc(2026, 8, 14, 22, 13, 18, 742000)).abs(), lessThanOrEqualTo(const Duration(seconds: 2)));
    expect(end.difference(DateTime.utc(2026, 8, 15, 21, 56, 3, 156000)).abs(), lessThanOrEqualTo(const Duration(seconds: 2)));

    final padas = PureDartAstronomyEngine.fourPadas(
      PureDartAstronomyEngine.julianDate(start),
      PureDartAstronomyEngine.julianDate(end),
    );
    final expected = <DateTime>[
      DateTime.utc(2026, 8, 15, 4, 5, 12, 797000),
      DateTime.utc(2026, 8, 15, 9, 59, 37, 906000),
    ];
    expect(PureDartAstronomyEngine.fromJulianDate(padas[0].endJd).difference(expected[0]).abs(), lessThanOrEqualTo(const Duration(seconds: 2)));
    expect(PureDartAstronomyEngine.fromJulianDate(padas[1].endJd).difference(expected[1]).abs(), lessThanOrEqualTo(const Duration(seconds: 2)));
  });

  test('Lafayette Master Workbook Uttara Phalguni Pada 4 boundary', () {
    final start = PureDartAstronomyEngine.boundaryNear(
      DateTime.utc(2026, 8, 14, 22, 12),
      11,
    );
    final end = PureDartAstronomyEngine.boundaryNear(
      DateTime.utc(2026, 8, 15, 21, 54),
      12,
    );
    expect(start.difference(DateTime.utc(2026, 8, 14, 22, 12)).abs(), lessThanOrEqualTo(const Duration(hours: 1)));
    expect(end.difference(DateTime.utc(2026, 8, 15, 21, 54)).abs(), lessThanOrEqualTo(const Duration(hours: 1)));
    final padas = PureDartAstronomyEngine.fourPadas(PureDartAstronomyEngine.julianDate(start), PureDartAstronomyEngine.julianDate(end));
    expect(padas, hasLength(4));
  });
}
