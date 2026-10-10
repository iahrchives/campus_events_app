import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// Renders [text] with any http/https links styled and tappable. Tapping a
/// link copies it to the clipboard (no external launcher dependency needed)
/// and shows a confirmation snackbar.
class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const LinkifiedText(this.text, {super.key, this.style});

  static final RegExp _urlRegex =
      RegExp(r'((https?:\/\/)[^\s]+)', caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final base = style ??
        TextStyle(color: AppColors.textDark, height: 1.6, fontSize: 15);
    final linkStyle = base.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );

    final spans = <InlineSpan>[];
    int start = 0;
    for (final m in _urlRegex.allMatches(text)) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start)));
      }
      final url = m.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard.')));
          },
      ));
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: base, children: spans),
    );
  }
}
