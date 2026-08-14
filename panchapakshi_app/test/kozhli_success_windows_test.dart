import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/kozhli_success_rules.dart';
import 'package:panchapakshi_app/models/pakshi.dart';

void main() {
  test('Friday waxing day windows start with KOZHLI at each jamam', () {
    final sunrise = DateTime(2026, 8, 14, 5, 46, 5, 443000);
    final sunset = DateTime(2026, 8, 14, 18, 29, 9, 913000);

    final windows = KozhliSuccessRules.windowsForPeriod(
      periodStart: sunrise,
      periodEnd: sunset,
      paksham: Paksham.valarpirai,
      dayNight: DayNight.day,
      rulingWeekday: DateTime.friday,
      paduDay: false,
    );

    expect(windows.length, greaterThanOrEqualTo(3));

    expect(windows[0].bird, Pakshi.kozhi);
    expect(windows[0].activity, Thozhil.oon);
    expect(windows[0].percent, 75);
    expect(windows[0].start.difference(sunrise).inSeconds.abs(), lessThanOrEqualTo(1));
    expect(
      windows[0].end.difference(DateTime(2026, 8, 14, 6, 35, 49)).inSeconds.abs(),
      lessThanOrEqualTo(1),
    );

    expect(windows[1].bird, Pakshi.kozhi);
    expect(windows[1].activity, Thozhil.oon);
    expect(windows[1].percent, 75);
    expect(
      windows[1].start.difference(DateTime(2026, 8, 14, 8, 18, 42)).inSeconds.abs(),
      lessThanOrEqualTo(1),
    );
    expect(
      windows[1].end.difference(DateTime(2026, 8, 14, 8, 56, 26)).inSeconds.abs(),
      lessThanOrEqualTo(1),
    );

    expect(windows[2].bird, Pakshi.kozhi);
    expect(windows[2].activity, Thozhil.arasu);
    expect(windows[2].percent, 100);
    expect(
      windows[2].start.difference(DateTime(2026, 8, 14, 10, 51, 19)).inSeconds.abs(),
      lessThanOrEqualTo(1),
    );
    expect(
      windows[2].end.difference(DateTime(2026, 8, 14, 11, 23, 3)).inSeconds.abs(),
      lessThanOrEqualTo(1),
    );
  });

  test('night windows remain inside the selected sunset-to-next-sunrise period', () {
    final sunset = DateTime(2026, 8, 14, 18, 29, 9, 913000);
    final nextSunrise = DateTime(2026, 8, 15, 5, 46, 18, 548000);

    final windows = KozhliSuccessRules.windowsForPeriod(
      periodStart: sunset,
      periodEnd: nextSunrise,
      paksham: Paksham.valarpirai,
      dayNight: DayNight.night,
      rulingWeekday: DateTime.friday,
      paduDay: false,
    );

    for (final window in windows) {
      expect(window.start.isBefore(window.end), isTrue);
      expect(window.start.isBefore(nextSunrise), isTrue);
      expect(window.end.isAfter(sunset), isTrue);
      expect(window.bird, Pakshi.kozhi);
      expect(window.percent, anyOf(50, 75, 100));
    }
  });
}
