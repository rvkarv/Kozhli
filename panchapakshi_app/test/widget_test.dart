import 'package:flutter_test/flutter_test.dart';

import 'package:panchapakshi_app/main.dart';

void main() {
  testWidgets('KOZHLI app boots', (tester) async {
    await tester.pumpWidget(const PanchapakshiApp());
    expect(find.text('KOZHLI'), findsOneWidget);
  });
}
