import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Animated circular percentage gauge replicating `react_app/src/components/Ring.jsx`.
///
/// Ownership: Shared Attendance Visualizations
// ==========================================
// SHARED WIDGETS - Attendance Percentage Ring
// ==========================================
class AttendanceRing extends StatelessWidget {
  final double? percent;
  final double minPercent;
  final double size;
  final bool animate;

  const AttendanceRing({
    super.key,
    required this.percent,
    this.minPercent = 75.0,
    this.size = 140.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: (percent ?? 0.0).clamp(0.0, 100.0),
            ),
            duration: animate
                ? const Duration(milliseconds: 700)
                : Duration.zero,
            curve: const Cubic(0.4, 0.0, 0.2, 1.0),
            builder: (context, animatedValue, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  percent: percent == null ? null : animatedValue,
                  minPercent: minPercent,
                  isDark: isDark,
                ),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main percentage text
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        percent == null
                            ? '—'
                            : (percent! % 1 == 0
                                  ? percent!.toInt().toString()
                                  : (percent! * 10).round() / 10 == percent!
                                  ? percent!.toStringAsFixed(1)
                                  : ((percent! * 10).round() / 10).toString()),
                        style: AppTypography.displayMedium.copyWith(
                          color: paperColor,
                          fontWeight: FontWeight.w700,
                          fontSize: size * 0.22,
                        ),
                      ),
                      if (percent != null)
                        Text(
                          '%',
                          style: AppTypography.headlineSmall.copyWith(
                            color: paperColor,
                            fontWeight: FontWeight.w700,
                            fontSize: size * 0.12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Target text
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.labelSmall.copyWith(
                        color: mutedColor,
                        fontSize: math.max(9.0, size * 0.075),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(text: 'TARGET '),
                        TextSpan(
                          text:
                              '${minPercent.toStringAsFixed(minPercent % 1 == 0 ? 0 : 1)}%',
                          style: TextStyle(
                            color: paperColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double? percent;
  final double minPercent;
  final bool isDark;

  _RingPainter({
    required this.percent,
    required this.minPercent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Scale stroke width proportionally to 200px reference
    final scale = size.width / 200.0;
    final strokeWidth = 14.0 * scale;
    final r = 82.0 * scale;

    final center = Offset(cx, cy);

    // 1. Background Track
    final trackColor = isDark ? AppColors.ruleDark : AppColors.ruleLight;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, r, trackPaint);

    // 2. Active Progress Arc
    if (percent != null && percent! > 0) {
      final safePct = percent!.clamp(0.0, 100.0);
      final sweepAngle = (safePct / 100.0) * 2 * math.pi;
      final startAngle = -math.pi / 2; // -90 degrees (top)

      final isSafe = percent! >= minPercent;

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (isSafe) {
        // Gradient: Blue -> Purple -> Emerald
        final rect = Rect.fromCircle(center: center, radius: r);
        progressPaint.shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [
            Color(0xFF3B82F6), // Blue
            Color(0xFF8B5CF6), // Purple
            Color(0xFF10B981), // Emerald
          ],
        ).createShader(rect);
      } else {
        // Solid Rose red
        progressPaint.color = AppColors.penRed;
      }

      final arcRect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, progressPaint);
    }

    // 3. Target Threshold Indicator Needle
    final thresholdAngle = -math.pi / 2 + (minPercent / 100.0) * 2 * math.pi;
    final needleInnerR = (82.0 - 11.0) * scale;
    final needleOuterR = (82.0 + 11.0) * scale;

    final innerX = cx + needleInnerR * math.cos(thresholdAngle);
    final innerY = cy + needleInnerR * math.sin(thresholdAngle);
    final outerX = cx + needleOuterR * math.cos(thresholdAngle);
    final outerY = cy + needleOuterR * math.sin(thresholdAngle);

    final needlePaint = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(innerX, innerY),
      Offset(outerX, outerY),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.minPercent != minPercent ||
        oldDelegate.isDark != isDark;
  }
}
