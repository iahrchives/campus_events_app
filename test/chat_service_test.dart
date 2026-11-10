import 'package:flutter_test/flutter_test.dart';

import 'package:campus_events_app/services/auth_service.dart';
import 'package:campus_events_app/services/chat_service.dart';
import 'package:campus_events_app/services/report_service.dart';

void main() {
  final chat = ChatService.instance;

  test('contactsFor groups threads by person and sorts by activity', () async {
    const me = 'contact_me_1';
    const seller = 'contact_seller_1';
    const other = 'contact_other_1';

    final first = chat.openConversation(
      itemId: 'contact_item_1',
      itemTitle: 'Laptop',
      buyerId: me,
      sellerId: seller,
    );
    chat.send(first.id, seller, 'still available?');
    await Future.delayed(const Duration(milliseconds: 1));

    final second = chat.openConversation(
      itemId: 'contact_item_2',
      itemTitle: 'Book',
      buyerId: me,
      sellerId: seller,
    );
    chat.send(second.id, me, 'I am interested');
    await Future.delayed(const Duration(milliseconds: 1));

    final third = chat.openConversation(
      itemId: 'contact_item_3',
      itemTitle: 'Chair',
      buyerId: me,
      sellerId: other,
    );
    chat.send(third.id, other, 'latest message');

    final contacts = chat.contactsFor(me);
    expect(contacts.length, 2);
    expect(contacts.first.uid, other);

    final sellerContact =
        contacts.firstWhere((contact) => contact.uid == seller);
    expect(sellerContact.conversations.length, 2);
  });

  test('removeContact hides a thread until a new message arrives', () {
    const me = 'contact_me_2';
    const seller = 'contact_seller_2';

    final convo = chat.openConversation(
      itemId: 'contact_item_4',
      itemTitle: 'Camera',
      buyerId: me,
      sellerId: seller,
    );
    chat.send(convo.id, me, 'hello');
    expect(chat.contactsFor(me).any((c) => c.uid == seller), isTrue);

    chat.removeContact(me, seller);
    expect(chat.contactsFor(me).any((c) => c.uid == seller), isFalse);
    expect(chat.conversationsFor(me).any((c) => c.id == convo.id), isFalse);

    chat.send(convo.id, seller, 'are you still there?');
    expect(chat.contactsFor(me).any((c) => c.uid == seller), isTrue);
  });

  test('blocking stops messages both ways and unblock restores contact', () {
    const me = 'contact_me_3';
    const seller = 'contact_seller_3';

    final convo = chat.openConversation(
      itemId: 'contact_item_5',
      itemTitle: 'Desk',
      buyerId: me,
      sellerId: seller,
    );
    chat.send(convo.id, me, 'hi');
    expect(convo.messages.length, 1);

    chat.blockContact(me, seller);
    expect(chat.isBlockedBetween(me, seller), isTrue);
    expect(chat.conversationsFor(me).any((c) => c.id == convo.id), isFalse);

    chat.send(convo.id, seller, 'blocked reply');
    chat.send(convo.id, me, 'blocked reply');
    expect(convo.messages.length, 1);

    chat.unblockContact(me, seller);
    expect(chat.isBlockedBetween(me, seller), isFalse);
    chat.send(convo.id, seller, 'now it works');
    expect(convo.messages.length, 2);
  });

  test('reportContact records a report with its reason and conversation', () {
    const me = 'contact_me_4';
    const seller = 'contact_seller_4';

    final convo = chat.openConversation(
      itemId: 'contact_item_6',
      itemTitle: 'Phone',
      buyerId: me,
      sellerId: seller,
    );
    final before = ReportService.instance.reports.length;

    chat.reportContact(
      me,
      seller,
      'Spam or scam',
      conversationId: convo.id,
    );

    expect(ReportService.instance.reports.length, before + 1);
    final report = ReportService.instance.reports.firstWhere(
      (r) =>
          r.reporterId == me &&
          r.reason == 'Spam or scam' &&
          r.conversationId == convo.id,
    );
    expect(report.targetId, seller);
    expect(report.contextLabel, 'Phone');
  });

  test('content visibility is symmetric for both block directions', () {
    const a = 'visibility_user_a';
    const b = 'visibility_user_b';
    const c = 'visibility_user_c';

    chat.blockContact(a, b);

    expect(chat.canSeeContentFrom(a, b), isFalse);
    expect(chat.canSeeContentFrom(b, a), isFalse);
    expect(chat.canSeeContentFrom(c, a), isTrue);

    chat.unblockContact(a, b);
    expect(chat.canSeeContentFrom(a, b), isTrue);
    expect(chat.canSeeContentFrom(b, a), isTrue);
  });

  test('admins bypass content visibility filtering', () async {
    const admin = 'uid_admin_000';
    const other = 'visibility_other_user';

    chat.blockContact(admin, other);
    await AuthService.instance.signIn(
      email: 'admin@campus.edu',
      password: 'password123',
    );

    expect(chat.canSeeContentFrom(admin, other), isTrue);
    expect(chat.canSeeContentFrom(other, admin), isFalse);

    chat.unblockContact(admin, other);
    AuthService.instance.signOut();
  });
}
