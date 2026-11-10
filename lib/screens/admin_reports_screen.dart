import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/soft_card.dart';
import 'forum_post_detail_screen.dart';

enum _ReportFilter { open, resolved, dismissed, all }

/// Admin-only inbox for reports submitted from direct messages and the forum.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  _ReportFilter _filter = _ReportFilter.open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Reports')),
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [ReportService.instance, AuthService.instance]),
        builder: (context, _) {
          if (!AuthService.instance.isAdmin) {
            return Center(
              child: Text(
                'Only admins can review reports.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final all = ReportService.instance.reports;
          final filtered = _filtered(all);
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _summary(all),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip(_ReportFilter.open,
                      'Open (${_count(all, ReportStatus.open)})'),
                  _filterChip(_ReportFilter.resolved,
                      'Resolved (${_count(all, ReportStatus.resolved)})'),
                  _filterChip(_ReportFilter.dismissed,
                      'Dismissed (${_count(all, ReportStatus.dismissed)})'),
                  _filterChip(_ReportFilter.all, 'All (${all.length})'),
                ],
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                _emptyState()
              else
                ...filtered.map(_reportCard),
            ],
          );
        },
      ),
    );
  }

  List<ModerationReport> _filtered(List<ModerationReport> all) {
    if (_filter == _ReportFilter.all) return all;
    final status = switch (_filter) {
      _ReportFilter.open => ReportStatus.open,
      _ReportFilter.resolved => ReportStatus.resolved,
      _ReportFilter.dismissed => ReportStatus.dismissed,
      _ReportFilter.all => ReportStatus.open,
    };
    return all.where((r) => r.status == status).toList();
  }

  int _count(List<ModerationReport> all, ReportStatus status) =>
      all.where((r) => r.status == status).length;

  Widget _summary(List<ModerationReport> all) {
    final open = _count(all, ReportStatus.open);
    return SoftCard(
      color: AppColors.surfaceTint.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.danger.withValues(alpha: 0.12),
            child: const Icon(Icons.flag_outlined, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$open open ${open == 1 ? "report" : "reports"}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${all.length} total submitted',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(_ReportFilter filter, String label) {
    final selected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = filter),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.textDark,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : AppColors.surfaceTint.withValues(alpha: 0.6),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    );
  }

  Widget _emptyState() {
    final label = switch (_filter) {
      _ReportFilter.open => 'No open reports',
      _ReportFilter.resolved => 'No resolved reports',
      _ReportFilter.dismissed => 'No dismissed reports',
      _ReportFilter.all => 'No reports yet',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 54, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reports submitted by users will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(ModerationReport report) {
    final preview = report.contentPreview.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    report.targetType.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const Spacer(),
                _statusPill(report.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.reason,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${report.reporterName} reported ${report.targetAuthorName}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
            if (report.contextLabel != null &&
                report.contextLabel!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Context: ${report.contextLabel}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              timeAgo(report.createdAt),
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (report.targetType != ReportTargetType.contact)
                  OutlinedButton.icon(
                    onPressed: () => _openContent(report),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open content'),
                  ),
                if (report.status == ReportStatus.open) ...[
                  TextButton(
                    onPressed: () =>
                        ReportService.instance.resolve(report.id),
                    child: const Text('Resolve'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ReportService.instance.dismiss(report.id),
                    child: const Text('Dismiss'),
                  ),
                ] else
                  TextButton(
                    onPressed: () => ReportService.instance.reopen(report.id),
                    child: const Text('Reopen'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(ReportStatus status) {
    final color = switch (status) {
      ReportStatus.open => AppColors.danger,
      ReportStatus.resolved => AppColors.success,
      ReportStatus.dismissed => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  void _openContent(ModerationReport report) {
    final postId = report.parentPostId ?? report.targetId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForumPostDetailScreen(postId: postId),
      ),
    );
  }
}
