import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../models/contact.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'report_service.dart';

/// Mock store for private buyer↔seller conversations + admin broadcasts
/// (mirrors a Firestore `Conversations` collection scoped by participant ids).
///
/// Extends [ChangeNotifier] so the nav-bar message badge and the inbox update
/// live whenever a message arrives or a thread is opened/read.
class ChatService extends ChangeNotifier {
  ChatService._();
  static final ChatService instance = ChatService._();

  final List<Conversation> _conversations = [];
  final Map<String, StreamController<List<ChatMessage>>> _controllers = {};

  /// Admin → everyone broadcast messages, visible to every signed-in user.
  final List<BroadcastMessage> _broadcasts = [];

  /// Last time the current device opened a given conversation / the broadcast
  /// thread, used to compute the unread badge.
  final Map<String, DateTime> _lastRead = {};
  DateTime? _broadcastLastRead;

  /// Conversation ids a user has removed from their contact list. The thread is
  /// hidden from that user only; a new incoming message brings it back.
  final Map<String, Set<String>> _hiddenThreads = {};

  /// blocker uid → uids they have blocked. Blocking is one-directional to store
  /// but enforced both ways so neither party can message the other.
  final Map<String, Set<String>> _blocked = {};

  /// Returns the existing conversation between [buyerId] and [sellerId] about
  /// [itemId], creating it on first message. The conversation is keyed so each
  /// buyer↔seller↔item triple gets its own private thread.
  Conversation openConversation({
    required String itemId,
    required String itemTitle,
    required String buyerId,
    required String sellerId,
  }) {
    final id = '${itemId}_${buyerId}_$sellerId';
    final convo = _conversations.firstWhere(
      (c) => c.id == id,
      orElse: () {
        final created = Conversation(
          id: id,
          itemId: itemId,
          itemTitle: itemTitle,
          buyerId: buyerId,
          sellerId: sellerId,
        );
        _conversations.add(created);
        notifyListeners();
        return created;
      },
    );
    // Explicitly opening a thread brings it back into the contact list.
    final unhidden = _hiddenFor(buyerId).remove(id);
    final alsoUnhidden = _hiddenFor(sellerId).remove(id);
    if (unhidden || alsoUnhidden) notifyListeners();
    return convo;
  }

  /// All conversations [uid] takes part in, most-recently-active first.
  ///
  /// Threads the user removed and conversations with blocked users are hidden.
  List<Conversation> conversationsFor(String uid) {
    final hidden = _hiddenThreads[uid] ?? const <String>{};
    final list = _conversations
        .where((c) =>
            c.includes(uid) &&
            !hidden.contains(c.id) &&
            !isBlockedBetween(uid, c.otherParty(uid)))
        .toList()
      ..sort((a, b) {
        final at = a.messages.isEmpty ? DateTime(0) : a.messages.last.sentAt;
        final bt = b.messages.isEmpty ? DateTime(0) : b.messages.last.sentAt;
        return bt.compareTo(at);
      });
    return list;
  }

  /// One [Contact] per person [uid] has a visible conversation with, newest
  /// activity first.
  List<Contact> contactsFor(String uid) {
    final grouped = <String, List<Conversation>>{};
    for (final c in conversationsFor(uid)) {
      grouped.putIfAbsent(c.otherParty(uid), () => []).add(c);
    }
    final contacts = grouped.entries
        .map((e) => Contact(uid: e.key, conversations: e.value))
        .toList()
      ..sort((a, b) {
        final at = a.lastActivity ?? DateTime(0);
        final bt = b.lastActivity ?? DateTime(0);
        return bt.compareTo(at);
      });
    return contacts;
  }

  /// Removes [otherUid] from [uid]'s contact list by hiding their threads.
  /// This does not block them — a new message will surface the thread again.
  void removeContact(String uid, String otherUid) {
    final hidden = _hiddenFor(uid);
    for (final c in _conversations) {
      if (c.includes(uid) && c.includes(otherUid)) hidden.add(c.id);
    }
    notifyListeners();
  }

  /// Blocks [otherUid] so neither party can send messages to the other.
  void blockContact(String uid, String otherUid) {
    if (uid.isEmpty || otherUid.isEmpty || uid == otherUid) return;
    _blocked.putIfAbsent(uid, () => <String>{}).add(otherUid);
    notifyListeners();
  }

  /// Lifts a block [uid] previously placed on [otherUid].
  void unblockContact(String uid, String otherUid) {
    _blocked[uid]?.remove(otherUid);
    notifyListeners();
  }

  /// True if [blockerId] has explicitly blocked [blockedId].
  bool hasBlocked(String blockerId, String blockedId) =>
      _blocked[blockerId]?.contains(blockedId) ?? false;

  /// True if either [a] or [b] has blocked the other.
  bool isBlockedBetween(String a, String b) =>
      hasBlocked(a, b) || hasBlocked(b, a);

  /// Whether [viewerId] may see content authored by [authorId].
  ///
  /// Blocking is symmetric for visibility: if either side blocked the other,
  /// neither sees the other's posts. Admins bypass this for moderation.
  bool canSeeContentFrom(String viewerId, String authorId) {
    if (viewerId.isEmpty || authorId.isEmpty || viewerId == authorId) {
      return true;
    }
    if (AuthService.instance.profileForUid(viewerId)?.isAdmin ?? false) {
      return true;
    }
    return !isBlockedBetween(viewerId, authorId);
  }

  /// Convenience wrapper around [canSeeContentFrom] for the signed-in user.
  bool canSeeContentFromCurrentUser(String authorId) {
    final viewerId = AuthService.instance.currentUser?.uid ?? '';
    return canSeeContentFrom(viewerId, authorId);
  }

  /// Uids that [uid] has blocked.
  List<String> blockedContactsFor(String uid) =>
      (_blocked[uid] ?? const <String>{}).toList();

  /// Records a moderation report against [reportedUid] for admin review.
  void reportContact(
    String reporterId,
    String reportedUid,
    String reason, {
    String? conversationId,
  }) {
    if (reporterId.isEmpty ||
        reportedUid.isEmpty ||
        reporterId == reportedUid) {
      return;
    }
    final convo = conversationId == null ? null : _byId(conversationId);
    ReportService.instance.submitContact(
      reporterId: reporterId,
      reportedUid: reportedUid,
      reason: reason,
      reporterName: AuthService.instance.nameForUid(reporterId),
      reportedName: AuthService.instance.nameForUid(reportedUid),
      conversationId: conversationId,
      contextLabel: convo?.itemTitle,
    );
  }

  Stream<List<ChatMessage>> messages(String conversationId) {
    final ctrl = _controllers.putIfAbsent(
      conversationId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    // Prime late subscribers with the current history.
    final convo = _byId(conversationId);
    scheduleMicrotask(() {
      if (!ctrl.isClosed) {
        ctrl.add(List.unmodifiable(convo?.messages ?? const []));
      }
    });
    return ctrl.stream;
  }

  /// Sends [text] from [senderId]. Rejects senders who aren't a participant.
  ///
  /// Returns true when the message was appended, false when the send was
  /// rejected (empty text, non-participant, or either side blocked).
  bool send(String conversationId, String senderId, String text) {
    final convo = _byId(conversationId);
    if (convo == null || !convo.includes(senderId) || text.trim().isEmpty) {
      return false;
    }
    final recipient = convo.otherParty(senderId);
    // Blocking stops contact in both directions.
    if (isBlockedBetween(senderId, recipient)) return false;

    convo.messages.add(ChatMessage(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      senderId: senderId,
      text: text.trim(),
    ));
    // A new message brings a previously removed thread back for both parties.
    _hiddenFor(recipient).remove(conversationId);
    _hiddenFor(senderId).remove(conversationId);
    _controllers[conversationId]?.add(List.unmodifiable(convo.messages));

    // Notify the recipient so they see it in their bell + message badge.
    final senderName = AuthService.instance.nameForUid(senderId);
    NotificationService.instance.push(
      userId: recipient,
      type: AppNotificationType.message,
      title: 'New message from $senderName',
      body: 'About "${convo.itemTitle}": ${text.trim()}',
      targetId: convo.id,
    );
    notifyListeners();
    return true;
  }

  // ---- Admin broadcasts ----
  List<BroadcastMessage> get broadcasts => List.unmodifiable(
        _broadcasts.reversed,
      );

  bool get hasBroadcasts => _broadcasts.isNotEmpty;

  BroadcastMessage? get latestBroadcast =>
      _broadcasts.isEmpty ? null : _broadcasts.last;

  /// Admin sends a message to every user. Also drops a notification in each
  /// (non-admin) user's bell.
  void sendBroadcast(String senderName, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _broadcasts.add(BroadcastMessage(
      id: 'b_${DateTime.now().microsecondsSinceEpoch}',
      senderName: senderName,
      text: t,
    ));
    for (final p in AuthService.instance.allProfiles()) {
      if (p.isAdmin) continue;
      NotificationService.instance.push(
        userId: p.uid,
        type: AppNotificationType.message,
        title: 'Message from $senderName',
        body: t,
        targetId: 'broadcast',
      );
    }
    notifyListeners();
  }

  // ---- Unread tracking ----
  /// Unread badge count for [uid]: conversations with an unseen incoming
  /// message, plus 1 if there are unseen admin broadcasts.
  int unreadFor(String uid) {
    var count = 0;
    for (final c in conversationsFor(uid)) {
      if (c.messages.isEmpty) continue;
      final last = c.messages.last;
      final seenAt = _lastRead[c.id];
      if (last.senderId != uid &&
          (seenAt == null || last.sentAt.isAfter(seenAt))) {
        count++;
      }
    }
    if (_broadcasts.isNotEmpty) {
      final last = _broadcasts.last.sentAt;
      if (_broadcastLastRead == null || last.isAfter(_broadcastLastRead!)) {
        count++;
      }
    }
    return count;
  }

  void markConversationRead(String conversationId) {
    _lastRead[conversationId] = DateTime.now();
    notifyListeners();
  }

  void markBroadcastsRead() {
    _broadcastLastRead = DateTime.now();
    notifyListeners();
  }

  Set<String> _hiddenFor(String uid) =>
      _hiddenThreads.putIfAbsent(uid, () => <String>{});

  Conversation? _byId(String id) {
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// A campus-wide message published by an admin to all users.
class BroadcastMessage {
  final String id;
  final String senderName;
  final String text;
  final DateTime sentAt;

  BroadcastMessage({
    required this.id,
    required this.senderName,
    required this.text,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();
}
