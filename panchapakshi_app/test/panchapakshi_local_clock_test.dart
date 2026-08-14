import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/models/pakshi.dart';
import 'package:panchapakshi_app/services/app_state.dart';
import 'package:panchapakshi_app/services/timezone_service.dart';
import 'package:panchapakshi_app/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(TimezoneService.initialize);

  ResolvedLocation lafayette() => const ResolvedLocation(
        label: 'Lafayette, Louisiana, USA',
        lat: 30.2241,
        lng: -92.0198,
        timeZoneId: 'America/Chicago',
      );

  test('Lafayette 09:17 AM is treated as local daytime', () {
    final app = AppState();

    // Inject the test location directly. Do NOT call useManualLocation()
    // here because that production method deliberately persists the selected
    // location through SharedPreferences. These unit tests must not depend
    // on a platform plugin.
    app.location = lafayette();
    app.setOverrideDateTime(DateTime(2026, 8, 11, 9, 17));

    final state = app.state;
    expect(state, isNotNull);
    expect(state!.dayNight, DayNight.day);
    expect(state.asOf.hour, 9);
    expect(state.asOf.minute, 17);
    expect(state.sunrise.hour, lessThan(7));
    expect(state.sunset.hour, greaterThanOrEqualTo(19));
    expect(app.currentLocationOffset?.inHours, -5);

    app.dispose();
  });

  test('Lafayette 04:38 AM remains nighttime before sunrise', () {
    final app = AppState();

    app.location = lafayette();
    app.setOverrideDateTime(DateTime(2026, 8, 11, 4, 38));

    final state = app.state;
    expect(state, isNotNull);
    expect(state!.dayNight, DayNight.night);
    expect(state.asOf.hour, 4);
    expect(state.asOf.minute, 38);

    app.dispose();
  });
}
