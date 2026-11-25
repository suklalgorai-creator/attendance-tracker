import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Key-value statistic row matching React `.stat-row` with semantic status tinting.
///
/// Ownership: Shared Design System Widgets
// ==========================================
// SHARED WIDGETS - Stat Label & Value Row
// ==========================================
enum StatValueColor { auto, safe, danger, paper, amber, muted }

typedef StatValueVariant = StatValueColor;

/// Reusable StatRow component replicating `.stat-row`, `.stat-label`, `.stat-value`
/// from `react_app/src/styles/components.css`.
class StatRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final StatValueColor valueColor;
  final Color? customValueColor;
  final bool isStatus;
  final bool isLast;
  final bool showDivider;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const StatRowWidget({
    super.key,
    required this.label,
    required this.value,
    StatValueColor? valueColor,
    this.customValueColor,
    bool? isStatus,
    bool? isStatusText,
    this.isLast = false,
    this.showDivider = true,
    this.trailing,
    this.padding,
    StatValueColor? variant,
  }) : isStatus = isStatusText ?? isStatus ?? false,
       valueColor = variant ?? valueColor ?? StatValueColor.auto;

  const StatRowWidget.safe({
    super.key,
    required this.label,
    required this.value,
    bool? isStatus,
    bool? isStatusText,
    this.isLast = false,
    this.showDivider = true,
    this.trailing,
    this.padding,
  }) : valueColor = StatValueColor.safe,
       customValueColor = null,
       isStatus = isStatusText ?? isStatus ?? false;

  const StatRowWidget.danger({
    super.key,
    required this.label,
    required this.value,
    bool? isStatus,
    bool? isStatusText,
    this.isLast = false,
    this.showDivider = true,
    this.trailing,
    this.padding,
  }) : valueColor = StatValueColor.danger,
       customValueColor = null,
       isStatus = isStatusText ?? isStatus ?? false;

  bool get isStatusText => isStatus;
  StatValueVariant get variant => valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;

    Color effectiveColor;
    if (customValueColor != null) {
      effectiveColor = customValueColor!;
    } else {
      switch (valueColor) {
        case StatValueColor.safe:
          effectiveColor = AppColors.inkGreen;
          break;
        case StatValueColor.danger:
          effectiveColor = AppColors.penRed;
          break;
        case StatValueColor.amber:
          effectiveColor = AppColors.amber;
          break;
        case StatValueColor.muted:
          effectiveColor = mutedColor;
          break;
        case StatValueColor.paper:
        case StatValueColor.auto:
          effectiveColor = paperColor;
          break;
      }
    }

    final double effectivePaddingBottom = (isLast || !showDivider) ? 0.0 : 12.0;

    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: effectivePaddingBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // .stat-label
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  softWrap: true,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: mutedColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // .stat-value
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.outfit(
                          fontSize: isStatus ? 15 : 20,
                          fontWeight: FontWeight.w800,
                          color: effectiveColor,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!isLast && showDivider) ...[
            const SizedBox(height: 12),
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(
                color: mutedColor.withValues(alpha: 0.2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  static const double dashWidth = 4.0;
  static const double dashSpace = 4.0;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(math.min(startX + dashWidth, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
