import 'package:flutter_test/flutter_test.dart';

import 'package:safepill_frontend/main.dart';

void main() {
  testWidgets('SafePill app starts at splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SafePill'), findsOneWidget);
  });
}
