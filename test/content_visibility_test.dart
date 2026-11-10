import 'package:flutter_test/flutter_test.dart';

import 'package:campus_events_app/models/item.dart';
import 'package:campus_events_app/services/auth_service.dart';
import 'package:campus_events_app/services/chat_service.dart';
import 'package:campus_events_app/services/event_service.dart';
import 'package:campus_events_app/services/forum_service.dart';
import 'package:campus_events_app/services/item_service.dart';

void main() {
  final chat = ChatService.instance;

  tearDown(() {
    chat.unblockContact('uid_validated_001', 'uid_pending_002');
    chat.unblockContact('uid_pending_002', 'uid_validated_001');
    chat.unblockContact('uid_admin_000', 'uid_pending_002');
    AuthService.instance.signOut();
  });

  test('blocked users no longer see each other\'s content', () async {
    await AuthService.instance.signIn(
      email: 'validated@campus.edu',
      password: 'password123',
    );
    chat.blockContact('uid_validated_001', 'uid_pending_002');

    final marketItems = ItemService.instance.byType(PostType.marketplace);
    expect(
      marketItems.any((item) => item.posterID == 'uid_pending_002'),
      isFalse,
    );
    expect(
      marketItems.any((item) => item.posterID == 'uid_validated_001'),
      isTrue,
    );

    final lostItems = ItemService.instance.byType(PostType.lostFound);
    expect(
      lostItems.any((item) => item.posterID == 'uid_pending_002'),
      isFalse,
    );

    final posts = ForumService.instance.current;
    expect(posts.any((post) => post.authorId == 'uid_pending_002'), isFalse);
    expect(posts.any((post) => post.authorId == 'uid_validated_001'), isTrue);
    expect(ForumService.instance.visibleById('p2'), isNull);
    expect(ForumService.instance.visibleById('p1'), isNotNull);

    final events = EventService.instance.current;
    expect(
      events.any((event) => event.organizerID == 'uid_pending_002'),
      isFalse,
    );
    expect(
      events.any((event) => event.organizerID == 'uid_validated_001'),
      isTrue,
    );
  });

  test('a user blocked by another stops seeing the blocker\'s content',
      () async {
    // Pending blocks Validated, then Validated signs in.
    chat.blockContact('uid_pending_002', 'uid_validated_001');
    await AuthService.instance.signIn(
      email: 'validated@campus.edu',
      password: 'password123',
    );

    final marketItems = ItemService.instance.byType(PostType.marketplace);
    expect(
      marketItems.any((item) => item.posterID == 'uid_pending_002'),
      isFalse,
    );
    // The viewer's own content stays visible.
    expect(
      marketItems.any((item) => item.posterID == 'uid_validated_001'),
      isTrue,
    );
  });

  test('admins still see all content after blocking a user', () async {
    chat.blockContact('uid_admin_000', 'uid_pending_002');
    await AuthService.instance.signIn(
      email: 'admin@campus.edu',
      password: 'password123',
    );

    final marketItems = ItemService.instance.byType(PostType.marketplace);
    expect(
      marketItems.any((item) => item.posterID == 'uid_pending_002'),
      isTrue,
    );
  });
}
