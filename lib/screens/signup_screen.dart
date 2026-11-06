import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_logo.dart';
import '../widgets/pill_button.dart';
import '../widgets/rounded_text_field.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

/// Screen 2 — large top-rounded primary sheet rising from the bottom.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _schoolId = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  // Required proof of enrollment (a screenshot of the assessment form).
  XFile? _enrollmentShot;

  @override
  void dispose() {
    for (final c in [
      _name,
      _username,
      _email,
      _address,
      _schoolId,
      _password,
      _confirm
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickEnrollmentShot() async {
    try {
      final picked =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _enrollmentShot = picked);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the gallery on this device.')));
    }
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    // Enrollment screenshot is mandatory to complete sign up.
    if (_enrollmentShot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Please attach a screenshot of your enrollment assessment.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.signUp(
        fullName: _name.text.trim(),
        username: _username.text.trim(),
        schoolEmail: _email.text.trim(),
        schoolID: _schoolId.text.trim(),
        password: _password.text,
        address: _address.text.trim(),
        enrollmentProof: _enrollmentShot?.name,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VerificationScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildEnrollmentUpload() {
    final attached = _enrollmentShot != null;
    return InkWell(
      onTap: _pickEnrollmentShot,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(
            color: attached ? AppColors.success : AppColors.surfaceTint,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              attached
                  ? Icons.check_circle_outline
                  : Icons.add_photo_alternate_outlined,
              color: attached ? AppColors.success : AppColors.secondary,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attached
                        ? 'Enrollment screenshot attached'
                        : 'Upload Enrollment Assessment',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    attached
                        ? _enrollmentShot!.name
                        : 'Required · attach a screenshot of your assessment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: Column(
        children: [
          // Branded header on the neutral base.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 44, 8, 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const BrandHeader(context: 'Welcome to', logoSize: 64),
              ],
            ),
          ),
          // Top-rounded primary sheet.
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadii.sheet),
                  topRight: Radius.circular(AppRadii.sheet),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      RoundedTextField(
                        controller: _name,
                        hint: 'Name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      RoundedTextField(
                        controller: _username,
                        hint: 'Username',
                        icon: Icons.alternate_email,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Choose a username';
                          if (t.length < 3) return 'At least 3 characters';
                          if (t.contains(' ')) return 'No spaces allowed';
                          return null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 6, right: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'You can change this later, but only once every 24 hours.',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RoundedTextField(
                        controller: _email,
                        hint: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || !v.contains('@')) {
                            return 'Enter a valid email';
                          }
                          if (AuthService.instance.emailExists(v)) {
                            return 'This email is already registered';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      RoundedTextField(
                        controller: _address,
                        hint: 'Address',
                        icon: Icons.home_outlined,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter your address'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Strict **-**-**** mask.
                      RoundedTextField(
                        controller: _schoolId,
                        hint: 'School ID  (e.g. 02-19-1234)',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [SchoolIdInputFormatter()],
                        validator: (v) =>
                            (v == null || v.length != 10) // **-**-****
                                ? 'Format must be **-**-****'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      RoundedTextField(
                        controller: _password,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscure: true,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Minimum 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      RoundedTextField(
                        controller: _confirm,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscure: true,
                        validator: (v) => (v != _password.text)
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildEnrollmentUpload(),
                      const SizedBox(height: 28),
                      PillButton(
                        label: 'Next',
                        loading: _loading,
                        color: AppColors.neutralLight,
                        textColor: AppColors.primary,
                        onPressed: _next,
                      ),
                      const SizedBox(height: 6),
                      _SignInLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
      child: RichText(
        text: const TextSpan(
          text: 'Already have an account?  ',
          style: TextStyle(color: Colors.white70, fontSize: 14),
          children: [
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
