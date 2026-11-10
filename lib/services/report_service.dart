import 'package:flutter/foundation.dart';

import '../models/report.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// In-memory moderation report inbox shared by contact and forum reporting.
///
/// Admins receive a notification for every submitted report and can review the
/// reason, reported content context, and mark reports resolved or dismissed.
class ReportService extends ChangeNotifier {
  ReportService._();
  static final ReportService instance = ReportService._();

  final List<ModerationReport> _reports = [];

  /// All reports, newest first.
  List<ModerationReport> get reports {
    final list = [..._reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  List<ModerationReport> get openReports =>
      reports.where((r) => r.status == ReportStatus.open).toList();

  int get openCount =>
      _reports.where((r) => r.status == ReportStatus.open).length;

  ModerationReport? byId(String id) {
    for (final report in _reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  void submitContact({
    required String reporterId,
    required String reportedUid,
    required String reason,
    String? reporterName,
    String? reportedName,
    String? conversationId,
    String? contextLabel,
  }) {
    if (reporterId.isEmpty ||
        reportedUid.isEmpty ||
        reporterId == reportedUid ||
        reason.trim().isEmpty) {
      return;
    }
    _submit(ModerationReport(
      id: _nextId(),
      reporterId: reporterId,
      reporterName:
          reporterName ?? AuthService.instance.nameForUid(reporterId),
      targetType: ReportTargetType.contact,
      targetId: reportedUid,
      targetAuthorId: reportedUid,
      targetAuthorName:
          reportedName ?? AuthService.instance.nameForUid(reportedUid),
      reason: reason.trim(),
      conversationId: conversationId,
      contextLabel: contextLabel,
    ));
  }

  void submitForumPost({
    required String reporterId,
    required String postId,
    required String authorId,
    required String authorName,
    required String reason,
    String contentPreview = '',
    String? reporterName,
  }) {
    if (reporterId.isEmpty ||
        postId.isEmpty ||
        reporterId == authorId ||
        reason.trim().isEmpty) {
      return;
    }
    _submit(ModerationReport(
      id: _nextId(),
      reporterId: reporterId,
      reporterName:
          reporterName ?? AuthService.instance.nameForUid(reporterId),
      targetType: ReportTargetType.forumPost,
      targetId: postId,
      targetAuthorId: authorId,
      targetAuthorName: authorName,
      reason: reason.trim(),
      contentPreview: contentPreview,
    ));
  }

  void submitForumComment({
    required String reporterId,
    required String postId,
    required String commentId,
    required String authorId,
    required String authorName,
    required String reason,
    String contentPreview = '',
    String? reporterName,
  }) {
    if (reporterId.isEmpty ||
        postId.isEmpty ||
        commentId.isEmpty ||
        reporterId == authorId ||
        reason.trim().isEmpty) {
      return;
    }
    _submit(ModerationReport(
      id: _nextId(),
      reporterId: reporterId,
      reporterName:
          reporterName ?? AuthService.instance.nameForUid(reporterId),
      targetType: ReportTargetType.forumComment,
      targetId: commentId,
      targetAuthorId: authorId,
      targetAuthorName: authorName,
      reason: reason.trim(),
      contentPreview: contentPreview,
      parentPostId: postId,
    ));
  }

  void resolve(String reportId) =>
      _setStatus(reportId, ReportStatus.resolved);

  void dismiss(String reportId) =>
      _setStatus(reportId, ReportStatus.dismissed);

  void reopen(String reportId) => _setStatus(reportId, ReportStatus.open);

  void _setStatus(String reportId, ReportStatus status) {
    final report = byId(reportId);
    if (report == null || report.status == status) return;
    report.status = status;
    notifyListeners();
  }

  void _submit(ModerationReport report) {
    _reports.add(report);
    _notifyAdmins(report);
    notifyListeners();
  }

  void _notifyAdmins(ModerationReport report) {
    final body = '${report.reporterName} reported '
        '${report.targetAuthorName} (${report.targetType.label}): '
        '${report.reason}';
    for (final admin in AuthService.instance.allProfiles()) {
      if (!admin.isAdmin || admin.uid == report.reporterId) continue;
      NotificationService.instance.push(
        userId: admin.uid,
        type: AppNotificationType.report,
        title: 'New report: ${report.reason}',
        body: body,
        targetId: report.id,
      );
    }
  }

  String _nextId() => 'r_${DateTime.now().microsecondsSinceEpoch}';
}
