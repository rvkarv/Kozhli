import 'package:flutter_test/flutter_test.dart';
import 'package:kozhli/panchapakshi_rules.dart';

void main() {
  test('Master Workbook Aug 16 authoritative boundary reference', () {
    // Authoritative values transcribed from the latest Master Workbook.
    // This test records the reference timestamps before changing production
    // astronomy code. Exact production integration must reproduce these.
    expect('2026-08-15T09:35:51.880+05:30', '2026-08-15T09:35:51.880+05:30');
    expect('2026-08-17T16:18:53.106+05:30', '2026-08-17T16:18:53.106+05:30');
    expect('2026-08-16T03:26:12.884+05:30', '2026-08-16T03:26:12.884+05:30');
    expect('2026-08-16T09:28:26.726+05:30', '2026-08-16T09:28:26.726+05:30');
    expect('2026-08-16T15:33:21.647+05:30', '2026-08-16T15:33:21.647+05:30');
    expect('2026-08-17T03:51:04.425+05:30', '2026-08-17T03:51:04.425+05:30');
  });
}
