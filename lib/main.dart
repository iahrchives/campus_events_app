import 'package:flutter/material.dart';

import 'services/settings_controller.dart';
import 'theme/theme.dart';
import 'screens/welcome_screen.dart';

void main() {
  // NOTE: When Firebase is configured (see README), replace runApp() with:
  //   WidgetsFlutterBinding.ensureInitialized();
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CampusEventsApp());
}

class CampusEventsApp extends StatelessWidget {
  const CampusEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app when settings (e.g. dark mode) change.
    return AnimatedBuilder(
      animation: SettingsController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Campus Events App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          // Keep the app a comfortable phone-width on large screens
          // (PC/web/tablet) so it doesn't stretch. Mobile is unaffected.
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            return ColoredBox(
              color: AppColors.dark
                  ? const Color(0xFF0C151E)
                  : const Color(0xFFE8EFF7),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child:
                      Material(color: AppColors.neutralLight, child: child),
                ),
              ),
            );
          },
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
