import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/pill_button.dart';
import '../widgets/rounded_text_field.dart';
import 'main_layout_shell.dart';
import 'signup_screen.dart';

/// Screen 3 — login. Mirrors the sign-up sheet with simplified inputs and
/// implements the LLD `isValidated` access-control routing.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final UserProfile profile = await AuthService.instance.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;

      // Everyone enters the shell. Access is gated by verification status:
      // unverified students see a restricted nav (Dashboard, Announcements,
      // Settings) and verify via Settings → Verify Account.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayoutShell()),
        (route) => false,
      );
      // Avoid "unused" lint while keeping the profile reference meaningful.
      assert(profile.uid.isNotEmpty);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: Column(
        children: [
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
                const BrandHeader(context: 'Sign in to continue', logoSize: 64),
              ],
            ),
          ),
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
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Log in',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                      const SizedBox(height: 18),
                      const _DemoHint(),
                      const SizedBox(height: 18),
                      RoundedTextField(
                        controller: _email,
                        hint: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      RoundedTextField(
                        controller: _password,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscure: true,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter your password'
                            : null,
                      ),
                      const SizedBox(height: 30),
                      PillButton(
                        label: 'Login',
                        loading: _loading,
                        color: AppColors.neutralLight,
                        textColor: AppColors.primary,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?',
                            style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        ),
                        child: const Text("Don't have an account? Sign Up",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
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

/// Small helper showing the seeded demo credentials for quick testing.
class _DemoHint extends StatelessWidget {
  const _DemoHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: const Text(
        'Demo logins (password: password123)\n'
        '• validated@campus.edu  → verified (full access)\n'
        '• pending@campus.edu  → unverified (restricted)\n'
        '• admin@campus.edu  → admin + Verification panel',
        style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.5),
      ),
    );
  }
}
