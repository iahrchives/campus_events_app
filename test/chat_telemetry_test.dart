import 'package:flutter_test/flutter_test.dart';

import 'package:campus_events_app/models/chat.dart';
import 'package:campus_events_app/services/auth_service.dart';
import 'package:campus_events_app/services/chat_service.dart';
import 'package:campus_events_app/services/presence_service.dart';

void main() {
  final chat = ChatService.instance;
  final presence = PresenceService.instance;

  tearDown(() {
    AuthService.instance.signOut();
  });

  test('a message progresses Sent -> Delivered -> Read', () {
    const me = 'telemetry_me_1';
    const peer = 'telemetry_peer_1';

    final convo = chat.openConversation(
      itemId: 'telemetry_item_1',
      itemTitle: 'Laptop',
      buyerId: me,
      sellerId: peer,
    );
    expect(chat.send(convo.id, me, 'hello'), isTrue);

    var message = convo.messages.last;
    expect(message.deliveryState, MessageDeliveryState.sent);
    expect(chat.visibleStateFor(message, peer), MessageDeliveryState.sent);

    // Recipient device becomes active -> Delivered.
    presence.markOnline(peer);
    message = convo.messages.last;
    expect(message.deliveredAt, isNotNull);
    expect(chat.visibleStateFor(message, peer), MessageDeliveryState.delivered);

    // Recipient opens the thread -> Read.
    chat.markConversationRead(convo.id, peer);
    message = convo.messages.last;
    expect(message.readAt, isNotNull);
    expect(chat.visibleStateFor(message, peer), MessageDeliveryState.read);

    presence.markOffline(peer);
  });

  test('disabled read receipts cap the sender at Delivered', () {
    const me = 'telemetry_me_2';
    const peer = 'telemetry_peer_2';

    final convo = chat.openConversation(
      itemId: 'telemetry_item_2',
      itemTitle: 'Camera',
      buyerId: me,
      sellerId: peer,
    );
    chat.send(convo.id, me, 'still there?');
    presence.markOnline(peer);
    chat.markConversationRead(convo.id, peer);

    final message = convo.messages.last;
    expect(chat.visibleStateFor(message, peer), MessageDeliveryState.read);

    chat.setReadReceiptsEnabled(peer, false);
    expect(chat.visibleStateFor(message, peer), MessageDeliveryState.delivered);

    chat.setReadReceiptsEnabled(peer, true);
    expect(chat.visibleStateFor(message, peer), MessageDeliveryState.read);

    presence.markOffline(peer);
  });

  test('active status privacy hides presence from the UI', () {
    const uid = 'telemetry_presence_1';

    expect(presence.activeStatusEnabledFor(uid), isTrue);
    presence.markOnline(uid);
    expect(presence.canShowStatus(uid), isTrue);
    expect(presence.isOnline(uid), isTrue);

    presence.setActiveStatusEnabled(uid, false);
    expect(presence.canShowStatus(uid), isFalse);
    // The raw flag still drives delivery internally.
    expect(presence.isOnline(uid), isTrue);

    presence.setActiveStatusEnabled(uid, true);
    expect(presence.canShowStatus(uid), isTrue);

    presence.markOffline(uid);
    expect(presence.lastSeenFor(uid), isNotNull);
  });

  test('signing in and out syncs presence', () async {
    const uid = 'uid_validated_001';

    await AuthService.instance.signIn(
      email: 'validated@campus.edu',
      password: 'password123',
    );
    expect(presence.isOnline(uid), isTrue);
    expect(presence.lastSeenFor(uid), isNotNull);

    AuthService.instance.signOut();
    expect(presence.isOnline(uid), isFalse);
    expect(presence.lastSeenFor(uid), isNotNull);
  });
}
