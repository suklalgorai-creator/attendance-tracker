import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

enum AppBannerType { safe, danger, neutral, reminder }

typedef AppBannerVariant = AppBannerType;

/// Banner widget matching `.banner-safe`, `.banner-danger`, `.banner-none`, and `.reminder-banner`.
class AppBanner extends StatelessWidget {
  final AppBannerType type;
  final String? title;
  final String? message;
  final Widget? child;
  final Widget? leading;
  final Widget? action;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? customBackgroundColor;
  final Color? customTextColor;
  final Color? customBorderColor;

  const AppBanner({
    super.key,
    this.type = AppBannerType.neutral,
    this.title,
    this.message,
    this.child,
    this.leading,
    this.action,
    this.onTap,
    this.padding,
    this.margin,
    this.customBackgroundColor,
    this.customTextColor,
    this.customBorderColor,
  });

  const AppBanner.safe({
    super.key,
    this.title,
    this.message,
    this.child,
    this.leading,
    this.action,
    this.onTap,
    this.padding,
    this.margin,
    this.customBackgroundColor,
    this.customTextColor,
    this.customBorderColor,
  }) : type = AppBannerType.safe;

  const AppBanner.danger({
    super.key,
    this.title,
    this.message,
    this.child,
    this.leading,
    this.action,
    this.onTap,
    this.padding,
    this.margin,
    this.customBackgroundColor,
    this.customTextColor,
    this.customBorderColor,
  }) : type = AppBannerType.danger;

  const AppBanner.neutral({
    super.key,
    this.title,
    this.message,
    this.child,
    this.leading,
    this.action,
    this.onTap,
    this.padding,
    this.margin,
    this.customBackgroundColor,
    this.customTextColor,
    this.customBorderColor,
  }) : type = AppBannerType.neutral;

  const AppBanner.reminder({
    super.key,
    this.title,
    this.message,
    this.child,
    this.leading,
    this.action,
    this.onTap,
    this.padding,
    this.margin,
    this.customBackgroundColor,
    this.customTextColor,
    this.customBorderColor,
  }) : type = AppBannerType.reminder;

  AppBannerVariant get variant => type;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    Color bg;
    Color borderC;
    Color textC;
    double radius;
    EdgeInsets defaultPadding;
    EdgeInsets defaultMargin;
    double fontSize;
    FontWeight fontWeight;

    switch (type) {
      case AppBannerType.safe:
        bg = AppColors.inkGreen.withValues(alpha: 0.10);
        borderC = AppColors.inkGreen.withValues(alpha: 0.20);
        textC = AppColors.inkGreen;
        radius = 12.0;
        defaultPadding = const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        );
        defaultMargin = const EdgeInsets.only(bottom: 16.0);
        fontSize = 14.0;
        fontWeight = FontWeight.w500;
        break;
      case AppBannerType.danger:
        bg = AppColors.penRed.withValues(alpha: 0.10);
        borderC = AppColors.penRed.withValues(alpha: 0.20);
        textC = AppColors.penRed;
        radius = 12.0;
        defaultPadding = const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        );
        defaultMargin = const EdgeInsets.only(bottom: 16.0);
        fontSize = 14.0;
        fontWeight = FontWeight.w500;
        break;
      case AppBannerType.neutral:
        bg = mutedColor.withValues(alpha: 0.10);
        borderC = isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;
        textC = mutedColor;
        radius = 12.0;
        defaultPadding = const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        );
        defaultMargin = const EdgeInsets.only(bottom: 16.0);
        fontSize = 14.0;
        fontWeight = FontWeight.w500;
        break;
      case AppBannerType.reminder:
        bg = AppColors.penRedSoft;
        borderC = AppColors.penRed.withValues(alpha: 0.20);
        textC = AppColors.penRed;
        radius = AppRadius.lg; // 20.0
        defaultPadding = const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 20.0,
        );
        defaultMargin = const EdgeInsets.only(bottom: 24.0);
        fontSize = 15.0;
        fontWeight = FontWeight.w600;
        break;
    }

    final effectiveBg = customBackgroundColor ?? bg;
    final effectiveBorderColor = customBorderColor ?? borderC;
    final effectiveTextColor = customTextColor ?? textC;

    Widget bannerContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: paperColor,
                  ),
                ),
                if (message != null || child != null) const SizedBox(height: 4),
              ],
              if (message != null)
                Text(
                  message!,
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: effectiveTextColor,
                    height: 1.5,
                  ),
                ),
              ?child,
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );

    Widget container = Container(
      margin: margin ?? defaultMargin,
      padding: padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: effectiveBorderColor, width: 1.0),
      ),
      child: bannerContent,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: container,
        ),
      );
    }

    return container;
  }
}
