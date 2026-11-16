
/// Delivery lifecycle of a direct message, from the sender's perspective.
enum MessageDeliveryState { sent, delivered, read }

/// A single message inside a private buyer↔seller conversation.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final Map<String, String> reactions;
  final Set<String> deletedFor;
  bool deletedForEveryone;

  /// When the recipient's device received the message (null until delivered).
  DateTime? deliveredAt;

  /// When the recipient opened the message (null until read).
  DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    DateTime? sentAt,
    Map<String, String>? reactions,
    Set<String>? deletedFor,
    this.deletedForEveryone = false,
    this.deliveredAt,
    this.readAt,
  })  : sentAt = sentAt ?? DateTime.now(),
        reactions = reactions ?? <String, String>{},
        deletedFor = deletedFor ?? <String>{};

  /// Derived delivery state from the stored timestamps.
  MessageDeliveryState get deliveryState {
    if (readAt != null) return MessageDeliveryState.read;
    if (deliveredAt != null) return MessageDeliveryState.delivered;
    return MessageDeliveryState.sent;
  }
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
