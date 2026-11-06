import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../services/forum_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/report_dialog.dart';
import '../widgets/rich_post_text.dart';
import '../widgets/soft_card.dart';
import 'forum_composer_screen.dart';
import 'forum_post_detail_screen.dart';

/// Screen 10 — Community Forum: a Facebook-style feed. Search + "Write Post",
/// Latest/Trending toggle, and post cards with media, reactions and comments.
class CommunityForumScreen extends StatefulWidget {
  const CommunityForumScreen({super.key});

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  int _tab = 0; // 0 = Latest, 1 = Trending
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterByHashtag(String tag) {
    setState(() {
      _searchCtrl.text = '#$tag';
      _query = '#${tag.toLowerCase()}';
    });
  }

  void _openThread(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ForumPostDetailScreen(postId: postId)),
    );
  }

  void _writePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForumComposerScreen()),
    );
  }

  Future<void> _react(ForumPost post) async {
    final chosen = await showReactionPicker(context, current: post.myReaction);
    if (chosen == null) return;
    ForumService.instance.setReaction(post.id, chosen);
  }

  Future<void> _report(ForumPost post) async {
    final reason = await showReportReasonSheet(context, subject: 'this post');
    if (reason == null) return;
    ForumService.instance.reportPost(post.id, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reported for "$reason". Thanks for flagging this.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: Column(
        children: [
          // Search bar + Write Post pill.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search posts or #hashtags...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.secondary),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _query = '';
                              }),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _writePost,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Write Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _toggle('Latest', 0),
                const SizedBox(width: 12),
                _toggle('Trending', 1),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ForumPost>>(
              stream: ForumService.instance.stream,
              initialData: ForumService.instance.current,
              builder: (context, snapshot) {
                var posts = List<ForumPost>.from(snapshot.data ?? const []);
                if (_query.isNotEmpty) {
                  posts = posts
                      .where((p) =>
                          p.body.toLowerCase().contains(_query) ||
                          p.author.toLowerCase().contains(_query))
                      .toList();
                }
                if (_tab == 1) {
                  // Trending = most reactions + comments.
                  posts.sort((a, b) => (b.reactionCount + b.commentCount)
                      .compareTo(a.reactionCount + a.commentCount));
                }
                if (posts.isEmpty) {
                  return Center(
                    child: Text('No posts yet.',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: posts.length,
                  itemBuilder: (context, i) => _postCard(posts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(ForumPost post) {
    final my = post.myReaction;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        onTap: () => _openThread(post.id),
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
                IconButton(
                  icon: Icon(Icons.flag_outlined,
                      size: 20, color: AppColors.textMuted),
                  tooltip: 'Report',
                  onPressed: () => _report(post),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (post.body.isNotEmpty)
              RichPostText(post.body, onHashtagTap: _filterByHashtag),
            if (post.hasMedia) ...[
              const SizedBox(height: 10),
              ForumMedia(imageURL: post.imageURL, videoURL: post.videoURL),
            ],
            ReactionSummary(post: post),
            const Divider(height: 6),
            Row(
              children: [
                Expanded(
                  child: _action(
                    icon: my != null ? null : Icons.thumb_up_alt_outlined,
                    emoji: my?.emoji,
                    label: my?.label ?? 'React',
                    color: my?.color ?? AppColors.textMuted,
                    onTap: () => _react(post),
                  ),
                ),
                Expanded(
                  child: _action(
                    icon: Icons.mode_comment_outlined,
                    label: 'Comment',
                    color: AppColors.textMuted,
                    onTap: () => _openThread(post.id),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _toggle(String label, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
