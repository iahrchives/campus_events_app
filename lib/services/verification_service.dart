import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../models/verification.dart';
import 'announcement_service.dart';

/// Drives the per-semester re-verification cycle.
///
/// When an admin opens a drive, every (non-admin) student is asked to re-submit
/// their enrollment proof before the drive's id is recorded against them.
/// Mirrors a Firestore `VerificationDrives` collection + a `submissions` set.
class VerificationService extends ChangeNotifier {
  VerificationService._();
  static final VerificationService instance = VerificationService._();

  VerificationDrive? _activeDrive;
  VerificationDrive? get activeDrive => _activeDrive;

  /// Keys of the form 'uid:driveId' for students who already re-submitted.
  final Set<String> _submitted = {};

  bool get isActive => _activeDrive != null;

  /// Whether [user] still owes a re-submission for the active drive.
  bool needsResubmission(UserProfile? user) {
    final drive = _activeDrive;
    if (drive == null || user == null || user.isAdmin) return false;
    return !_submitted.contains('${user.uid}:${drive.id}');
  }

  /// Admin starts a new drive. Also auto-publishes an announcement so every
  /// student is notified.
  Future<void> startDrive({
    required Semester semester,
    required String schoolYear,
    required String message,
    required String adminId,
    required String adminName,
  }) async {
    final drive = VerificationDrive(
      id: 'vd_${DateTime.now().millisecondsSinceEpoch}',
      semester: semester,
      schoolYear: schoolYear,
      message: message,
      createdById: adminId,
      createdByName: adminName,
    );
    _activeDrive = drive;
    _submitted.removeWhere((k) => k.endsWith(':${drive.id}'));
    notifyListeners();

    await AnnouncementService.instance.postAnnouncement(
      title: 'Action required: ${drive.title}',
      body: message.trim().isEmpty
          ? 'A new semester has started. Please re-submit your enrollment '
              'assessment to keep your campus profile active.'
          : message.trim(),
      authorId: adminId,
      authorName: adminName,
    );
  }

  void endDrive() {
    _activeDrive = null;
    notifyListeners();
  }

  /// Records that [uid] re-submitted proof for the active drive.
  void markSubmitted(String uid) {
    final drive = _activeDrive;
    if (drive == null) return;
    _submitted.add('$uid:${drive.id}');
    notifyListeners();
  }

  bool hasSubmitted(String uid) {
    final drive = _activeDrive;
    if (drive == null) return false;
    return _submitted.contains('$uid:${drive.id}');
  }
}
