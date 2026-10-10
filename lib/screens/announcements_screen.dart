import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/soft_card.dart';
import 'announcement_composer_screen.dart';
import 'announcement_detail_screen.dart';
import 'announcement_requests_screen.dart';

/// Announcements board. Admins can post directly; regular users can submit a
/// request for an admin to publish on their behalf.
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  void _open(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcementId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.isAdmin;
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          if (isAdmin)
            // Pending-requests inbox with a live badge.
            StreamBuilder<List<AnnouncementRequest>>(
              stream: AnnouncementService.instance.requestStream,
              initialData: AnnouncementService.instance.requests,
              builder: (context, snapshot) {
                final pending = (snapshot.data ?? const [])
                    .where((r) => r.status == RequestStatus.pending)
                    .length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.inbox_outlined),
                      tooltip: 'Requests',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AnnouncementRequestsScreen()),
                      ),
                    ),
                    if (pending > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                              color: AppColors.danger, shape: BoxShape.circle),
                          child: Text('$pending',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: Icon(isAdmin ? Icons.campaign : Icons.edit_note),
        label: Text(isAdmin ? 'Post' : 'Request'),
        onPressed: () => _compose(context, isAdmin),
      ),
      body: Column(
        children: [
          if (!isAdmin) _userNotice(),
          Expanded(
            child: StreamBuilder<List<Announcement>>(
              stream: AnnouncementService.instance.stream,
              initialData: AnnouncementService.instance.current,
              builder: (context, snapshot) {
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return Center(
                    child: Text('No announcements yet.',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _card(context, items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _userNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Only admins can post announcements. Tap “Request” to ask an '
              'admin to publish one for you.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Announcement a) {
    final date = DateFormat('MMM d · h:mm a').format(a.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        onTap: () => _open(context, a.id),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.campaign_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(a.brief,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textMuted, height: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (a.hasMedia) ...[
                        Icon(
                            a.videoURL != null
                                ? Icons.videocam_outlined
                                : Icons.image_outlined,
                            size: 14,
                            color: AppColors.secondary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text('${a.authorName} · $date',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _compose(BuildContext context, bool isAdmin) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AnnouncementComposerScreen(isAdmin: isAdmin)),
    );
  }
}
