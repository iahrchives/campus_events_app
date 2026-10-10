/// A campus-wide announcement. Only admins (or, in the future, authorized
/// personnel) may publish these.
class Announcement {
  final String id;
  final String title;
  final String body;

  /// uid + display name of whoever published it.
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  /// When an announcement originated from a user request that an admin
  /// approved, this records who originally asked for it.
  final String? requestedBy;

  /// Optional media attachments (local paths or URLs).
  final String? imageURL;
  final String? videoURL;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    DateTime? createdAt,
    this.requestedBy,
    this.imageURL,
    this.videoURL,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasMedia => imageURL != null || videoURL != null;

  /// A short preview of the body for cards/dashboards (first line, trimmed).
  String get brief {
    final firstLine = body.split('\n').first.trim();
    return firstLine.isEmpty ? body.trim() : firstLine;
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'requestedBy': requestedBy,
        'imageURL': imageURL,
        'videoURL': videoURL,
      };
}

/// Status of a user's request to have an announcement published.
enum RequestStatus { pending, approved, declined }

/// A regular user's request for an admin to post an announcement.
class AnnouncementRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String title;
  final String body;
  final String? imageURL;
  final String? videoURL;
  RequestStatus status;
  final DateTime createdAt;

  AnnouncementRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.title,
    required this.body,
    this.imageURL,
    this.videoURL,
    this.status = RequestStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
