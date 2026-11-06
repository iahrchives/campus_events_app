import 'package:flutter/material.dart';

import '../models/campus_floors.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../theme/theme.dart';
import 'event_creation_form_screen.dart';

/// Screen 7 — Campus Map. Matches the wireframe: bold title, soft floor
/// dropdown, line-art floor plan, an "UPCOMING EVENTS" section header, and
/// event rows with stacked time/date/venue + a "Join Event" pill. FAB (+)
/// opens the event creation form.
class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  /// Neutral option that shows every venue/event regardless of floor.
  static const String _allFloors = 'All Floors';

  String _floor = _allFloors;
  List<String> get _floors => [_allFloors, ...CampusFloors.names];

  bool get _isAll => _floor == _allFloors;

  /// Venues to show for the current selection ('All Floors' = every venue).
  List<String> get _venues => _isAll
      ? [for (final f in CampusFloors.names) ...CampusFloors.venuesOf(f)]
      : CampusFloors.venuesOf(_floor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      floatingActionButton: Builder(builder: (context) {
        final isAdmin = AuthService.instance.isAdmin;
        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          icon: Icon(isAdmin ? Icons.add : Icons.edit_calendar_outlined),
          label: Text(isAdmin ? 'Create Event' : 'Request Event'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EventCreationFormScreen(isAdmin: isAdmin)),
          ),
        );
      }),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          // Bold screen title.
          const Text(
            'Campus Map',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Floor selector dropdown (surface tint).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                initialValue: _floor,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                dropdownColor: AppColors.neutralLight,
                borderRadius: BorderRadius.circular(AppRadii.field),
                style: TextStyle(
                    color: AppColors.textDark, fontWeight: FontWeight.w700),
                items: _floors
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _floor = v ?? _floor),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Black-and-white line-art floor plan placeholder.
          Container(
            height: 210,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neutralLight,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.surfaceTint, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: _FloorPlanPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Rooms & areas available on the selected floor.
          const Text(
            'ROOMS & AREAS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _venues
                .map((v) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                            color: AppColors.surfaceTint, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.meeting_room_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(v,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.textDark)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),

          // Section header.
          const Text(
            'UPCOMING EVENTS: Interweave Campus',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            _floor,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 14),

          // Floor-specific event list (events whose venue is on this floor).
          StreamBuilder<List<CampusEvent>>(
            stream: EventService.instance.stream,
            initialData: EventService.instance.current,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final venues = _venues;
              final events = (snapshot.data ?? const [])
                  .where((e) => _isAll || venues.contains(e.venue))
                  .toList();
              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                      child: Text(
                          _isAll
                              ? 'No events scheduled yet.'
                              : 'No events scheduled for this floor.',
                          style: TextStyle(color: AppColors.textMuted))),
                );
              }
              return Column(
                children: events
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _MapEventCard(
                            event: e,
                            onJoin: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Joined "${e.title}"')),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Event row card matching the wireframe — title with stacked time/date/venue
/// lines on the left and a solid primary "Join Event" pill on the right.
class _MapEventCard extends StatelessWidget {
  final CampusEvent event;
  final VoidCallback? onJoin;

  const _MapEventCard({required this.event, this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.surfaceTint, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                _line(event.time),
                _line(event.date),
                _line(event.venue),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              child: const Text('Join Event'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text,
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
      );
}

/// Black-and-white architectural line-art for the floor plan placeholder.
class _FloorPlanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Use brand tones so the blueprint stays visible in both light and dark.
    final wall = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final thin = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final w = size.width, h = size.height;

    // Outer perimeter.
    canvas.drawRect(Rect.fromLTWH(6, 6, w - 12, h - 12), wall);

    // Central room.
    final central = Rect.fromLTWH(w * 0.36, h * 0.34, w * 0.28, h * 0.32);
    canvas.drawRect(central, wall);

    // Left column of rooms.
    canvas.drawLine(Offset(6, h * 0.5), Offset(w * 0.36, h * 0.5), wall);
    canvas.drawLine(Offset(w * 0.18, 6), Offset(w * 0.18, h * 0.5), thin);

    // Right corridor + rooms.
    canvas.drawLine(Offset(w * 0.64, h * 0.34), Offset(w - 6, h * 0.34), wall);
    canvas.drawLine(Offset(w * 0.64, h * 0.66), Offset(w - 6, h * 0.66), wall);
    canvas.drawLine(Offset(w * 0.82, h * 0.34), Offset(w * 0.82, h - 6), thin);

    // Top + bottom partitions.
    canvas.drawLine(Offset(w * 0.36, 6), Offset(w * 0.36, h * 0.34), thin);
    canvas.drawLine(Offset(w * 0.64, 6), Offset(w * 0.64, h * 0.34), thin);
    canvas.drawLine(Offset(w * 0.5, h * 0.66), Offset(w * 0.5, h - 6), thin);

    // Stair hatch in the central room.
    for (var i = 0; i < 4; i++) {
      final y = central.top + 8 + i * (central.height - 16) / 3;
      canvas.drawLine(Offset(central.left + 6, y),
          Offset(central.right - 6, y), thin);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
