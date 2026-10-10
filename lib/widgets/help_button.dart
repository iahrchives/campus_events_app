import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Small circular "?" help button shown bottom-right of the auth screens
/// (matches the mockups). Pops a quick info dialog.
class HelpButton extends StatelessWidget {
  final String message;

  const HelpButton({
    super.key,
    this.message =
        'Use the demo accounts on the Login screen, or create a new account '
            'to get started. Need more help? Contact the campus IT office.',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.primary, width: 2.5),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: const Text('Need a hand?'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.question_mark_rounded,
              color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
