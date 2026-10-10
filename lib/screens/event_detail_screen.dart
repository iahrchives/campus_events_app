import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/pill_button.dart';
import '../widgets/soft_card.dart';

/// Detail view for a single event, opened from the dashboard billboard or any
/// event card.
class EventDetailScreen extends StatelessWidget {
  final CampusEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Event Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero banner — the event's theme photo, or a gradient placeholder.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: event.imageURL != null
                  ? ItemImage(
                      source: event.imageURL,
                      fallbackIcon: Icons.celebration_outlined)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.secondary, AppColors.primary],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.celebration_outlined,
                            size: 90, color: Colors.white24),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            event.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              children: [
                _row(Icons.calendar_today_outlined, 'Date', event.date),
                const Divider(height: 22),
                _row(Icons.access_time, 'Time', event.time),
                const Divider(height: 22),
                _row(Icons.place_outlined, 'Venue', event.venue),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('About this event',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(
            event.description.isEmpty
                ? 'No description provided for this event.'
                : event.description,
            style: TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 30),
          PillButton(
            label: 'Join Event',
            icon: Icons.check_circle_outline,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined "${event.title}"')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 22),
        const SizedBox(width: 14),
        Text('$label:',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
