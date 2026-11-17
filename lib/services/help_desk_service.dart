import 'package:flutter/foundation.dart';

import '../models/support_ticket.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Mock store for campus FAQs and student support tickets (PBI-13).
class HelpDeskService extends ChangeNotifier {
  HelpDeskService._();

  static final HelpDeskService instance = HelpDeskService._();

  static const List<String> ticketCategories = [
    'Account & Verification',
    'Events & Registration',
    'Marketplace & Messaging',
    'Lost & Found',
    'Bug / Technical Issue',
    'Other Inquiry',
  ];

  /// Pre-loaded campus FAQs searchable by students.
  final List<FaqItem> _faqs = const [
    FaqItem(
      id: 'faq_1',
      category: 'Account & Verification',
      question: 'How do I verify my student account?',
      answer:
      'Go to Settings > Verify Account, upload a clear photo of your valid school ID or Certificate of Registration (COR), and submit. Campus admins usually review requests within 24 hours.',
    ),
    FaqItem(
      id: 'faq_2',
      category: 'Account & Verification',
      question: 'Why are Events, Marketplace, and Forum locked for me?',
      answer:
      'To keep the campus community safe, full access to Events, Campus Map, Marketplace, Lost & Found, and Community Forum unlocks once your student account is verified by an administrator.',
    ),
    FaqItem(
      id: 'faq_3',
      category: 'Events & Registration',
      question: 'How do I register or request to host a campus event?',
      answer:
      'Open the Events tab from the navigation drawer. Tap any event card to view its schedule, room location, and RSVP button. Verified students and student organizations can also tap the "+" button to submit an event proposal.',
    ),
    FaqItem(
      id: 'faq_4',
      category: 'Marketplace & Messaging',
      question: 'What happens to my messages if I lose campus Wi-Fi?',
      answer:
      'Any message you send while offline is automatically saved locally on your device as "Queued (Offline)" and will be sent automatically in order as soon as your internet connection returns.',
    ),
    FaqItem(
      id: 'faq_5',
      category: 'Marketplace & Messaging',
      question: 'How do I report or block a suspicious user?',
      answer:
      'Open your chat thread with the user, tap the three-dots menu (⋮) in the top-right corner, and choose "Report contact" or "Block contact". Reports are sent directly to campus moderators.',
    ),
    FaqItem(
      id: 'faq_6',
      category: 'Technical Support',
      question: 'How do I turn on Dark Mode or hide my Active Status?',
      answer:
      'Open the Settings tab from the drawer. Under Appearance, toggle Dark Mode. Under Privacy, you can toggle Read Receipts and Active Status on or off anytime.',
    ),
  ];

  final List<SupportTicket> _tickets = [
    SupportTicket(
      id: 't_1001',
      studentId: 'uid_student_sample',
      studentName: 'Sample Student',
      category: 'Account & Verification',
      subject: 'COR upload status inquiry',
      description:
      'Hi! I submitted my Certificate of Registration yesterday morning. May I ask when it will be approved?',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      status: TicketStatus.resolved,
      adminReply:
      'Your COR has been verified! Please re-open the drawer to access all verified student tabs.',
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  List<FaqItem> get faqs => List.unmodifiable(_faqs);

  List<SupportTicket> get allTickets => List.unmodifiable(_tickets);

  int get openTicketCount =>
      _tickets.where((t) => t.status != TicketStatus.resolved).length;

  /// Returns all tickets for admins, or only tickets belonging to [uid].
  List<SupportTicket> ticketsForUser(String uid, {required bool isAdmin}) {
    if (isAdmin) return List.unmodifiable(_tickets);
    return _tickets.where((t) => t.studentId == uid).toList();
  }

  /// Submits a new support ticket from a student and notifies admins.
  void submitTicket({
    required String studentId,
    required String studentName,
    required String category,
    required String subject,
    required String description,
  }) {
    final ticket = SupportTicket(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      studentName: studentName,
      category: category,
      subject: subject.trim(),
      description: description.trim(),
    );
    _tickets.insert(0, ticket);

    for (final profile in AuthService.instance.allProfiles()) {
      if (!profile.isAdmin) continue;
      NotificationService.instance.push(
        userId: profile.uid,
        type: AppNotificationType.announcement,
        title: 'New Help Desk Ticket: ${ticket.subject}',
        body: '${ticket.studentName} (${ticket.category})',
        targetId: ticket.id,
      );
    }

    notifyListeners();
  }

  /// Admin updates a ticket's status and/or adds an official response.
  void updateTicket({
    required String ticketId,
    required TicketStatus status,
    String? adminReply,
  }) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;

    final ticket = _tickets[idx];
    ticket.status = status;
    if (adminReply != null && adminReply.trim().isNotEmpty) {
      ticket.adminReply = adminReply.trim();
    }
    ticket.updatedAt = DateTime.now();

    NotificationService.instance.push(
      userId: ticket.studentId,
      type: AppNotificationType.announcement,
      title: 'Support Ticket ${status.label}: ${ticket.subject}',
      body: ticket.adminReply ?? 'Your ticket status is now ${status.label}.',
      targetId: ticket.id,
    );

    notifyListeners();
  }
}