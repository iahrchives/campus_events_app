import 'chat.dart';

/// A person the current user has an active direct-message thread with.

/// Contacts are from marketplace conversations.
class Contact {
  final String uid;
  final List<Conversation> conversations;

  Contact({required this.uid, required List<Conversation> conversations})
      : conversations = List.unmodifiable(conversations);

  /// Most recent conversation with contact.
  Conversation get latest => conversations.first;

  /// When the latest message in the newest thread was sent (null if empty).
  DateTime? get lastActivity {
    final messages = latest.messages;
    return messages.isEmpty ? null : messages.last.sentAt;
  }
}
