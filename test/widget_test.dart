// Smoke test: the app boots and shows the Welcome screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:campus_events_app/main.dart';

void main() {
  testWidgets('Welcome screen renders with entry buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CampusEventsApp());
    await tester.pump();

    expect(find.text('CAMPUS EVENTS'), findsOneWidget);
    expect(find.text('I have an account'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });
}
