import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_typography.dart';

enum AppButtonVariant {
  present,
  absent,
  ghost,
  clear,
}

/// Standardized Button matching React CSS `.btn-present`, `.btn-absent`, `.btn-ghost`, `.btn-clear`
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isWide;
  final bool isLoading;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.present,
    this.icon,
    this.isWide = false,
    this.isLoading = false,
    this.fontSize,
    this.padding,
  });

  const AppButton.present({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isWide = false,
    this.isLoading = false,
    this.fontSize,
    this.padding,
  }) : variant = AppButtonVariant.present;

  const AppButton.absent({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isWide = false,
    this.isLoading = false,
    this.fontSize,
    this.padding,
  }) : variant = AppButtonVariant.absent;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isWide = false,
    this.isLoading = false,
    this.fontSize,
    this.padding,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.clear({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isWide = false,
    this.isLoading = false,
    this.fontSize,
    this.padding,
  }) : variant = AppButtonVariant.clear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadows;

    switch (variant) {
      case AppButtonVariant.present:
        bg = AppColors.inkGreen;
        fg = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.inkGreen.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case AppButtonVariant.absent:
        bg = AppColors.penRed;
        fg = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.penRed.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case AppButtonVariant.ghost:
        bg = isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;
        fg = paperColor;
        border = Border.all(
          color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          width: 1,
        );
        break;
      case AppButtonVariant.clear:
        bg = Colors.transparent;
        fg = mutedColor;
        border = Border.all(
          color: isDark ? AppColors.ruleDark : AppColors.ruleLight,
          width: 1,
        );
        break;
    }

    final buttonPadding = padding ??
        (isWide
            ? const EdgeInsets.symmetric(vertical: 16, horizontal: 20)
            : const EdgeInsets.symmetric(vertical: 12, horizontal: 16));

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: buttonPadding,
      decoration: BoxDecoration(
        color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
        borderRadius: BorderRadius.circular(AppRadius.card - 2), // 14px
        border: border,
        boxShadow: onPressed == null ? null : shadows,
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisSize: isWide ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize ?? 14.5,
                    ),
                  ),
                ],
              ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadius.card - 2),
        child: isWide ? SizedBox(width: double.infinity, child: content) : content,
      ),
    );
  }
}
