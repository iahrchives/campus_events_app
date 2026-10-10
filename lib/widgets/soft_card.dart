import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Reusable soft-rounded card container with generous padding and a
/// thick, subtle border — the core "bubble" building block.
class SoftCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Border? border;

  const SoftCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppRadii.card,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.neutralLight,
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(color: AppColors.surfaceTint, width: 2),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }
}
