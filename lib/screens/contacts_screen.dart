import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/theme.dart';
import '../widgets/contact_actions.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/soft_card.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

/// Lists everyone the current user has a direct-message thread with, plus a blocked section. Contacts can be reported, removed or blocked from here.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  String get _uid => AuthService.instance.currentUser?.uid ?? '';

  void _openChat(BuildContext context, Contact contact) {
    final convo = contact.latest;
    ChatService.instance.markConversationRead(convo.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
    );
  }

  Future<void> _handleAction(
    BuildContext context, {
    required String uid,
    required String name,
    required String conversationId,
    required String action,
  }) async {
    switch (action) {
      case 'report':
        await reportContactFlow(
          context,
          uid: uid,
          name: name,
          conversationId: conversationId,
        );
        break;
      case 'remove':
        await confirmRemoveContact(context, uid: uid, name: name);
        break;
      case 'block':
        await confirmBlockContact(context, uid: uid, name: name);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Contacts')),
      body: AnimatedBuilder(
        animation: ChatService.instance,
        builder: (context, _) {
          final contacts = ChatService.instance.contactsFor(_uid);
          final blocked = ChatService.instance.blockedContactsFor(_uid);
          if (contacts.isEmpty && blocked.isEmpty) return _emptyState();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _section('Contacts (${contacts.length})'),
              if (contacts.isEmpty)
                _muted('No active contacts. Message a seller from a marketplace '
                    'listing to start a conversation.')
              else
                ...contacts.map((c) => _contactTile(context, c)),
              if (blocked.isNotEmpty) ...[
                const SizedBox(height: 18),
                _section('Blocked (${blocked.length})'),
                ...blocked.map((uid) => _blockedTile(context, uid)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _contactTile(BuildContext context, Contact contact) {
    final profile = AuthService.instance.profileForUid(contact.uid);
    final name = profile?.fullName ?? 'Campus User';
    final latest = contact.latest;
    final preview = latest.messages.isEmpty
        ? 'No messages yet'
        : latest.messages.last.text;
    final activity = contact.lastActivity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        onTap: () => _openChat(context, contact),
        child: Row(
          children: [
            UserAvatar(photoURL: profile?.photoURL, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (activity != null)
                        Text(
                          timeAgo(activity),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${profile?.handle ?? 'campus'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Contact options',
              icon: Icon(Icons.more_vert, color: AppColors.textMuted),
              onSelected: (action) => _handleAction(
                context,
                uid: contact.uid,
                name: name,
                conversationId: latest.id,
                action: action,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report contact')),
                PopupMenuItem(value: 'remove', child: Text('Remove contact')),
                PopupMenuItem(value: 'block', child: Text('Block contact')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockedTile(BuildContext context, String uid) {
    final profile = AuthService.instance.profileForUid(uid);
    final name = profile?.fullName ?? 'Campus User';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        color: AppColors.surfaceTint.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            UserAvatar(photoURL: profile?.photoURL, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Blocked',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ChatService.instance.unblockContact(_uid, uid);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$name unblocked.'),
                ));
              },
              child: const Text('Unblock'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            letterSpacing: 0.6,
            color: AppColors.primary,
          ),
        ),
      );

  Widget _muted(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          text,
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
      );

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.contacts_outlined,
                  size: 54, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No contacts yet',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Message a seller from a marketplace listing to start a '
                'conversation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
}
