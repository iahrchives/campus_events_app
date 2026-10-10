import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

/// Mock authentication + profile service.
///
/// This emulates the Firebase Auth + Firestore `Users` flow so the app runs
/// with zero backend setup. The method shapes match the real Firebase calls
/// (see README → "Step 2: Backend Authentication") so switching is a drop-in.
///
/// Extends [ChangeNotifier] so the navigation shell + admin panel react to
/// verification approvals in real time.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserProfile? _current;
  UserProfile? get currentUser => _current;

  // In-memory "Users collection". Seeded with demo accounts covering every
  // verification state so the admin review panel has something to act on.
  final Map<String, _Account> _accounts = {
    'validated@campus.edu': _Account(
      password: 'password123',
      profile: const UserProfile(
        uid: 'uid_validated_001',
        schoolID: '02-19-1234',
        schoolEmail: 'validated@campus.edu',
        fullName: 'Maria Santos',
        isEnrolled: true,
        isValidated: true, // → full access
        verifyStatus: VerifyStatus.approved,
      ),
    ),
    'pending@campus.edu': _Account(
      password: 'password123',
      profile: const UserProfile(
        uid: 'uid_pending_002',
        schoolID: '02-20-5678',
        schoolEmail: 'pending@campus.edu',
        fullName: 'Juan Dela Cruz',
        isEnrolled: true,
        isValidated: false, // → restricted nav until approved
        verifyStatus: VerifyStatus.none,
      ),
    ),
    'review@campus.edu': _Account(
      password: 'password123',
      profile: const UserProfile(
        uid: 'uid_review_003',
        schoolID: '02-21-9012',
        schoolEmail: 'review@campus.edu',
        fullName: 'Andrea Cruz',
        isEnrolled: true,
        isValidated: false,
        verifyStatus: VerifyStatus.pending, // → awaiting admin yes/no
        verificationProof: 'assessment_andrea.jpg',
      ),
    ),
    'admin@campus.edu': _Account(
      password: 'password123',
      profile: const UserProfile(
        uid: 'uid_admin_000',
        schoolID: '00-00-0000',
        schoolEmail: 'admin@campus.edu',
        fullName: 'Campus Admin',
        username: 'admin',
        isEnrolled: true,
        isValidated: true,
        isAdmin: true, // → can delete anyone's posts / listings
        verifyStatus: VerifyStatus.approved,
      ),
    ),
  };

  /// Whether the current user may edit/delete content owned by [ownerId].
  /// True for the owner themselves, or for any admin.
  bool canModify(String? ownerId) {
    final user = _current;
    if (user == null) return false;
    return user.isAdmin || (ownerId != null && ownerId == user.uid);
  }

  bool get isAdmin => _current?.isAdmin ?? false;

  /// Whether the current user has full (verified) access.
  bool get isVerified => _current?.isVerified ?? false;

  /// Whether an account already exists for [email] (case-insensitive).
  bool emailExists(String email) =>
      _accounts.containsKey(email.trim().toLowerCase());

  /// All registered profiles (used by the admin verification panel).
  List<UserProfile> allProfiles() =>
      _accounts.values.map((a) => a.profile).toList();

  UserProfile? profileForUid(String uid) {
    for (final a in _accounts.values) {
      if (a.profile.uid == uid) return a.profile;
    }
    return null;
  }

  /// Display name for a uid, falling back to a generic label.
  String nameForUid(String uid) =>
      profileForUid(uid)?.fullName ?? 'Campus User';

  /// Replaces a stored profile (matched by email) and keeps [_current] in sync.
  void _saveProfile(UserProfile updated) {
    final key = updated.schoolEmail.toLowerCase();
    final existing = _accounts[key];
    if (existing != null) {
      _accounts[key] = _Account(password: existing.password, profile: updated);
    }
    if (_current?.uid == updated.uid) _current = updated;
    notifyListeners();
  }

  /// Current user submits a picture of their enrollment proof for review.
  void submitVerification(String proofPath) {
    final user = _current;
    if (user == null) return;
    _saveProfile(user.copyWith(
      verifyStatus: VerifyStatus.pending,
      verificationProof: proofPath,
      isValidated: false,
    ));
  }

  /// Admin decision on a submitted account: approve (yes) or reject (no).
  void setVerificationDecision(String uid, bool approved) {
    final profile = profileForUid(uid);
    if (profile == null) return;
    _saveProfile(profile.copyWith(
      verifyStatus:
          approved ? VerifyStatus.approved : VerifyStatus.rejected,
      isValidated: approved,
    ));
  }

  /// Emulates FirebaseAuth.createUserWithEmailAndPassword + Firestore write.
  ///
  /// Enrollment proof (a screenshot of the assessment form) is now collected
  /// during sign up. When a proof file is attached the profile is created as
  /// validated; without it the account stays pending (isValidated = false).
  Future<UserProfile> signUp({
    required String fullName,
    required String schoolEmail,
    required String schoolID,
    required String password,
    required String address,
    required String username,
    String? enrollmentProof,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700)); // network sim
    final key = schoolEmail.trim().toLowerCase();
    // Enforce a single account per email (case-insensitive, trimmed).
    if (_accounts.containsKey(key)) {
      throw AuthException('An account with this email already exists.');
    }
    final hasProof = enrollmentProof != null && enrollmentProof.isNotEmpty;
    final profile = UserProfile(
      uid: 'uid_${DateTime.now().millisecondsSinceEpoch}',
      schoolID: schoolID,
      schoolEmail: schoolEmail.trim(),
      fullName: fullName,
      username: username.trim(),
      isEnrolled: true,
      // New accounts start unverified — an admin must approve the proof.
      isValidated: false,
      verifyStatus: hasProof ? VerifyStatus.pending : VerifyStatus.none,
      verificationProof: enrollmentProof,
      // Sign up sets the initial handle without starting the cooldown, so a
      // typo can be fixed once; that first edit then starts the 24h timer.
    );
    _accounts[key] = _Account(password: password, profile: profile);
    _current = profile;
    notifyListeners();
    return profile;
  }

  /// Emulates FirebaseAuth.signInWithEmailAndPassword + Firestore profile fetch.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700)); // network sim
    final account = _accounts[email.toLowerCase()];
    if (account == null || account.password != password) {
      throw AuthException('Invalid email or password.');
    }
    _current = account.profile;
    notifyListeners();
    return account.profile;
  }

  /// Updates the current user's username, enforcing a 24-hour cooldown
  /// between changes. Throws [AuthException] if the cooldown is still active.
  void updateUsername(String newUsername) {
    final user = _current;
    if (user == null) return;
    if (!user.canChangeUsername) {
      throw AuthException(
          'You can change your username again in '
          '${formatCooldown(user.usernameCooldownRemaining)}.');
    }
    _saveProfile(user.copyWith(
      username: newUsername.trim(),
      usernameUpdatedAt: DateTime.now(),
    ));
  }

  /// Human-friendly "Hh Mm" formatting for a cooldown duration.
  static String formatCooldown(Duration d) {
    if (d <= Duration.zero) return 'a moment';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '${d.inSeconds}s';
  }

  /// Updates the current user's profile photo (local path or URL) and
  /// persists it back to the in-memory accounts store.
  void updatePhoto(String? path) {
    final user = _current;
    if (user == null) return;
    _saveProfile(user.copyWith(photoURL: path));
  }

  /// Updates the stored enrollment-proof image without changing review status.
  void updateVerificationProof(String proofPath) {
    final user = _current;
    if (user == null) return;
    _saveProfile(user.copyWith(verificationProof: proofPath));
  }

  /// Called after a successful enrollment-form upload to flip the flag.
  void markValidated() {
    final user = _current;
    if (user == null) return;
    _saveProfile(user.copyWith(
      isValidated: true,
      verifyStatus: VerifyStatus.approved,
    ));
  }

  void signOut() {
    _current = null;
    notifyListeners();
  }
}

class _Account {
  final String password;
  final UserProfile profile;
  _Account({required this.password, required this.profile});
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
