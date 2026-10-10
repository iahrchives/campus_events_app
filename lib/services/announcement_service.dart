import 'dart:async';

import '../models/announcement.dart';

/// Mock store for announcements + pending publish requests.
///
/// Mirrors a Firestore layout (`Announcements` and `AnnouncementRequests`
/// collections) so swapping to Firebase only changes the data source.
class AnnouncementService {
  AnnouncementService._() {
    _annCtrl = StreamController<List<Announcement>>.broadcast(
      onListen: () => _annCtrl.add(List.unmodifiable(_announcements)),
    );
    _reqCtrl = StreamController<List<AnnouncementRequest>>.broadcast(
      onListen: () => _reqCtrl.add(List.unmodifiable(_requests)),
    );
  }
  static final AnnouncementService instance = AnnouncementService._();

  late final StreamController<List<Announcement>> _annCtrl;
  late final StreamController<List<AnnouncementRequest>> _reqCtrl;

  final List<Announcement> _announcements = [
    Announcement(
      id: 'a1',
      title: 'Enrollment for the new semester is now open',
      body:
          'Visit the registrar portal to enlist your subjects. Deadline is '
          'June 30. Late enrollment incurs additional fees.',
      authorId: 'uid_admin_000',
      authorName: 'Campus Admin',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Announcement(
      id: 'a2',
      title: 'Campus-wide maintenance this weekend',
      body:
          'Water and power interruptions are scheduled Saturday 8 AM–12 NN '
          'across the Engineering and Science buildings.',
      authorId: 'uid_admin_000',
      authorName: 'Campus Admin',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<AnnouncementRequest> _requests = [];

  // ---- Announcements ----
  Stream<List<Announcement>> get stream => _annCtrl.stream;
  List<Announcement> get current => List.unmodifiable(_announcements);

  Announcement? byId(String id) {
    for (final a in _announcements) {
      if (a.id == id) return a;
    }
    return null;
  }

  Announcement? get latest =>
      _announcements.isEmpty ? null : _announcements.first;

  Future<void> postAnnouncement({
    required String title,
    required String body,
    required String authorId,
    required String authorName,
    String? requestedBy,
    String? imageURL,
    String? videoURL,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _announcements.insert(
      0,
      Announcement(
        id: 'a_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        authorId: authorId,
        authorName: authorName,
        requestedBy: requestedBy,
        imageURL: imageURL,
        videoURL: videoURL,
      ),
    );
    _annCtrl.add(List.unmodifiable(_announcements));
  }

  Future<void> deleteAnnouncement(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _announcements.removeWhere((a) => a.id == id);
    _annCtrl.add(List.unmodifiable(_announcements));
  }

  // ---- Requests ----
  Stream<List<AnnouncementRequest>> get requestStream => _reqCtrl.stream;
  List<AnnouncementRequest> get requests => List.unmodifiable(_requests);
  int get pendingCount =>
      _requests.where((r) => r.status == RequestStatus.pending).length;

  Future<void> submitRequest({
    required String requesterId,
    required String requesterName,
    required String title,
    required String body,
    String? imageURL,
    String? videoURL,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _requests.insert(
      0,
      AnnouncementRequest(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        requesterId: requesterId,
        requesterName: requesterName,
        title: title,
        body: body,
        imageURL: imageURL,
        videoURL: videoURL,
      ),
    );
    _reqCtrl.add(List.unmodifiable(_requests));
  }

  /// Admin approves a request → publishes it as an announcement.
  Future<void> approveRequest({
    required String requestId,
    required String adminId,
    required String adminName,
  }) async {
    final req = _requests.firstWhere((r) => r.id == requestId);
    req.status = RequestStatus.approved;
    _reqCtrl.add(List.unmodifiable(_requests));
    await postAnnouncement(
      title: req.title,
      body: req.body,
      authorId: adminId,
      authorName: adminName,
      requestedBy: req.requesterName,
      imageURL: req.imageURL,
      videoURL: req.videoURL,
    );
  }

  Future<void> declineRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _requests.firstWhere((r) => r.id == requestId).status =
        RequestStatus.declined;
    _reqCtrl.add(List.unmodifiable(_requests));
  }
}
