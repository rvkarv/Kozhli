import 'package:flutter_test/flutter_test.dart';

import '../lib/core/thaarai_calculator.dart';

void main() {
  test('பூரம் to திருவாதிரை is 23rd Pratyakku Thaarai', () {
    final result = ThaaraiCalculator.compute(
      birthNakshatra: 'பூரம்',
      todayNakshatra: 'திருவாதிரை',
    );

    expect(result, isNotNull);
    expect(result!.ordinalFromBirth, 23);
    expect(result.category.tamil, 'பிரத்தியக்கு தாரை');
  });

  test('ஆயில்யம் to திருவாதிரை is 25th Vadhai Thaarai', () {
    final result = ThaaraiCalculator.compute(
      birthNakshatra: 'ஆயில்யம்',
      todayNakshatra: 'திருவாதிரை',
    );

    expect(result, isNotNull);
    expect(result!.ordinalFromBirth, 25);
    expect(result.category.tamil, 'வதை தாரை');
  });
}
