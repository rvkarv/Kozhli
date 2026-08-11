import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/sun_calculator.dart';

void main() {
  test('Lafayette Aug 11 sunset keeps the correct UTC calendar date', () {
    final result = SunCalculator.calculate(
      date: DateTime(2026, 8, 11),
      lat: 30.2241,
      lng: -92.0198,
    );

    expect(result.sunrise, isNotNull);
    expect(result.sunset, isNotNull);

    // Lafayette is UTC-5 on Aug 11, 2026. Its local sunset is on Aug 11
    // evening, which is after midnight UTC on Aug 12. The solar event must
    // therefore retain Aug 12 as its UTC calendar date.
    expect(result.sunrise!.year, 2026);
    expect(result.sunrise!.month, 8);
    expect(result.sunrise!.day, 11);

    expect(result.sunset!.year, 2026);
    expect(result.sunset!.month, 8);
    expect(result.sunset!.day, 12);
  });
}
