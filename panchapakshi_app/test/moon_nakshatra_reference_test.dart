import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/nakshatra_calculator.dart';

void main() {
  group('Moon Nakshatra reference checks', () {
    test('Chennai: Punarvasu begins after the verified 10-Aug boundary', () {
      // Verified reference: Chennai, IST
      // Punarvasu starts at 10-Aug-2026 12:27 PM and ends
      // 11-Aug-2026 10:09 AM. We test safely inside the interval so the
      // test does not depend on a source that only publishes minute precision.
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

    test('Chennai: AstroSage reference at 10-Aug 16:50 is Punarvasu pada 3', () {
      final pos = NakshatraCalculator.computeCurrent(
        DateTime.utc(2026, 8, 10, 11, 20, 17), // 16:50:17 IST
      );

      expect(pos.nakshatraName, 'புனர்பூசம்');
      expect(pos.pada, 3);
      expect(pos.rasiName, 'மிதுனம்');
    });

    test('Lafayette reference uses the same astronomical instant after UTC conversion', () {
      // Lafayette, Louisiana was shown in the reference at UTC-05:00.
      // 10-Aug-2026 01:57:24 AM CDT = 06:57:24 UTC.
      final pos = NakshatraCalculator.computeCurrent(
        DateTime.utc(2026, 8, 10, 6, 57, 24),
      );

      expect(pos.nakshatraName, 'புனர்பூசம்');
      expect(pos.pada, 1);
      expect(pos.rasiName, 'மிதுனம்');
    });
  });
}
