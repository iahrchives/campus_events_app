import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/soft_card.dart';
import 'event_creation_form_screen.dart';
import 'event_detail_screen.dart';
import 'event_requests_screen.dart';

/// Dedicated Events tab — a searchable list of every upcoming campus event,
/// independent of the floor filtering used on the Campus Map.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.isAdmin;
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        actions: [
          if (isAdmin)
            // Pending event-request inbox with a live badge (admins only).
            StreamBuilder<List<EventRequest>>(
              stream: EventService.instance.requestStream,
              initialData: EventService.instance.requests,
              builder: (context, snapshot) {
                final pending = (snapshot.data ?? const [])
                    .where((r) => r.status == RequestStatus.pending)
                    .length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.inbox_outlined),
                      tooltip: 'Event requests',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EventRequestsScreen()),
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
        icon: Icon(isAdmin ? Icons.add : Icons.edit_calendar_outlined),
        label: Text(isAdmin ? 'Create Event' : 'Request Event'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventCreationFormScreen(isAdmin: isAdmin)),
        ),
      ),
      body: Column(
        children: [
          if (!isAdmin) _requestNotice(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search events...',
                prefixIcon: Icon(Icons.search, color: AppColors.secondary),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CampusEvent>>(
              stream: EventService.instance.stream,
              initialData: EventService.instance.current,
              builder: (context, snapshot) {
                final all = snapshot.data ?? const [];
                final events = all.where((e) {
                  if (_query.isEmpty) return true;
                  return e.title.toLowerCase().contains(_query) ||
                      e.venue.toLowerCase().contains(_query) ||
                      e.description.toLowerCase().contains(_query);
                }).toList();

                if (events.isEmpty) {
                  return Center(
                    child: Text('No events found.',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: events.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _eventCard(events[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestNotice() {
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
              'Only admins can publish events. Tap “Request Event” to send '
              'your event to an admin for approval.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(CampusEvent e) {
    return SoftCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: e)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 58,
              width: 58,
              child: e.imageURL != null
                  ? ItemImage(
                      source: e.imageURL,
                      fallbackIcon: Icons.celebration_outlined)
                  : Container(
                      color: AppColors.surfaceTint,
                      alignment: Alignment.center,
                      child: const Icon(Icons.celebration_outlined,
                          color: AppColors.primary, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: AppColors.textDark)),
                const SizedBox(height: 4),
                _meta(Icons.schedule, '${e.date} · ${e.time}'),
                const SizedBox(height: 2),
                _meta(Icons.place_outlined, e.venue),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined "${e.title}"')),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                textStyle:
                    const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              child: const Text('Join'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
