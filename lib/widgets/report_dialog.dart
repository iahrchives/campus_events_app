import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Pre-written report reasons offered to users when flagging content.
const List<String> kReportReasons = [
  'Harassment or bullying',
  'Spam or scam',
  'Hate speech',
  'Inappropriate or explicit content',
  'Violence or dangerous behavior',
  'False information',
  'Other',
];

/// Shows a report sheet asking the user to pick a pre-written reason (with an
/// optional free-text box for "Other"). Returns the chosen reason string, or
/// null if the user cancelled.
Future<String?> showReportReasonSheet(
  BuildContext context, {
  String subject = 'this post',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.neutralLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _ReportSheet(subject: subject),
  );
}

class _ReportSheet extends StatefulWidget {
  final String subject;
  const _ReportSheet({required this.subject});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selected;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  bool get _isOther => _selected == 'Other';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, color: AppColors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Report ${widget.subject}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Why are you reporting this? Pick a reason below.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ...kReportReasons.map((r) {
              final selected = _selected == r;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selected = r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(r,
                            style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_isOther) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _details,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Tell us more (optional)…',
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: BorderSide(color: AppColors.surfaceTint, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selected == null
                        ? null
                        : () {
                            final detail = _details.text.trim();
                            final reason = _isOther && detail.isNotEmpty
                                ? 'Other: $detail'
                                : _selected!;
                            Navigator.pop(context, reason);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill)),
                    ),
                    child: const Text('Submit report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
