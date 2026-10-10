import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// Renders forum text with #hashtags and http(s) links highlighted.
///
/// • Hashtags are tappable — [onHashtagTap] receives the tag without the '#'.
/// • Links are tappable and copied to the clipboard (no launcher dependency).
class RichPostText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final ValueChanged<String>? onHashtagTap;

  const RichPostText(
    this.text, {
    super.key,
    this.style,
    this.onHashtagTap,
  });

  // Matches #hashtags (letters/numbers/underscore) or http(s) URLs.
  static final RegExp _token = RegExp(
    r'(#[A-Za-z0-9_]+)|((https?:\/\/)[^\s]+)',
    caseSensitive: false,
  );

  /// Extract the unique hashtags (without '#') contained in [body].
  static List<String> hashtagsIn(String body) {
    return RegExp(r'#([A-Za-z0-9_]+)')
        .allMatches(body)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        style ?? TextStyle(color: AppColors.textDark, height: 1.45);
    final accent = base.copyWith(
        color: AppColors.primary, fontWeight: FontWeight.w700);

    final spans = <InlineSpan>[];
    int start = 0;
    for (final m in _token.allMatches(text)) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start)));
      }
      final token = m.group(0)!;
      if (token.startsWith('#')) {
        spans.add(TextSpan(
          text: token,
          style: accent,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onHashtagTap?.call(token.substring(1)),
        ));
      } else {
        spans.add(TextSpan(
          text: token,
          style: accent.copyWith(decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Link copied to clipboard.')));
            },
        ));
      }
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(text: TextSpan(style: base, children: spans));
  }
}
