import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Kinds of in-app notifications surfaced in the navigation bar bell.
enum AppNotificationType { forumReply, forumReaction, message, announcement, system }

extension AppNotificationTypeX on AppNotificationType {
  IconData get icon {
    switch (this) {
      case AppNotificationType.forumReply:
        return Icons.mode_comment_outlined;
      case AppNotificationType.forumReaction:
        return Icons.favorite_outline;
      case AppNotificationType.message:
        return Icons.chat_bubble_outline;
      case AppNotificationType.announcement:
        return Icons.campaign_outlined;
      case AppNotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (this) {
      case AppNotificationType.forumReply:
        return AppColors.primary;
      case AppNotificationType.forumReaction:
        return AppColors.danger;
      case AppNotificationType.message:
        return AppColors.secondary;
      case AppNotificationType.announcement:
        return AppColors.success;
      case AppNotificationType.system:
        return AppColors.textMuted;
    }
  }
}

/// A single in-app notification addressed to one recipient.
class AppNotification {
  final String id;

  /// uid of the recipient this notification belongs to.
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;

  /// Optional id of the thing to open (e.g. a forum postId).
  final String? targetId;
  bool read;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// App-wide in-app notification centre (forum replies, reactions, messages…).
///
/// A [ChangeNotifier] singleton so the nav-bar bell badge and the notifications
/// screen update live. Mirrors a future Firestore `Notifications` collection.
class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final List<AppNotification> _items = [];

  /// Notifications for [uid], newest first.
  List<AppNotification> forUser(String uid) {
    final list = _items.where((n) => n.userId == uid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  int unreadFor(String uid) =>
      _items.where((n) => n.userId == uid && !n.read).length;

  /// Adds a notification for [userId]. No-op when the recipient is empty.
  void push({
    required String userId,
    required AppNotificationType type,
    required String title,
    required String body,
    String? targetId,
  }) {
    if (userId.isEmpty) return;
    _items.insert(
      0,
      AppNotification(
        id: 'n_${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        type: type,
        title: title,
        body: body,
        targetId: targetId,
      ),
    );
    notifyListeners();
  }

  void markRead(String id) {
    for (final n in _items) {
      if (n.id == id) {
        n.read = true;
        break;
      }
    }
    notifyListeners();
  }

  void markAllRead(String uid) {
    for (final n in _items) {
      if (n.userId == uid) n.read = true;
    }
    notifyListeners();
  }

  void clearFor(String uid) {
    _items.removeWhere((n) => n.userId == uid);
    notifyListeners();
  }
}
