import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/linkified_text.dart';
import '../widgets/soft_card.dart';

/// Full read view of a single announcement. Admins (or the author) can delete.
class AnnouncementDetailScreen extends StatelessWidget {
  final String announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  Future<void> _confirmDelete(BuildContext context, Announcement a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete announcement?'),
        content: Text('"${a.title}" will be removed for everyone.'),
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
    await AnnouncementService.instance.deleteAnnouncement(a.id);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Announcement deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Announcement')),
      body: StreamBuilder<List<Announcement>>(
        stream: AnnouncementService.instance.stream,
        initialData: AnnouncementService.instance.current,
        builder: (context, snapshot) {
          final a = AnnouncementService.instance.byId(announcementId);
          if (a == null) {
            return Center(
              child: Text('This announcement is no longer available.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          final canModify = AuthService.instance.canModify(a.authorId);
          final date = DateFormat('MMM d, y · h:mm a').format(a.createdAt);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Posted by ${a.authorName}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Text(date,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  if (canModify)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, a),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(a.title,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark)),
              if (a.hasMedia) ...[
                const SizedBox(height: 14),
                ForumMedia(imageURL: a.imageURL, videoURL: a.videoURL),
              ],
              const SizedBox(height: 12),
              LinkifiedText(a.body),
              if (a.requestedBy != null) ...[
                const SizedBox(height: 20),
                SoftCard(
                  color: AppColors.surfaceTint.withValues(alpha: 0.4),
                  child: Text('Requested by ${a.requestedBy}',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
