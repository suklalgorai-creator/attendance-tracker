import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

/// Reusable painter for the 4-sided prism border matching React components.css lines 33-37:
/// Top emerald 40%, right blue 40%, bottom rose 40%, left amber 40%.
class PrismBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;

  const PrismBorderPainter({
    this.radius = AppRadius.card,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = const SweepGradient(
        colors: [
          Color(0x6610B981), // Emerald 40% (top)
          Color(0x663B82F6), // Blue 40% (right)
          Color(0x66F43F5E), // Rose 40% (bottom)
          Color(0x66F59E0B), // Amber 40% (left)
          Color(0x6610B981), // Emerald 40% (loop back)
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(
          -1.5707963267948966,
        ), // -pi/2 (starts at top 12 o'clock)
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant PrismBorderPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.strokeWidth != strokeWidth;
}

/// Reusable glassmorphic card component matching the `.card` class in React CSS:
/// 4-sided prism border, translucent surface, card shadow, and optional backdrop blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool useBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14.0),
    this.onTap,
    this.useBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final shadowColor = isDark
        ? AppColors.cardShadowDark
        : AppColors.cardShadowLight;

    Widget content = CustomPaint(
      foregroundPainter: const PrismBorderPainter(
        radius: AppRadius.card,
        strokeWidth: 1.5,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );

    if (useBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: content,
        ),
      );
    }

    return content;
  }
}
