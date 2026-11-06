/// Lifecycle of a user's enrollment-proof verification, reviewed by an admin.
enum VerifyStatus { none, pending, approved, rejected }

extension VerifyStatusX on VerifyStatus {
  String get label {
    switch (this) {
      case VerifyStatus.none:
        return 'Not submitted';
      case VerifyStatus.pending:
        return 'Pending review';
      case VerifyStatus.approved:
        return 'Approved';
      case VerifyStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Mock profile model used for the LLD security-routing logic.
///
/// Mirrors the Firestore `Users` document shape so the swap to Firebase
/// (see README) only changes the data source, not this template.
class UserProfile {
  final String uid;
  final String schoolID;
  final String schoolEmail;
  final String fullName;
  final bool isEnrolled;

  /// Editable handle. When empty, [handle] falls back to the email prefix.
  final String username;

  /// Drives the access-control rule: only validated profiles reach the
  /// dashboard; everyone else is redirected to enrollment verification.
  final bool isValidated;

  /// Admins may delete any post / listing, not just their own.
  final bool isAdmin;

  /// When the username was last changed. Used to enforce the 24-hour
  /// change cooldown. Null means it has never been changed since sign up.
  final DateTime? usernameUpdatedAt;

  /// Local path / URL of the user's profile photo (null = default avatar).
  final String? photoURL;

  /// Admin-reviewed enrollment verification state.
  final VerifyStatus verifyStatus;

  /// Local path / URL of the submitted enrollment-proof picture.
  final String? verificationProof;

  const UserProfile({
    required this.uid,
    required this.schoolID,
    required this.schoolEmail,
    required this.fullName,
    this.username = '',
    this.isEnrolled = true,
    this.isValidated = false,
    this.isAdmin = false,
    this.usernameUpdatedAt,
    this.photoURL,
    this.verifyStatus = VerifyStatus.none,
    this.verificationProof,
  });

  /// Whether the account has full access (admin approved the enrollment proof).
  bool get isVerified => isAdmin || verifyStatus == VerifyStatus.approved;

  /// How long the user must wait between username changes.
  static const Duration usernameCooldown = Duration(hours: 24);

  /// Username shown in the UI, with a sensible fallback.
  String get handle =>
      username.isNotEmpty ? username : schoolEmail.split('@').first;

  /// Earliest time the username may be changed again (null if no prior change).
  DateTime? get nextUsernameChange =>
      usernameUpdatedAt?.add(usernameCooldown);

  /// Whether the username can be changed right now.
  bool get canChangeUsername {
    final next = nextUsernameChange;
    return next == null || !DateTime.now().isBefore(next);
  }

  /// Remaining cooldown before the username can change again.
  Duration get usernameCooldownRemaining {
    final next = nextUsernameChange;
    if (next == null) return Duration.zero;
    final diff = next.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  UserProfile copyWith({
    bool? isValidated,
    bool? isEnrolled,
    String? username,
    bool? isAdmin,
    DateTime? usernameUpdatedAt,
    String? photoURL,
    VerifyStatus? verifyStatus,
    String? verificationProof,
  }) =>
      UserProfile(
        uid: uid,
        schoolID: schoolID,
        schoolEmail: schoolEmail,
        fullName: fullName,
        username: username ?? this.username,
        isEnrolled: isEnrolled ?? this.isEnrolled,
        isValidated: isValidated ?? this.isValidated,
        isAdmin: isAdmin ?? this.isAdmin,
        usernameUpdatedAt: usernameUpdatedAt ?? this.usernameUpdatedAt,
        photoURL: photoURL ?? this.photoURL,
        verifyStatus: verifyStatus ?? this.verifyStatus,
        verificationProof: verificationProof ?? this.verificationProof,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'schoolID': schoolID,
        'schoolEmail': schoolEmail,
        'fullName': fullName,
        'username': username,
        'isEnrolled': isEnrolled,
        'isValidated': isValidated,
        'isAdmin': isAdmin,
        'usernameUpdatedAt': usernameUpdatedAt?.toIso8601String(),
        'photoURL': photoURL,
        'verifyStatus': verifyStatus.name,
        'verificationProof': verificationProof,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String? ?? '',
        schoolID: map['schoolID'] as String? ?? '',
        schoolEmail: map['schoolEmail'] as String? ?? '',
        fullName: map['fullName'] as String? ?? '',
        username: map['username'] as String? ?? '',
        isEnrolled: map['isEnrolled'] as bool? ?? true,
        isValidated: map['isValidated'] as bool? ?? false,
        isAdmin: map['isAdmin'] as bool? ?? false,
        usernameUpdatedAt: (map['usernameUpdatedAt'] as String?) != null
            ? DateTime.tryParse(map['usernameUpdatedAt'] as String)
            : null,
        photoURL: map['photoURL'] as String?,
        verifyStatus: VerifyStatus.values.firstWhere(
          (s) => s.name == map['verifyStatus'],
          orElse: () => VerifyStatus.none,
        ),
        verificationProof: map['verificationProof'] as String?,
      );
}
