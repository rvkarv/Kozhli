import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/nakshatra_calculator.dart';

void main() {
  group('Moon Nakshatra reference checks', () {
    test('Chennai: Punarvasu begins after the verified 10-Aug boundary', () {
      // Verified reference: Chennai, IST.
      // Punarvasu starts at 10-Aug-2026 12:27 PM and ends
      // 11-Aug-2026 10:09 AM. Test safely inside the interval.
      final pos = NakshatraCalculator.computeCurrent(
        DateTime.utc(2026, 8, 10, 7, 0), // 12:30 PM IST
      );

      expect(pos.nakshatraName, 'புனர்பூசம்');
      expect(pos.pada, 1);
      expect(pos.rasiName, 'மிதுனம்');
    });

    test('Chennai: Punarvasu remains active shortly before the verified end', () {
      final pos = NakshatraCalculator.computeCurrent(
        DateTime.utc(2026, 8, 11, 4, 30), // 10:00 AM IST
      );

      expect(pos.nakshatraName, 'புனர்பூசம்');
    });

    test('Chennai: Pushya follows the verified 11-Aug 10:09 boundary', () {
      final pos = NakshatraCalculator.computeCurrent(
        DateTime.utc(2026, 8, 11, 4, 45), // 10:15 AM IST
      );

      expect(pos.nakshatraName, 'பூசம்');
    });

    test('Chennai: 10-Aug 16:50 is Punarvasu pada 1', () {
      // 16:50:17 IST = 11:20:17 UTC. With the same sidereal longitude
      // calculation used by the dashboard, this instant is still in
      // Punarvasu pada 1. Pada 3 begins later in the evening.
      final pos = NakshatraCalculator.computeCurrent(
        DateTime.utc(2026, 8, 10, 11, 20, 17),
      );

      expect(pos.nakshatraName, 'புனர்பூசம்');
      expect(pos.pada, 1);
      expect(pos.rasiName, 'மிதுனம்');
    });

    test('Lafayette: 10-Aug-2026 shortly after the Punarvasu boundary is pada 1', () {
      // Lafayette is UTC-05:00 (CDT) on this date.
      // 01:58 AM CDT = 06:58 UTC, safely after the approximately
      // 06:57:24 UTC Punarvasu boundary and away from the exact edge.
      final pos = NakshatraCalculator.computeCurrent(
        DateTime.utc(2026, 8, 10, 6, 58),
      );

      expect(pos.nakshatraName, 'புனர்பூசம்');
      expect(pos.pada, 1);
      expect(pos.rasiName, 'மிதுனம்');
    });

    test('Lafayette: 10-Aug-2026 11:03:13 AM CDT is Punarvasu pada 2', () {
      // 11:03:13 AM CDT = 16:03:13 UTC.
      // This explicitly protects the regression reported when the device
      // itself is in Chennai but the selected place is Lafayette.
      final pos = NakshatraCalculator.computeCurrent(
        DateTime.utc(2026, 8, 10, 16, 3, 13),
      );

      expect(pos.nakshatraName, 'புனர்பூசம்');
      expect(pos.pada, 2);
      expect(pos.rasiName, 'மிதுனம்');
    });
  });
}
