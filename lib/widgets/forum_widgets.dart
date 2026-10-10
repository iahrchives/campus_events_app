import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../theme/theme.dart';
import 'item_image.dart';

/// Compact "time ago" label (e.g. "2h", "3d").
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${(d.inDays / 7).floor()}w';
}

/// Displays a post's attached photo or a video placeholder.
class ForumMedia extends StatelessWidget {
  final String? imageURL;
  final String? videoURL;

  const ForumMedia({super.key, this.imageURL, this.videoURL});

  @override
  Widget build(BuildContext context) {
    if (videoURL != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black87),
              const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 56),
              ),
              const Positioned(
                left: 10,
                bottom: 8,
                child: Row(
                  children: [
                    Icon(Icons.videocam, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text('Video attachment',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (imageURL != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ItemImage(source: imageURL, fallbackIcon: Icons.image),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Summary row showing the top reaction emojis + total count, and comments.
class ReactionSummary extends StatelessWidget {
  final ForumPost post;
  const ReactionSummary({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final tops = post.topReactions;
    if (post.reactionCount == 0 && post.commentCount == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (tops.isNotEmpty) ...[
            Text(tops.map((r) => r.emoji).join(),
                style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text('${post.reactionCount}',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.textMuted)),
          ],
          const Spacer(),
          if (post.commentCount > 0)
            Text(
                '${post.commentCount} '
                '${post.commentCount == 1 ? "comment" : "comments"}',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Shows the Facebook-style reaction chooser as a bottom sheet and returns
/// the chosen reaction. Returns the same reaction to toggle it off, or null
/// only if dismissed.
Future<ReactionType?> showReactionPicker(
  BuildContext context, {
  ReactionType? current,
}) {
  return showModalBottomSheet<ReactionType>(
    context: context,
    backgroundColor: AppColors.neutralLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('React',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.textDark)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ReactionType.values.map((r) {
                final selected = r == current;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(ctx, r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.surfaceTint.withValues(alpha: 0.7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(r.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 2),
                        Text(r.label,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}
