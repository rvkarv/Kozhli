import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/kozhli_success_rules.dart';
import 'package:panchapakshi_app/models/pakshi.dart';

void _expectNear(DateTime actual, DateTime expected, {int seconds = 1}) {
  expect(
    actual.difference(expected).inMilliseconds.abs(),
    lessThanOrEqualTo(seconds * 1000),
    reason: 'Expected $expected, got $actual',
  );
}

void main() {
  test('Friday waxing day KOZHLI windows match Excel-calculated timings', () {
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

    // Excel Main!F7 = (day samam - 02:24) / 5.
    // The resulting KOZHLI periods are:
    // 05:46:05.443–06:35:48.821  ஊண் 75%
    // 08:18:42.337–08:56:25.716  நடை 50%
    // 10:51:19.231–11:23:02.610  அரசு 100%
    expect(windows.length, 3);

    expect(windows[0].bird, Pakshi.kozhi);
    expect(windows[0].activity, Thozhil.oon);
    expect(windows[0].percent, 75);
    _expectNear(windows[0].start, sunrise);
    _expectNear(windows[0].end, DateTime(2026, 8, 14, 6, 35, 48, 821000));

    expect(windows[1].bird, Pakshi.kozhi);
    expect(windows[1].activity, Thozhil.nadai);
    expect(windows[1].percent, 50);
    _expectNear(windows[1].start, DateTime(2026, 8, 14, 8, 18, 42, 337000));
    _expectNear(windows[1].end, DateTime(2026, 8, 14, 8, 56, 25, 716000));

    expect(windows[2].bird, Pakshi.kozhi);
    expect(windows[2].activity, Thozhil.arasu);
    expect(windows[2].percent, 100);
    _expectNear(windows[2].start, DateTime(2026, 8, 14, 10, 51, 19, 231000));
    _expectNear(windows[2].end, DateTime(2026, 8, 14, 11, 23, 2, 610000));
  });

  test('Friday waxing night KOZHLI windows match Excel sunset-to-next-sunrise timings', () {
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

    // Excel Main!F9 = (02:24 - night samam) / 5.
    // Only the KOZHLI success activities are returned:
    // 20:44:35.640–21:12:52.785  நடை 50%
    // 01:15:27.094–01:25:44.239  ஊண் 75%
    // 03:30:52.821–04:17:09.966  அரசு 100%
    expect(windows.length, 3);

    expect(windows[0].bird, Pakshi.kozhi);
    expect(windows[0].activity, Thozhil.nadai);
    expect(windows[0].percent, 50);
    _expectNear(windows[0].start, DateTime(2026, 8, 14, 20, 44, 35, 640000));
    _expectNear(windows[0].end, DateTime(2026, 8, 14, 21, 12, 52, 785000));

    expect(windows[1].bird, Pakshi.kozhi);
    expect(windows[1].activity, Thozhil.oon);
    expect(windows[1].percent, 75);
    _expectNear(windows[1].start, DateTime(2026, 8, 15, 1, 15, 27, 94000));
    _expectNear(windows[1].end, DateTime(2026, 8, 15, 1, 25, 44, 239000));

    expect(windows[2].bird, Pakshi.kozhi);
    expect(windows[2].activity, Thozhil.arasu);
    expect(windows[2].percent, 100);
    _expectNear(windows[2].start, DateTime(2026, 8, 15, 3, 30, 52, 821000));
    _expectNear(windows[2].end, DateTime(2026, 8, 15, 4, 17, 9, 966000));
  });
}
