import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/core/moon_nakshatra_window.dart';

void main() {
  test('Rajahmundry 15-Aug-2026 Moon window matches Master Workbook', () {
    // Master Workbook reference:
    // local Rajahmundry 15-Aug-2026 12:16 PM IST
    // Nakshatra: Uttara Phalguni, Pada 2
    // Nakshatra: 03:43:18.742 -> next day 03:26:03.156 IST
    // Pada 2:       09:35:12.797 -> 15:29:37.906 IST
    final window = MoonNakshatraWindow.forUtc(
      DateTime.utc(2026, 8, 15, 6, 46),
    );

    expect(window.startUtc, DateTime.utc(2026, 8, 14, 22, 13, 18, 742000));
    expect(window.endUtc, DateTime.utc(2026, 8, 15, 21, 56, 3, 156000));
    expect(window.padaStartUtc, DateTime.utc(2026, 8, 15, 4, 5, 12, 797000));
    expect(window.padaEndUtc, DateTime.utc(2026, 8, 15, 9, 59, 37, 906000));
  });
}
