import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/theme.dart';
import '../widgets/contact_actions.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Duration _sendCooldown = Duration(seconds: 3);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  // PBI-3: Quick-Reply Canned Response Templates
  final List<String> _quickReplies = [
    'Is this still available?',
    'I am at the meetup spot',
    'Can we negotiate the price?',
    'What time are you available?',
    'Thank you!',
  ];

  @override
  void initState() {
    super.initState();
    ChatService.instance.markConversationRead(widget.conversation.id);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textToSend]) {
    final text = (textToSend ?? _controller.text).trim();
    if (text.isEmpty) return;

    if (_cooldownRemaining > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Please wait ${_cooldownRemaining}s before sending again.',
        ),
        duration: const Duration(seconds: 1),
      ));
      return;
    }

    final currentUid = AuthService.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    final sent = ChatService.instance.send(
      widget.conversation.id,
      currentUid,
      text,
    );
    if (!sent) return;

    if (textToSend == null) {
      _controller.clear();
    }
    _scrollToBottom();
    _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = _sendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownRemaining = 0);
      } else {
        setState(() => _cooldownRemaining -= 1);
      }
    });
  }

  Future<void> _handleContactAction(String action) async {
    final currentUid = AuthService.instance.currentUser?.uid ?? '';
    final otherUid = widget.conversation.otherParty(currentUid);
    final otherName = AuthService.instance.nameForUid(otherUid);

    ContactActionResult result;
    switch (action) {
      case 'report':
        result = await reportContactFlow(
          context,
          uid: otherUid,
          name: otherName,
          conversationId: widget.conversation.id,
        );
        break;
      case 'remove':
        result = await confirmRemoveContact(
          context,
          uid: otherUid,
          name: otherName,
        );
        break;
      case 'block':
        result = await confirmBlockContact(
          context,
          uid: otherUid,
          name: otherName,
        );
        break;
      default:
        return;
    }

    if (!mounted) return;
    if (result == ContactActionResult.removed ||
        result == ContactActionResult.blocked) {
      Navigator.pop(context);
    } else {
      setState(() {});
    }
  }

  void _unblock(String otherUid) {
    final currentUid = AuthService.instance.currentUser?.uid ?? '';
    ChatService.instance.unblockContact(currentUid, otherUid);
    setState(() {});
  }

  // PBI-3: Vertically stacked buttons (Pababa ang mga pagpipilian)
  Widget _buildQuickReplyBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.surfaceTint.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'QUICK REPLIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final replyText in _quickReplies)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: InkWell(
                onTap: () => _sendMessage(replyText),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.neutralLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.surfaceTint.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          replyText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final convo = widget.conversation;
    final currentUid = AuthService.instance.currentUser?.uid ?? '';
    final otherUid = convo.otherParty(currentUid);
    final otherName = AuthService.instance.nameForUid(otherUid);
    final otherPhoto = AuthService.instance.profileForUid(otherUid)?.photoURL;
    final blockedByMe = ChatService.instance.hasBlocked(currentUid, otherUid);
    final blockedMe = ChatService.instance.hasBlocked(otherUid, currentUid);
    final isBlocked = blockedByMe || blockedMe;

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        titleSpacing: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Contact options',
            icon: const Icon(Icons.more_vert),
            onSelected: _handleContactAction,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Report contact')),
              PopupMenuItem(value: 'remove', child: Text('Remove contact')),
              PopupMenuItem(value: 'block', child: Text('Block contact')),
            ],
          ),
        ],
        title: Row(
          children: [
            UserAvatar(
              radius: 16,
              photoURL: otherPhoto,
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (convo.itemTitle.isNotEmpty)
                    Text(
                      convo.itemTitle,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner sa itaas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a private chat between you and $otherName.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          if (isBlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.danger.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.block, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      blockedByMe
                          ? 'You blocked this contact. Unblock to continue messaging.'
                          : 'You can no longer message this contact.',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                  if (blockedByMe)
                    TextButton(
                      onPressed: () => _unblock(otherUid),
                      child: const Text('Unblock'),
                    ),
                ],
              ),
            ),

          // Message Thread Stream
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.instance.messages(convo.id),
              initialData: convo.messages,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Say hello to start the conversation about\n"${convo.itemTitle}".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (!isBlocked) ...[
            // PBI-3: Quick-Reply Bar (Naka-linya pababa)
            _buildQuickReplyBar(),

            // Input field bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                      color: AppColors.surfaceTint.withValues(alpha: 0.3)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                              fontSize: 14, color: AppColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          filled: true,
                          fillColor: AppColors.neutralLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: _cooldownRemaining > 0
                          ? 'Please wait ${_cooldownRemaining}s'
                          : 'Send',
                      icon: _cooldownRemaining > 0
                          ? Text(
                              '${_cooldownRemaining}s',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: AppColors.primary),
                      onPressed: _cooldownRemaining > 0
                          ? null
                          : () => _sendMessage(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
