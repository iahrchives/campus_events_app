import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Mock store for announcements + pending publish requests.
///
/// Mirrors a Firestore layout (`Announcements` and `AnnouncementRequests`
/// collections) so swapping to Firebase only changes the data source.
class AnnouncementService extends ChangeNotifier {
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

  /// PBI-10: Tracks which emergency announcement IDs each user has dismissed.
  final Map<String, Set<String>> _dismissedEmergencies = {};

  final List<Announcement> _announcements = [
    Announcement(
      id: 'a1',
      title: 'Enrollment for the new semester is now open',
      body:
      'Visit the registrar portal to enlist your subjects. Deadline is '
          'June 30. Late enrollment incurs additional fees.',
      authorId: 'uid_admin_000',
      authorName: 'Campus Admin',
      priority: AnnouncementPriority.normal,
      category: 'General',
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
      priority: AnnouncementPriority.urgent,
      category: 'Facility Advisory',
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

  /// PBI-10: Returns the newest active high-priority emergency alert that
  /// [uid] has not yet tapped or dismissed.
  Announcement? activeEmergencyFor(String uid) {
    final dismissed = _dismissedEmergencies[uid] ?? const <String>{};
    for (final a in _announcements) {
      if (a.isEmergency && !dismissed.contains(a.id)) {
        return a;
      }
    }
    return null;
  }

  /// PBI-10: Marks an emergency banner as dismissed/acknowledged for [uid].
  void dismissEmergency(String uid, String announcementId) {
    if (uid.isEmpty) return;
    _dismissedEmergencies
        .putIfAbsent(uid, () => <String>{})
        .add(announcementId);
    notifyListeners();
  }

  Future<void> postAnnouncement({
    required String title,
    required String body,
    required String authorId,
    required String authorName,
    AnnouncementPriority priority = AnnouncementPriority.normal,
    String category = 'General',
    String? requestedBy,
    String? imageURL,
    String? videoURL,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final created = Announcement(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      authorId: authorId,
      authorName: authorName,
      priority: priority,
      category: category,
      requestedBy: requestedBy,
      imageURL: imageURL,
      videoURL: videoURL,
    );
    _announcements.insert(0, created);
    _annCtrl.add(List.unmodifiable(_announcements));

    // PBI-9: Push campus-wide notification to all users when urgent/emergency.
    if (priority != AnnouncementPriority.normal) {
      final prefix = priority == AnnouncementPriority.emergency
          ? '🚨 EMERGENCY ALERT'
          : '⚠️ URGENT';
      for (final profile in AuthService.instance.allProfiles()) {
        if (profile.uid == authorId) continue;
        NotificationService.instance.push(
          userId: profile.uid,
          type: AppNotificationType.announcement,
          title: '$prefix: $title',
          body: created.brief,
          targetId: created.id,
        );
      }
    }

    notifyListeners();
  }

  Future<void> deleteAnnouncement(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _announcements.removeWhere((a) => a.id == id);
    _annCtrl.add(List.unmodifiable(_announcements));
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
  }
}