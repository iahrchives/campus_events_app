/// A single message inside a private buyer↔seller conversation.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();
}

/// A private 1-on-1 conversation about a marketplace listing. Only the two
/// [participantIds] (buyer + seller) take part.
class Conversation {
  final String id;
  final String itemId;
  final String itemTitle;
  final String buyerId;
  final String sellerId;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.buyerId,
    required this.sellerId,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  /// True only if [uid] is one of the two participants.
  bool includes(String uid) => uid == buyerId || uid == sellerId;

  /// The other participant from [uid]'s perspective.
  String otherParty(String uid) => uid == buyerId ? sellerId : buyerId;
}
