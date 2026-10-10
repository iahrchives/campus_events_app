import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Circular "community embrace" brand mark used across the auth screens,
/// approximating the hugging-arms logo from the design mockups.
class AppLogo extends StatelessWidget {
  final double size;

  /// Use the light variant on coloured (primary) sheets.
  final bool light;

  const AppLogo({super.key, this.size = 120, this.light = false});

  @override
  Widget build(BuildContext context) {
    final ring = light ? Colors.white : AppColors.primary;
    final fill = light
        ? Colors.white.withValues(alpha: 0.16)
        : AppColors.surfaceTint.withValues(alpha: 0.55);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: ring.withValues(alpha: 0.35), width: 2),
      ),
      child: CustomPaint(painter: _EmbracePainter(ring)),
    );
  }
}

/// Draws a stylised "C" arm embracing a small circle (head) — the hug motif.
class _EmbracePainter extends CustomPainter {
  final Color color;
  _EmbracePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.30;

    final arm = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    // Embracing arm — open "C" sweeping most of the circle.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      math.pi * 0.65, // start
      math.pi * 1.55, // sweep
      false,
      arm,
    );

    // The "head" being embraced.
    final head = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final headPos = Offset(
      c.dx + r * math.cos(math.pi * 0.35),
      c.dy + r * math.sin(math.pi * 0.35),
    );
    canvas.drawCircle(headPos, size.width * 0.11, head);
  }

  @override
  bool shouldRepaint(covariant _EmbracePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Logo + small context line + bold app name. Used at the top of auth sheets.
class BrandHeader extends StatelessWidget {
  final String context;
  final double logoSize;
  final bool light;

  const BrandHeader({
    super.key,
    this.context = 'Welcome to',
    this.logoSize = 110,
    this.light = false,
  });

  @override
  Widget build(BuildContext ctx) {
    final textColor = light ? Colors.white : AppColors.primary;
    return Column(
      children: [
        AppLogo(size: logoSize, light: light),
        const SizedBox(height: 14),
        Text(
          context,
          style: TextStyle(
            color: light ? Colors.white70 : AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'CAMPUS EVENTS',
          style: TextStyle(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
