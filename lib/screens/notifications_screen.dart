import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/soft_card.dart';
import 'forum_post_detail_screen.dart';

/// In-app notification centre — forum replies, reactions and messages aimed at
/// the current user. Opened from the nav-bar bell.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String get _uid => AuthService.instance.currentUser?.uid ?? '';

  void _open(AppNotification n) {
    NotificationService.instance.markRead(n.id);
    // Forum reply/reaction notifications deep-link into the thread.
    if ((n.type == AppNotificationType.forumReply ||
            n.type == AppNotificationType.forumReaction) &&
        n.targetId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ForumPostDetailScreen(postId: n.targetId!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => NotificationService.instance.markAllRead(_uid),
            child: const Text('Mark all read',
                style: TextStyle(color: AppColors.onAccent, fontSize: 12.5)),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: NotificationService.instance,
        builder: (context, _) {
          final items = NotificationService.instance.forUser(_uid);
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 54, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text("You're all caught up!",
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Replies and reactions to your posts show up here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) => _tile(items[i]),
          );
        },
      ),
    );
  }

  Widget _tile(AppNotification n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        color: n.read
            ? AppColors.neutralLight
            : AppColors.surfaceTint.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(14),
        onTap: () => _open(n),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: n.type.color.withValues(alpha: 0.15),
              child: Icon(n.type.icon, color: n.type.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.3)),
                  const SizedBox(height: 4),
                  Text(_stamp(n.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (!n.read)
              Container(
                margin: const EdgeInsets.only(left: 6, top: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _stamp(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays >= 1) return DateFormat('MMM d · h:mm a').format(t);
    return timeAgo(t);
  }
}
