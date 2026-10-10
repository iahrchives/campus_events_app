import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import 'auth_service.dart';
import 'notification_service.dart';

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
    return _conversations.firstWhere(
      (c) => c.id == id,
      orElse: () {
        final convo = Conversation(
          id: id,
          itemId: itemId,
          itemTitle: itemTitle,
          buyerId: buyerId,
          sellerId: sellerId,
        );
        _conversations.add(convo);
        notifyListeners();
        return convo;
      },
    );
  }

  /// All conversations [uid] takes part in, most-recently-active first.
  List<Conversation> conversationsFor(String uid) {
    final list = _conversations.where((c) => c.includes(uid)).toList()
      ..sort((a, b) {
        final at = a.messages.isEmpty ? DateTime(0) : a.messages.last.sentAt;
        final bt = b.messages.isEmpty ? DateTime(0) : b.messages.last.sentAt;
        return bt.compareTo(at);
      });
    return list;
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
  void send(String conversationId, String senderId, String text) {
    final convo = _byId(conversationId);
    if (convo == null || !convo.includes(senderId) || text.trim().isEmpty) {
      return;
    }
    convo.messages.add(ChatMessage(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      senderId: senderId,
      text: text.trim(),
    ));
    _controllers[conversationId]?.add(List.unmodifiable(convo.messages));

    // Notify the recipient so they see it in their bell + message badge.
    final recipient = convo.otherParty(senderId);
    final senderName = AuthService.instance.nameForUid(senderId);
    NotificationService.instance.push(
      userId: recipient,
      type: AppNotificationType.message,
      title: 'New message from $senderName',
      body: 'About "${convo.itemTitle}": ${text.trim()}',
      targetId: convo.id,
    );
    notifyListeners();
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
