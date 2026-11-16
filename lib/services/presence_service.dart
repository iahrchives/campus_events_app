import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Mock presence tracker (mirrors a Firestore `Presence` collection).
///
/// Marks the signed-in account online and records when everyone else was last
/// seen. Because the demo runs one account per device, peers realistically show
/// as "Last seen …" once they sign out; the online state is still supported for
/// when a peer session is genuinely active (e.g. a second app instance).
///
/// Each user may hide their own activity through the Active Status privacy
/// toggle. The raw [isOnline] flag stays accurate for delivery handling; use
/// [canShowStatus] before surfacing presence in the UI.
class PresenceService extends ChangeNotifier {
  PresenceService._() {
    _syncWithAuth();
    AuthService.instance.addListener(_syncWithAuth);
  }

  static final PresenceService instance = PresenceService._();

  final Set<String> _online = <String>{};
  final Map<String, DateTime> _lastSeen = <String, DateTime>{};
  final Map<String, bool> _activeStatusEnabled = <String, bool>{};
  String? _trackedUid;

  /// Uids with an active session right now.
  List<String> get onlineUids => List.unmodifiable(_online);

  /// Whether [uid] currently has an active session (privacy-independent).
  bool isOnline(String uid) => _online.contains(uid);

  /// When [uid] was last active, or null if never seen.
  DateTime? lastSeenFor(String uid) => _lastSeen[uid];

  /// Whether [uid] allows others to see their active status.
  bool activeStatusEnabledFor(String uid) =>
      _activeStatusEnabled[uid] ?? true;

  /// Convenience for the UI: may presence be shown for [uid] at all?
  bool canShowStatus(String uid) => activeStatusEnabledFor(uid);

  /// Marks [uid] as online; refreshes their last-seen timestamp.
  void markOnline(String uid) {
    if (uid.isEmpty) return;
    final appeared = _online.add(uid);
    _lastSeen[uid] = DateTime.now();
    if (appeared) notifyListeners();
  }

  /// Marks [uid] as offline and records the moment they left.
  void markOffline(String uid) {
    if (uid.isEmpty) return;
    final disappeared = _online.remove(uid);
    _lastSeen[uid] = DateTime.now();
    if (disappeared) notifyListeners();
  }

  /// Updates [uid]'s Active Status privacy preference.
  void setActiveStatusEnabled(String uid, bool enabled) {
    if (uid.isEmpty) return;
    if (activeStatusEnabledFor(uid) == enabled) return;
    _activeStatusEnabled[uid] = enabled;
    notifyListeners();
  }

  void _syncWithAuth() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == _trackedUid) return;

    final previous = _trackedUid;
    _trackedUid = uid;

    if (previous != null && previous.isNotEmpty) {
      markOffline(previous);
    }
    if (uid != null && uid.isNotEmpty) {
      markOnline(uid);
    } else {
      notifyListeners();
    }
  }
}
