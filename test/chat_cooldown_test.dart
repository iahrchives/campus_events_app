import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_events_app/screens/chat_screen.dart';
import 'package:campus_events_app/services/auth_service.dart';
import 'package:campus_events_app/services/chat_service.dart';

void main() {
  testWidgets('chat send button enforces a 3 second cooldown',
      (tester) async {
    addTearDown(AuthService.instance.signOut);
    await tester.runAsync(() => AuthService.instance.signIn(
          email: 'validated@campus.edu',
          password: 'password123',
        ));

    const me = 'uid_validated_001';
    const seller = 'cooldown_seller_001';
    final convo = ChatService.instance.openConversation(
      itemId: 'cooldown_item_001',
      itemTitle: 'Cooldown item',
      buyerId: me,
      sellerId: seller,
    );

    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(conversation: convo)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'first message');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(convo.messages.length, 1);
    expect(find.byTooltip('Please wait 3s'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'second message');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Send'), findsOneWidget);

    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(convo.messages.length, 2);

    // Let the final cooldown expire so no timers remain pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
