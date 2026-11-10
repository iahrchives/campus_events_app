import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/theme.dart';
import 'report_dialog.dart';

/// Result of a contact-management action, used by callers that need to react (closing an open chat after its contact is removed/blocked).
enum ContactActionResult { none, removed, blocked }

/// Opens the report sheet, records the report, then offers to block the contact as well.
Future<ContactActionResult> reportContactFlow(
  BuildContext context, {
  required String uid,
  required String name,
  String? conversationId,
}) async {
  final me = AuthService.instance.currentUser?.uid ?? '';
  if (me.isEmpty) return ContactActionResult.none;

  final reason = await showReportReasonSheet(context, subject: name);
  if (reason == null) return ContactActionResult.none;

  ChatService.instance.reportContact(
    me,
    uid,
    reason,
    conversationId: conversationId,
  );

  if (!context.mounted) return ContactActionResult.none;
  final block = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.neutralLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Report submitted'),
      content: Text(
        'Thanks for flagging $name. Do you also want to block this contact? '
        'You and $name will no longer be able to message each other.',
        style: TextStyle(color: AppColors.textDark, height: 1.35),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Block contact'),
        ),
      ],
    ),
  );

  if (block == true) {
    ChatService.instance.blockContact(me, uid);
  }
  if (!context.mounted) return ContactActionResult.none;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(block == true
        ? '$name has been blocked.'
        : 'Report submitted. Thanks for flagging this.'),
  ));
  return block == true
      ? ContactActionResult.blocked
      : ContactActionResult.none;
}

/// Confirms and removes user from the current user's contact list.
Future<ContactActionResult> confirmRemoveContact(
  BuildContext context, {
  required String uid,
  required String name,
}) async {
  final me = AuthService.instance.currentUser?.uid ?? '';
  if (me.isEmpty) return ContactActionResult.none;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.neutralLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Remove contact?'),
      content: Text(
        'Remove $name from your contacts? This hides your conversation but '
        'does not block them — they can still message you again.',
        style: TextStyle(color: AppColors.textDark, height: 1.35),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Remove'),
        ),
      ],
    ),
  );

  if (confirmed != true) return ContactActionResult.none;
  ChatService.instance.removeContact(me, uid);
  if (!context.mounted) return ContactActionResult.none;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('$name removed from your contacts.'),
  ));
  return ContactActionResult.removed;
}

/// Confirms and blocks user so neither party can send further messages.
Future<ContactActionResult> confirmBlockContact(
  BuildContext context, {
  required String uid,
  required String name,
}) async {
  final me = AuthService.instance.currentUser?.uid ?? '';
  if (me.isEmpty) return ContactActionResult.none;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.neutralLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Block contact?'),
      content: Text(
        'You and $name will no longer be able to message each other. You can '
        'unblock them later from Contacts.',
        style: TextStyle(color: AppColors.textDark, height: 1.35),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Block'),
        ),
      ],
    ),
  );

  if (confirmed != true) return ContactActionResult.none;
  ChatService.instance.blockContact(me, uid);
  if (!context.mounted) return ContactActionResult.none;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('$name blocked. You can unblock them from Contacts.'),
  ));
  return ContactActionResult.blocked;
}
