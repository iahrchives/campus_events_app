import 'announcement.dart' show RequestStatus;

export 'announcement.dart' show RequestStatus;

/// Campus event template (mirrors the Firestore `Events` collection).
class CampusEvent {
  final String id;
  final String title;
  final String description;
  final String venue;
  final String date;
  final String time;
  final String organizerID;
  final String? imageURL;

  const CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.date,
    required this.time,
    required this.organizerID,
    this.imageURL,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'venue': venue,
        'date': date,
        'time': time,
        'organizerID': organizerID,
        'imageURL': imageURL,
      };

  factory CampusEvent.fromMap(String id, Map<String, dynamic> map) =>
      CampusEvent(
        id: id,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        venue: map['venue'] as String? ?? '',
        date: map['date'] as String? ?? '',
        time: map['time'] as String? ?? '',
        organizerID: map['organizerID'] as String? ?? '',
        imageURL: map['imageURL'] as String?,
      );
}

/// A regular user's request for an admin to publish a campus event.
/// Only admins may approve these into real [CampusEvent]s.
class EventRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String title;
  final String description;
  final String venue;
  final String date;
  final String time;
  final String? imageURL;
  RequestStatus status;
  final DateTime createdAt;

  EventRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.title,
    required this.description,
    required this.venue,
    required this.date,
    required this.time,
    this.imageURL,
    this.status = RequestStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
