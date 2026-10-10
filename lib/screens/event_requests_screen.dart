import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/soft_card.dart';

/// Admin-only inbox of user requests to publish campus events. Approving a
/// request publishes it as a real event; declining keeps it off the board.
class EventRequestsScreen extends StatelessWidget {
  const EventRequestsScreen({super.key});

  Future<void> _approve(BuildContext context, EventRequest r) async {
    final admin = AuthService.instance.currentUser;
    await EventService.instance.approveRequest(
      requestId: r.id,
      adminId: admin?.uid ?? 'uid_admin',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved & published "${r.title}".')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Event Requests')),
      body: StreamBuilder<List<EventRequest>>(
        stream: EventService.instance.requestStream,
        initialData: EventService.instance.requests,
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const [];
          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No event requests yet.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, i) => _requestCard(context, requests[i]),
          );
        },
      ),
    );
  }

  Widget _requestCard(BuildContext context, EventRequest r) {
    final pending = r.status == RequestStatus.pending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 18, color: AppColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('From ${r.requesterName}',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted)),
                ),
                _statusChip(r.status),
              ],
            ),
            if (r.imageURL != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ItemImage(source: r.imageURL, fallbackIcon: Icons.event),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(r.title,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            _meta(Icons.calendar_today_outlined, '${r.date} · ${r.time}'),
            const SizedBox(height: 3),
            _meta(Icons.place_outlined, r.venue),
            const SizedBox(height: 8),
            Text(r.description,
                style: TextStyle(color: AppColors.textMuted, height: 1.4)),
            if (pending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(context, r),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve & Publish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.pill)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () =>
                        EventService.instance.declineRequest(r.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill)),
                    ),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _statusChip(RequestStatus status) {
    late final Color color;
    late final String label;
    switch (status) {
      case RequestStatus.pending:
        color = AppColors.secondary;
        label = 'Pending';
        break;
      case RequestStatus.approved:
        color = AppColors.success;
        label = 'Approved';
        break;
      case RequestStatus.declined:
        color = AppColors.danger;
        label = 'Declined';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
