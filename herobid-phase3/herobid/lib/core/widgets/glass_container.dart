import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass panel used throughout HeroBid for cards, sheets, and
/// form backgrounds. Recreated here to match the look described in the
/// project README (dark/neon/glassmorphic Material 3) - if you already
/// have the original `core/theme` files from an earlier drop, prefer
/// those and drop this one in only if it's missing.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.blurSigma = 16,
    this.opacity = 0.08,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
