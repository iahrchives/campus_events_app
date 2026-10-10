import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/pill_button.dart';
import '../widgets/soft_card.dart';

/// Lets a student submit a picture of their enrollment assessment for admin
/// review. Reached from Settings → Verify Account (and the dashboard banner).
class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState
    extends State<AccountVerificationScreen> {
  String? _pickedPath;
  bool _submitting = false;

  Future<void> _pick() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null) setState(() => _pickedPath = x.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the gallery on this device.')));
    }
  }

  Future<void> _submit() async {
    final user = AuthService.instance.currentUser;
    final proof = _pickedPath ?? user?.verificationProof;
    if (proof == null) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    AuthService.instance.submitVerification(proof);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _pickedPath = null;
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Proof submitted — an admin will review it shortly.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Verify Account')),
      body: AnimatedBuilder(
        animation: AuthService.instance,
        builder: (context, _) {
          final user = AuthService.instance.currentUser;
          final status = user?.verifyStatus ?? VerifyStatus.none;
          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              _statusBanner(status),
              const SizedBox(height: 20),
              if (status == VerifyStatus.approved)
                _approvedView()
              else
                _uploadView(user),
            ],
          );
        },
      ),
    );
  }

  Widget _statusBanner(VerifyStatus status) {
    final (Color color, IconData icon, String msg) = switch (status) {
      VerifyStatus.approved => (
          AppColors.success,
          Icons.verified,
          'Your account is verified. You have full access to the app.'
        ),
      VerifyStatus.pending => (
          AppColors.secondary,
          Icons.hourglass_top,
          'Your proof was submitted and is awaiting admin review. You can '
              're-submit a clearer photo if needed.'
        ),
      VerifyStatus.rejected => (
          AppColors.danger,
          Icons.cancel_outlined,
          'Your previous submission was rejected. Please upload a valid '
              'enrollment assessment to try again.'
        ),
      VerifyStatus.none => (
          AppColors.primary,
          Icons.info_outline,
          'Submit a picture of your enrollment assessment so an admin can '
              'verify your account and unlock full access.'
        ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: AppColors.textDark, height: 1.4, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _approvedView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.verified_user,
            size: 80, color: AppColors.success),
        const SizedBox(height: 16),
        Text('You\u2019re all set!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
      ],
    );
  }

  Widget _uploadView(UserProfile? user) {
    final status = user?.verifyStatus ?? VerifyStatus.none;
    final current = _pickedPath ?? user?.verificationProof;
    final canSubmit = current != null;
    final isResubmit =
        status == VerifyStatus.pending || status == VerifyStatus.rejected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Enrollment assessment photo',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 12),
        SoftCard(
          onTap: _pick,
          padding: const EdgeInsets.all(10),
          child: current == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          size: 46, color: AppColors.primary),
                      const SizedBox(height: 10),
                      Text('Tap to choose a photo',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ItemImage(
                            source: current, fallbackIcon: Icons.description),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pick,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Change photo'),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 24),
        PillButton(
          label: isResubmit ? 'Resubmit for Review' : 'Submit for Review',
          loading: _submitting,
          onPressed: canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
