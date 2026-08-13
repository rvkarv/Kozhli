import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/panchapakshi_engine.dart';
import 'package:panchapakshi_app/models/pakshi.dart';
import 'package:panchapakshi_app/models/panchapakshi_state.dart';
import 'package:panchapakshi_app/services/timezone_service.dart';

void main() {
  setUpAll(TimezoneService.initialize);

  test('Rajahmundry Thursday night keeps Thursday Panchapakshi weekday', () {
    final state = PanchapakshiEngine.compute(
      bird: Pakshi.kozhi,
      nowLocal: DateTime(2026, 8, 13, 22, 24),
      nowUtc: DateTime.utc(2026, 8, 13, 16, 54),
      sunrise: DateTime(2026, 8, 13, 5, 46),
      sunset: DateTime(2026, 8, 13, 18, 30),
      nextSunrise: DateTime(2026, 8, 14, 5, 46),
      previousSunset: DateTime(2026, 8, 12, 18, 29),
    );

    expect(state.rulingWeekday, DateTime.thursday);
    expect(state.dayNight, DayNight.night);
  });

  test('Lafayette Thursday daytime uses Thursday and CDT solar window', () {
    final state = PanchapakshiEngine.compute(
      bird: Pakshi.kozhi,
      nowLocal: DateTime(2026, 8, 13, 11, 54),
      nowUtc: DateTime.utc(2026, 8, 13, 16, 54),
      sunrise: DateTime(2026, 8, 13, 6, 34),
      sunset: DateTime(2026, 8, 13, 19, 53),
      nextSunrise: DateTime(2026, 8, 14, 6, 34),
      previousSunset: DateTime(2026, 8, 12, 19, 52),
    );

    expect(state.rulingWeekday, DateTime.thursday);
    expect(state.dayNight, DayNight.day);
  });
}
