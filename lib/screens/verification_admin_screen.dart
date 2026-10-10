import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/verification_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/soft_card.dart';
import '../widgets/user_avatar.dart';

enum _VerifyFilter { all, verified, unverified, resubmission }

/// Admin-only panel (in the nav drawer) to review enrollment verifications.
/// Each student account shows whether they submitted proof; the admin marks
/// each one approved (yes) or rejected (no). Rejected/unverified accounts are
/// limited to Dashboard, Announcements and Settings.
class VerificationAdminScreen extends StatefulWidget {
  const VerificationAdminScreen({super.key});

  @override
  State<VerificationAdminScreen> createState() =>
      _VerificationAdminScreenState();
}

class _VerificationAdminScreenState extends State<VerificationAdminScreen> {
  final _search = TextEditingController();
  _VerifyFilter _filter = _VerifyFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<UserProfile> _filteredAccounts() {
    final query = _search.text.trim().toLowerCase();
    final accounts = AuthService.instance
        .allProfiles()
        .where((p) => !p.isAdmin)
        .where((p) {
          if (query.isEmpty) return true;
          return p.fullName.toLowerCase().contains(query) ||
              p.schoolEmail.toLowerCase().contains(query) ||
              p.schoolID.toLowerCase().contains(query);
        })
        .where((p) {
          return switch (_filter) {
            _VerifyFilter.all => true,
            _VerifyFilter.verified =>
              p.verifyStatus == VerifyStatus.approved,
            _VerifyFilter.unverified =>
              p.verifyStatus != VerifyStatus.approved,
            _VerifyFilter.resubmission =>
              VerificationService.instance.needsResubmission(p),
          };
        })
        .toList()
      ..sort((a, b) {
        int rank(VerifyStatus s) => switch (s) {
              VerifyStatus.pending => 0,
              VerifyStatus.none => 1,
              VerifyStatus.rejected => 2,
              VerifyStatus.approved => 3,
            };
        return rank(a.verifyStatus).compareTo(rank(b.verifyStatus));
      });
    return accounts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Verification')),
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [AuthService.instance, VerificationService.instance]),
        builder: (context, _) {
          final accounts = _filteredAccounts();
          final allStudents = AuthService.instance
              .allProfiles()
              .where((p) => !p.isAdmin)
              .toList();
          final pending = allStudents
              .where((a) => a.verifyStatus == VerifyStatus.pending)
              .length;
          final resubmission = allStudents
              .where((a) =>
                  VerificationService.instance.needsResubmission(a))
              .length;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _summary(pending, allStudents.length, resubmission),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or ID…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', _VerifyFilter.all),
                    const SizedBox(width: 8),
                    _filterChip('Verified', _VerifyFilter.verified),
                    const SizedBox(width: 8),
                    _filterChip('Unverified', _VerifyFilter.unverified),
                    const SizedBox(width: 8),
                    _filterChip('For resubmission', _VerifyFilter.resubmission),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (accounts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      _search.text.isNotEmpty || _filter != _VerifyFilter.all
                          ? 'No accounts match your search or filter.'
                          : 'No student accounts yet.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...accounts.map((a) => _accountCard(context, a)),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, _VerifyFilter value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected ? AppColors.primary : AppColors.textDark,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.surfaceTint,
        width: selected ? 1.5 : 1,
      ),
    );
  }

  Widget _summary(int pending, int total, int resubmission) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pending pending review · $total student accounts'
              '${resubmission > 0 ? ' · $resubmission need re-submission' : ''}. '
              'Approve to grant full access, reject to keep the account restricted.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard(BuildContext context, UserProfile a) {
    final submitted = a.verificationProof != null;
    final needsResubmit =
        VerificationService.instance.needsResubmission(a);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(photoURL: a.photoURL, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.fullName,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      Text(a.schoolEmail,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (needsResubmit) ...[
                  _resubmissionChip(),
                  const SizedBox(width: 6),
                ],
                _statusChip(a.verifyStatus),
              ],
            ),
            if (submitted) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _viewProof(context, a),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 54,
                        width: 54,
                        child: ItemImage(
                            source: a.verificationProof,
                            fallbackIcon: Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Submitted proof · tap to view',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('No proof submitted yet.',
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: a.verifyStatus == VerifyStatus.rejected
                        ? null
                        : () => _decide(context, a, false),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('No'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger, width: 1.6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.field)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: a.verifyStatus == VerifyStatus.approved
                        ? null
                        : () => _decide(context, a, true),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Yes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.field)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resubmissionChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh, size: 13, color: AppColors.secondary),
          const SizedBox(width: 3),
          Text('Re-submit',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondary)),
        ],
      ),
    );
  }

  void _decide(BuildContext context, UserProfile a, bool approved) {
    AuthService.instance.setVerificationDecision(a.uid, approved);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approved
            ? '${a.fullName} approved — full access granted.'
            : '${a.fullName} rejected — access kept restricted.')));
  }

  void _viewProof(BuildContext context, UserProfile a) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.neutralLight,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${a.fullName} · enrollment proof',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ItemImage(
                    source: a.verificationProof,
                    fallbackIcon: Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(VerifyStatus status) {
    final (Color color, IconData icon) = switch (status) {
      VerifyStatus.approved => (AppColors.success, Icons.check_circle),
      VerifyStatus.pending => (AppColors.secondary, Icons.hourglass_top),
      VerifyStatus.rejected => (AppColors.danger, Icons.cancel),
      VerifyStatus.none => (AppColors.textMuted, Icons.remove_circle_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
