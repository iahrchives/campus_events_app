import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Displays an item photo from a local file path, a network/blob URL, or a
/// soft placeholder icon when none is set. Works across mobile, desktop & web.
class ItemImage extends StatelessWidget {
  final String? source;
  final IconData fallbackIcon;
  final BoxFit fit;

  const ItemImage({
    super.key,
    required this.source,
    this.fallbackIcon = Icons.image_outlined,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final src = source;
    if (src == null || src.isEmpty) {
      return Container(
        color: AppColors.surfaceTint,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, size: 42, color: AppColors.primary),
      );
    }

    final isRemote = src.startsWith('http') || src.startsWith('blob');
    final Widget image = (kIsWeb || isRemote)
        ? Image.network(src, fit: fit, errorBuilder: _onError)
        : Image.file(File(src), fit: fit, errorBuilder: _onError);

    return SizedBox.expand(child: image);
  }

  Widget _onError(BuildContext context, Object error, StackTrace? stack) {
    return Container(
      color: AppColors.surfaceTint,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: 42, color: AppColors.primary),
    );
  }
}
