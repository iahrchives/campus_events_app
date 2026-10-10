import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/soft_card.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

/// Unified inbox: admin broadcasts + private buyer↔seller marketplace chats.
/// Opened from the nav drawer Messages tab.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String get _uid => AuthService.instance.currentUser?.uid ?? '';
  bool get _isAdmin => AuthService.instance.isAdmin;

  Future<void> _composeBroadcast() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.neutralLight,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Message everyone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This message is delivered to every campus user as a broadcast.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Type your message…'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send to all'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    final admin = AuthService.instance.currentUser;
    ChatService.instance.sendBroadcast(admin?.fullName ?? 'Campus Admin', text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent to all users.')));
  }

  void _openConversation(Conversation c) {
    ChatService.instance.markConversationRead(c.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: c)),
    );
  }

  void _openBroadcasts() {
    ChatService.instance.markBroadcastsRead();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _BroadcastThreadScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Message all'),
              onPressed: _composeBroadcast,
            )
          : null,
      body: AnimatedBuilder(
        animation: ChatService.instance,
        builder: (context, _) {
          final convos = ChatService.instance.conversationsFor(_uid);
          final hasBroadcasts = ChatService.instance.hasBroadcasts;
          if (!hasBroadcasts && convos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forum_outlined,
                        size: 54, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('No messages yet',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        'Message a seller from a marketplace listing to start '
                        'a conversation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hasBroadcasts) _broadcastTile(),
              ...convos.map(_conversationTile),
            ],
          );
        },
      ),
    );
  }

  Widget _broadcastTile() {
    final latest = ChatService.instance.latestBroadcast;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        color: AppColors.surfaceTint.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(14),
        onTap: _openBroadcasts,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.campaign, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campus Announcements',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(latest?.text ?? 'Broadcast messages from admins',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _conversationTile(Conversation c) {
    final otherId = c.otherParty(_uid);
    final otherName = AuthService.instance.nameForUid(otherId);
    final otherPhoto = AuthService.instance.profileForUid(otherId)?.photoURL;
    final last = c.messages.isEmpty ? null : c.messages.last;
    final preview = last == null
        ? 'No messages yet'
        : '${last.senderId == _uid ? "You: " : ""}${last.text}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        onTap: () => _openConversation(c),
        child: Row(
          children: [
            UserAvatar(photoURL: otherPhoto, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(otherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark)),
                      ),
                      if (last != null)
                        Text(timeAgo(last.sentAt),
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Re: ${c.itemTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only list of admin broadcast messages, newest at the bottom.
class _BroadcastThreadScreen extends StatelessWidget {
  const _BroadcastThreadScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Campus Announcements')),
      body: AnimatedBuilder(
        animation: ChatService.instance,
        builder: (context, _) {
          final items = ChatService.instance.broadcasts.reversed.toList();
          if (items.isEmpty) {
            return Center(
              child: Text('No broadcasts yet.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final b = items[i];
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(b.senderName,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(b.text,
                          style: TextStyle(
                              color: AppColors.textDark, height: 1.35)),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM d · h:mm a').format(b.sentAt),
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
