import 'package:flutter_test/flutter_test.dart';

import 'package:campus_events_app/models/event.dart';
import 'package:campus_events_app/services/event_service.dart';
import 'package:campus_events_app/services/notification_service.dart';

void main() {
  final events = EventService.instance;
  final notifications = NotificationService.instance;

  EventRequest requestFor(String id, String uid) => EventRequest(
        id: id,
        requesterId: uid,
        requesterName: 'Organizer',
        title: 'Robotics Meetup $id',
        description: 'Annual robotics showcase.',
        venue: 'AVR',
        date: 'Jul 1, 2026',
        time: '10:00 AM',
      );

  test('approving a room reservation notifies the organizer', () async {
    const uid = 'pbi11_organizer_approved';
    notifications.clearFor(uid);
    addTearDown(() => notifications.clearFor(uid));

    final req = requestFor('pbi11_req_approved', uid);
    await events.submitRequest(req);
    await events.approveRequest(requestId: req.id, adminId: 'uid_admin_000');

    final notes = notifications.forUser(uid);
    expect(notes, isNotEmpty);

    final note = notes.first;
    expect(note.type, AppNotificationType.eventApproved);
    expect(note.title, 'Room reservation approved');
    expect(note.body, contains(req.title));
    expect(note.body, contains('AVR'));
    expect(note.body, contains('approved'));
  });

  test('rejecting a room reservation notifies the organizer', () async {
    const uid = 'pbi11_organizer_rejected';
    notifications.clearFor(uid);
    addTearDown(() => notifications.clearFor(uid));

    final req = requestFor('pbi11_req_rejected', uid);
    await events.submitRequest(req);
    await events.declineRequest(req.id);

    final notes = notifications.forUser(uid);
    expect(notes, isNotEmpty);

    final note = notes.first;
    expect(note.type, AppNotificationType.eventRejected);
    expect(note.title, 'Room reservation rejected');
    expect(note.body, contains(req.title));
    expect(note.body, contains('not approved'));
  });
}
