import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/verification_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/pill_button.dart';
import '../widgets/soft_card.dart';
import 'main_layout_shell.dart';

/// Enrollment proof upload screen.
///
/// • Initial activation ([reverify] = false): a hard redirect target for
///   profiles where `isValidated == false`; on success it enters the app.
/// • Re-verification ([reverify] = true): opened from the dashboard banner
///   during an active semester drive; on success it records the submission
///   and pops back.
class EnrollmentVerificationScreen extends StatefulWidget {
  final bool reverify;

  const EnrollmentVerificationScreen({super.key, this.reverify = false});

  @override
  State<EnrollmentVerificationScreen> createState() =>
      _EnrollmentVerificationScreenState();
}

class _EnrollmentVerificationScreenState
    extends State<EnrollmentVerificationScreen> {
  String? _proofPath;
  bool _activating = false;

  Future<void> _pick() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null) setState(() => _proofPath = x.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the gallery on this device.')));
    }
  }

  Future<void> _activate() async {
    if (_proofPath == null) return;
    setState(() => _activating = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final uid = AuthService.instance.currentUser?.uid ?? '';
    AuthService.instance.updateVerificationProof(_proofPath!);

    if (widget.reverify) {
      VerificationService.instance.markSubmitted(uid);
      if (!mounted) return;
      setState(() => _activating = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Proof re-submitted. Thanks — you\u2019re all set!')));
      return;
    }

    AuthService.instance.markValidated();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainLayoutShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        backgroundColor: AppColors.neutralLight,
        foregroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: widget.reverify,
        title: Text(widget.reverify ? 'Re-verify Enrollment' : 'Profile Activation',
            style: const TextStyle(color: AppColors.primary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            const Icon(Icons.verified_user_outlined,
                size: 72, color: AppColors.secondary),
            const SizedBox(height: 18),
            Text(
              widget.reverify
                  ? 'Re-submit Your Enrollment'
                  : 'Verify Your Enrollment',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 10),
            Text(
              widget.reverify
                  ? 'A new semester has started. Please upload your latest '
                      'enrollment assessment form to keep your profile active. '
                      'You can change the photo and submit again if needed.'
                  : 'Your campus profile is not yet active. Please upload your '
                      "current semester's enrollment assessment form to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            SoftCard(
              onTap: _pick,
              color: AppColors.surfaceTint.withValues(alpha: 0.4),
              border: Border.all(
                color: _proofPath != null ? AppColors.success : AppColors.secondary,
                width: 2.5,
              ),
              padding: const EdgeInsets.all(10),
              child: _proofPath == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_upload_outlined,
                              size: 46, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text('Tap to upload assessment form',
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
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ItemImage(
                                source: _proofPath,
                                fallbackIcon: Icons.description),
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
            const Spacer(),
            PillButton(
              label: widget.reverify ? 'Submit Proof' : 'Activate Profile',
              loading: _activating,
              onPressed: _proofPath != null ? _activate : null,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (widget.reverify) {
                  Navigator.pop(context);
                } else {
                  AuthService.instance.signOut();
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
              child: Text(widget.reverify ? 'Maybe later' : 'Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
