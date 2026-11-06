import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/help_button.dart';
import '../widgets/pill_button.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Screen 1 — clean welcome view with a centered community logo + app name
/// and two thick pill buttons at the bottom.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Light-blue branded hero panel.
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadii.sheet),
                    ),
                    child: const Center(
                      child: BrandHeader(
                          context: 'Welcome to', logoSize: 140),
                    ),
                  ),
                ),
                // Action buttons.
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Your campus, all in one place',
                          style: TextStyle(
                              fontSize: 15, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 28),
                        PillButton(
                          label: 'I have an account',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PillButton(
                          label: 'Create an account',
                          filled: false,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(bottom: 18, right: 18, child: HelpButton()),
          ],
        ),
      ),
    );
  }
}
