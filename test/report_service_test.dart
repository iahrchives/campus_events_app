import 'package:flutter_test/flutter_test.dart';

import 'package:campus_events_app/models/report.dart';
import 'package:campus_events_app/services/auth_service.dart';
import 'package:campus_events_app/services/forum_service.dart';
import 'package:campus_events_app/services/notification_service.dart';
import 'package:campus_events_app/services/report_service.dart';

void main() {
  final reports = ReportService.instance;

  test('contact reports store the reason and notify admins', () {
    final beforeNotifications =
        NotificationService.instance.forUser('uid_admin_000').length;

    reports.submitContact(
      reporterId: 'report_reporter_1',
      reportedUid: 'report_target_1',
      reason: 'Harassment or bullying',
      reporterName: 'Reporter One',
      reportedName: 'Target One',
      conversationId: 'report_conversation_1',
      contextLabel: 'Laptop listing',
    );

    final report = reports.reports.firstWhere(
      (r) => r.reporterId == 'report_reporter_1',
    );
    expect(report.targetType, ReportTargetType.contact);
    expect(report.targetId, 'report_target_1');
    expect(report.targetAuthorName, 'Target One');
    expect(report.reason, 'Harassment or bullying');
    expect(report.conversationId, 'report_conversation_1');
    expect(report.contextLabel, 'Laptop listing');

    final notifications =
        NotificationService.instance.forUser('uid_admin_000');
    expect(notifications.length, beforeNotifications + 1);
    final notification =
        notifications.firstWhere((n) => n.targetId == report.id);
    expect(notification.type, AppNotificationType.report);
    expect(notification.title, contains('Harassment or bullying'));
    expect(notification.body, contains('Harassment or bullying'));
    expect(notification.body, contains('Reporter One'));
  });

  test('forum reports keep the reason and content context', () {
    reports.submitForumPost(
      reporterId: 'forum_reporter_1',
      reporterName: 'Forum Reporter',
      postId: 'forum_post_1',
      authorId: 'forum_author_1',
      authorName: 'Forum Author',
      reason: 'Spam or scam',
      contentPreview: 'Buy this now at a suspicious link',
    );

    final report = reports.reports.firstWhere(
      (r) =>
          r.reporterId == 'forum_reporter_1' &&
          r.targetId == 'forum_post_1',
    );
    expect(report.targetType, ReportTargetType.forumPost);
    expect(report.targetAuthorId, 'forum_author_1');
    expect(report.targetAuthorName, 'Forum Author');
    expect(report.reason, 'Spam or scam');
    expect(report.contentPreview, 'Buy this now at a suspicious link');
  });

  test('forum reply reports include the parent post', () {
    reports.submitForumComment(
      reporterId: 'forum_reporter_2',
      postId: 'forum_post_2',
      commentId: 'forum_comment_2',
      authorId: 'forum_author_2',
      authorName: 'Reply Author',
      reason: 'Hate speech',
      contentPreview: 'Reported reply text',
    );

    final report = reports.reports.firstWhere(
      (r) => r.targetId == 'forum_comment_2',
    );
    expect(report.targetType, ReportTargetType.forumComment);
    expect(report.parentPostId, 'forum_post_2');
    expect(report.reason, 'Hate speech');
  });

  test('resolving, dismissing, and reopening update report status', () {
    final before = reports.openCount;
    reports.submitForumPost(
      reporterId: 'status_reporter',
      postId: 'status_post',
      authorId: 'status_author',
      authorName: 'Status Author',
      reason: 'False information',
    );
    final report = reports.reports.firstWhere(
      (r) => r.targetId == 'status_post',
    );
    expect(report.status, ReportStatus.open);
    expect(reports.openCount, before + 1);

    reports.resolve(report.id);
    expect(report.status, ReportStatus.resolved);
    expect(reports.openCount, before);

    reports.reopen(report.id);
    expect(report.status, ReportStatus.open);
    expect(reports.openCount, before + 1);

    reports.dismiss(report.id);
    expect(report.status, ReportStatus.dismissed);
    expect(reports.openCount, before);
  });

  test('ForumService forwards post and reply reasons to the inbox', () async {
    await AuthService.instance.signIn(
      email: 'validated@campus.edu',
      password: 'password123',
    );

    ForumService.instance.reportPost('p2', reason: 'False information');
    final postReport = reports.reports.firstWhere(
      (r) => r.targetType == ReportTargetType.forumPost && r.targetId == 'p2',
    );
    expect(postReport.reason, 'False information');
    expect(postReport.targetAuthorId, 'uid_pending_002');

    ForumService.instance.reportComment(
      'p1',
      'c1',
      reason: 'Harassment or bullying',
    );
    final commentReport = reports.reports.firstWhere(
      (r) =>
          r.targetType == ReportTargetType.forumComment && r.targetId == 'c1',
    );
    expect(commentReport.reason, 'Harassment or bullying');
    expect(commentReport.parentPostId, 'p1');
    expect(commentReport.contentPreview, 'I have one, DM me!');

    AuthService.instance.signOut();
  });
}
