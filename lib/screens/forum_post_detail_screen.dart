import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../services/auth_service.dart';
import '../services/forum_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/report_dialog.dart';
import '../widgets/rich_post_text.dart';
import '../widgets/soft_card.dart';

/// Thread view for a single forum post: the post (with media + reactions),
/// its comments (each likeable / reportable), and a comment composer.
class ForumPostDetailScreen extends StatefulWidget {
  final String postId;

  const ForumPostDetailScreen({super.key, required this.postId});

  @override
  State<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<ForumPostDetailScreen> {
  final _comment = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final user = AuthService.instance.currentUser;
    await ForumService.instance.addComment(
      widget.postId,
      ForumComment(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        author: user?.fullName ?? 'You',
        authorId: user?.uid ?? '',
        body: text,
      ),
    );
    _comment.clear();
    if (!mounted) return;
    setState(() => _sending = false);
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _react() async {
    final post = ForumService.instance.byId(widget.postId);
    final chosen =
        await showReactionPicker(context, current: post?.myReaction);
    if (chosen == null) return;
    ForumService.instance.setReaction(widget.postId, chosen);
  }

  Future<void> _reactToComment(ForumComment c) async {
    final chosen = await showReactionPicker(context, current: c.myReaction);
    if (chosen == null) return;
    ForumService.instance.setCommentReaction(widget.postId, c.id, chosen);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete post?'),
        content: const Text('This post and its comments will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ForumService.instance.deletePost(widget.postId);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Post deleted.')));
  }

  Future<void> _confirmDeleteComment(ForumComment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete comment?'),
        content: const Text('This comment will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ForumService.instance.deleteComment(widget.postId, c.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Comment deleted.')));
  }

  Future<void> _report({String? commentId}) async {
    final reason = await showReportReasonSheet(
      context,
      subject: commentId == null ? 'this post' : 'this reply',
    );
    if (reason == null) return;
    if (commentId == null) {
      ForumService.instance.reportPost(widget.postId, reason: reason);
    } else {
      ForumService.instance.reportComment(widget.postId, commentId,
          reason: reason);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reported for "$reason". Thanks for flagging this.')));
  }

  @override
  Widget build(BuildContext context) {
    final post = ForumService.instance.byId(widget.postId);
    final canModify =
        post != null && AuthService.instance.canModify(post.authorId);
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') _confirmDelete();
              if (v == 'report') _report();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('Report post'),
                ]),
              ),
              if (canModify)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        size: 20, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text('Delete post',
                        style: TextStyle(color: AppColors.danger)),
                  ]),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ForumPost>>(
              stream: ForumService.instance.stream,
              initialData: ForumService.instance.current,
              builder: (context, snapshot) {
                final post = ForumService.instance.byId(widget.postId);
                if (post == null) {
                  return const Center(child: Text('Post not found.'));
                }
                return ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _postCard(post),
                    const SizedBox(height: 16),
                    Text(
                      '${post.commentCount} '
                      '${post.commentCount == 1 ? "Comment" : "Comments"}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    if (post.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No comments yet. Start the conversation!',
                            style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      ...post.comments.map(_commentTile),
                  ],
                );
              },
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _postCard(ForumPost post) {
    final my = post.myReaction;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceTint,
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    Text(timeAgo(post.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichPostText(post.body,
              style: TextStyle(color: AppColors.textDark, height: 1.5),
              onHashtagTap: (tag) => Navigator.pop(context)),
          if (post.hasMedia) ...[
            const SizedBox(height: 12),
            ForumMedia(imageURL: post.imageURL, videoURL: post.videoURL),
          ],
          const Divider(height: 22),
          ReactionSummary(post: post),
          const Divider(height: 8),
          Row(
            children: [
              Expanded(
                child: _action(
                  icon: my != null ? null : Icons.thumb_up_alt_outlined,
                  emoji: my?.emoji,
                  label: my?.label ?? 'React',
                  color: my?.color ?? AppColors.textMuted,
                  onTap: _react,
                ),
              ),
              Expanded(
                child: _action(
                  icon: Icons.mode_comment_outlined,
                  label: 'Comment',
                  color: AppColors.textMuted,
                  onTap: () => FocusScope.of(context).unfocus(),
                ),
              ),
              Expanded(
                child: _action(
                  icon: Icons.flag_outlined,
                  label: 'Report',
                  color: AppColors.textMuted,
                  onTap: () => _report(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action({
    IconData? icon,
    String? emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 16))
            else if (icon != null)
              Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _commentTile(ForumComment c) {
    final canDelete = AuthService.instance.canModify(c.authorId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceTint,
            child: const Icon(Icons.person, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.author,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(c.body,
                          style: TextStyle(
                              color: AppColors.textDark, height: 1.4)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: Row(
                    children: [
                      Text(timeAgo(c.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 14),
                      // Tap to react, long-press also opens the picker.
                      InkWell(
                        onTap: () => _reactToComment(c),
                        onLongPress: () => _reactToComment(c),
                        child: Row(
                          children: [
                            if (c.myReaction != null) ...[
                              Text(c.myReaction!.emoji,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              c.myReaction?.label ?? 'React',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.myReaction?.color ??
                                      AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () => _report(commentId: c.id),
                        child: Text('Report',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted)),
                      ),
                      if (canDelete) ...[
                        const SizedBox(width: 14),
                        InkWell(
                          onTap: () => _confirmDeleteComment(c),
                          child: const Text('Delete',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger)),
                        ),
                      ],
                      if (c.reactionCount > 0) ...[
                        const Spacer(),
                        Text(
                            c.topReactions.map((r) => r.emoji).join(),
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text('${c.reactionCount}',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).viewPadding.bottom),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        border: Border(top: BorderSide(color: AppColors.surfaceTint, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _comment,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _sending
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5)),
                )
              : IconButton.filled(
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(12)),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _sendComment,
                ),
        ],
      ),
    );
  }
}
