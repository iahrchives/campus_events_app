import 'dart:async';

import '../models/event.dart';

/// Mock events store exposing a broadcast [Stream] so screens can use
/// `StreamBuilder` exactly like they will with Firestore (see README → Step 3).
///
/// Events follow an admin-gated workflow: admins publish directly, while
/// regular (verified) users submit an [EventRequest] for an admin to approve.
class EventService {
  EventService._() {
    _controller = StreamController<List<CampusEvent>>.broadcast(
      onListen: () => _controller.add(List.unmodifiable(_events)),
    );
    _reqController = StreamController<List<EventRequest>>.broadcast(
      onListen: () => _reqController.add(List.unmodifiable(_requests)),
    );
  }
  static final EventService instance = EventService._();

  late final StreamController<List<CampusEvent>> _controller;
  late final StreamController<List<EventRequest>> _reqController;

  final List<CampusEvent> _events = [
    const CampusEvent(
      id: 'e1',
      title: 'Freshmen Orientation Week',
      description: 'Welcome assembly and campus tour for incoming students.',
      venue: 'Gymnasium (Left)',
      date: 'Jun 18, 2026',
      time: '9:00 AM',
      organizerID: 'uid_validated_001',
    ),
    const CampusEvent(
      id: 'e2',
      title: 'Tech & Innovation Fair',
      description: 'Showcase of capstone projects and startup pitches.',
      venue: 'AVR',
      date: 'Jun 22, 2026',
      time: '1:00 PM',
      organizerID: 'uid_validated_001',
    ),
    const CampusEvent(
      id: 'e3',
      title: 'Intramurals Opening',
      description: 'Parade of colors and opening ceremony of the sports week.',
      venue: 'Bleachers (Left)',
      date: 'Jun 25, 2026',
      time: '3:30 PM',
      organizerID: 'uid_pending_002',
    ),
    const CampusEvent(
      id: 'e4',
      title: 'Finals Study Hall',
      description: 'Quiet group study and tutoring sessions before finals.',
      venue: 'Library',
      date: 'Jun 27, 2026',
      time: '10:00 AM',
      organizerID: 'uid_validated_001',
    ),
    const CampusEvent(
      id: 'e5',
      title: 'Coffee & Careers Meetup',
      description: 'Casual networking with alumni over coffee.',
      venue: 'Cafe',
      date: 'Jun 28, 2026',
      time: '2:00 PM',
      organizerID: 'uid_pending_002',
    ),
    const CampusEvent(
      id: 'e6',
      title: 'Student Council Meeting',
      description: 'Monthly assembly of org representatives.',
      venue: 'Meeting Room 1',
      date: 'Jun 29, 2026',
      time: '4:00 PM',
      organizerID: 'uid_validated_001',
    ),
  ];

  final List<EventRequest> _requests = [];

  Stream<List<CampusEvent>> get stream => _controller.stream;
  List<CampusEvent> get current => List.unmodifiable(_events);

  /// Emulates FirebaseFirestore.instance.collection('Events').add(...).
  Future<void> addEvent(CampusEvent event) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _events.insert(0, event);
    _controller.add(List.unmodifiable(_events));
  }

  // ---- Event publish requests (regular users → admin approval) ----
  Stream<List<EventRequest>> get requestStream => _reqController.stream;
  List<EventRequest> get requests => List.unmodifiable(_requests);
  int get pendingCount =>
      _requests.where((r) => r.status == RequestStatus.pending).length;

  Future<void> submitRequest(EventRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _requests.insert(0, request);
    _reqController.add(List.unmodifiable(_requests));
  }

  /// Admin approves a request → publishes it as a real event.
  Future<void> approveRequest({
    required String requestId,
    required String adminId,
  }) async {
    final req = _requests.firstWhere((r) => r.id == requestId);
    req.status = RequestStatus.approved;
    _reqController.add(List.unmodifiable(_requests));
    await addEvent(CampusEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: req.title,
      description: req.description,
      venue: req.venue,
      date: req.date,
      time: req.time,
      organizerID: req.requesterId,
      imageURL: req.imageURL,
    ));
  }

  Future<void> declineRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _requests.firstWhere((r) => r.id == requestId).status =
        RequestStatus.declined;
    _reqController.add(List.unmodifiable(_requests));
  }
}
