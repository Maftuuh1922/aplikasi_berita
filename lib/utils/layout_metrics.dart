import 'package:flutter/material.dart';

/// Provides responsive metrics to keep spacing and sizing consistent across devices.
class LayoutMetrics {
  LayoutMetrics._(this.horizontal, this.smallGap, this.mediumGap, this.largeGap, this.cardRadius, this.fontScale);

  /// Base horizontal padding used across the UI.
  final double horizontal;

  /// Compact vertical spacing.
  final double smallGap;

  /// Medium vertical spacing.
  final double mediumGap;

  /// Large vertical spacing.
  final double largeGap;

  /// Default corner radius for cards and containers.
  final double cardRadius;

  /// Multiplier to scale font sizes responsively.
  final double fontScale;

  /// Helper to scale font sizes while clamping to a safe range.
  double scaledFont(double base) => (base * fontScale).clamp(base * 0.9, base * 1.2);

  static LayoutMetrics of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    final horizontal = width >= 600
        ? 28.0
        : width >= 420
            ? 22.0
            : width >= 360
                ? 18.0
                : 16.0;

    final smallGap = width >= 420 ? 10.0 : 8.0;
    final mediumGap = width >= 420 ? 14.0 : 12.0;
    final largeGap = width >= 420 ? 20.0 : 16.0;
    final cardRadius = width >= 420 ? 16.0 : 12.0;

    final fontScale = (width / 375).clamp(0.92, 1.1);

    return LayoutMetrics._(
      horizontal,
      smallGap,
      mediumGap,
      largeGap,
      cardRadius,
      fontScale,
    );
  }
}
