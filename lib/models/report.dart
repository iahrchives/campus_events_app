/// The kind of content a moderation report was filed against.
enum ReportTargetType { contact, forumPost, forumComment }

extension ReportTargetTypeX on ReportTargetType {
  String get label {
    switch (this) {
      case ReportTargetType.contact:
        return 'Direct message';
      case ReportTargetType.forumPost:
        return 'Forum post';
      case ReportTargetType.forumComment:
        return 'Forum reply';
    }
  }
}

/// Lifecycle of an admin-reviewed report.
enum ReportStatus { open, resolved, dismissed }

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.open:
        return 'Open';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}

/// A user-submitted moderation report with enough context for admin review.
class ModerationReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final ReportTargetType targetType;

  /// Reported user id, forum post id, or forum comment id.
  final String targetId;
  final String targetAuthorId;
  final String targetAuthorName;
  final String reason;

  /// Short excerpt of the reported content / conversation context.
  final String contentPreview;

  /// Conversation/item context for direct-message reports.
  final String? conversationId;
  final String? contextLabel;

  /// Parent post id when [targetType] is [ReportTargetType.forumComment].
  final String? parentPostId;

  final DateTime createdAt;
  ReportStatus status;

  ModerationReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetType,
    required this.targetId,
    required this.targetAuthorId,
    required this.targetAuthorName,
    required this.reason,
    this.contentPreview = '',
    this.conversationId,
    this.contextLabel,
    this.parentPostId,
    DateTime? createdAt,
    this.status = ReportStatus.open,
  }) : createdAt = createdAt ?? DateTime.now();
}
