/// Lifecycle status of a student support ticket.
enum TicketStatus { open, inProgress, resolved }

extension TicketStatusLabel on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }
}

/// A frequently asked question item shown in the Help Desk FAQ tab.
class FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;

  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });
}

/// A support ticket submitted by a student in the Help Desk tab.
class SupportTicket {
  final String id;
  final String studentId;
  final String studentName;
  final String category;
  final String subject;
  final String description;
  final DateTime createdAt;
  TicketStatus status;
  String? adminReply;
  DateTime? updatedAt;

  SupportTicket({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.category,
    required this.subject,
    required this.description,
    DateTime? createdAt,
    this.status = TicketStatus.open,
    this.adminReply,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();
}