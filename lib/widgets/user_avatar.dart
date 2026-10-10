import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Circular profile avatar that renders the user's photo (local path or URL)
/// or a person icon placeholder when none is set.
class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  const UserAvatar({
    super.key,
    required this.photoURL,
    this.radius = 24,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final src = photoURL;
    final bg = backgroundColor ?? AppColors.surfaceTint;
    final fg = iconColor ?? AppColors.primary;

    if (src == null || src.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Icon(Icons.person, size: radius * 1.1, color: fg),
      );
    }

    final isRemote = src.startsWith('http') || src.startsWith('blob');
    final ImageProvider provider = (kIsWeb || isRemote)
        ? NetworkImage(src)
        : FileImage(File(src)) as ImageProvider;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      foregroundImage: provider,
      child: Icon(Icons.person, size: radius * 1.1, color: fg),
    );
  }
}
