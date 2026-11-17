import 'package:flutter/material.dart';

/// Central design tokens for colors matching react_app/src/styles/global.css
abstract final class AppColors {
  // Dark Palette (Default - matching react_app/src/styles/global.css)
  static const Color bgPrimaryDark = Color(0xFF050505);
  static const Color surfaceDark = Color(0xA618181B); // 65% alpha zinc-900 (rgba(24, 24, 27, 0.65))
  static const Color surfaceSolidDark = Color(0xFF18181B);
  static const Color surfaceHoverDark = Color(0xD927272A); // 85% alpha zinc-800 (rgba(39, 39, 42, 0.85))
  static const Color glassBorderDark = Color(0x14FFFFFF); // 8% alpha white (rgba(255, 255, 255, 0.08))
  static const Color ruleDark = Color(0x0FFFFFFF); // 6% alpha white (rgba(255, 255, 255, 0.06))
  static const Color ruleBrightDark = Color(0x1FFFFFFF); // 12% alpha white (rgba(255, 255, 255, 0.12))
  static const Color paperDark = Color(0xFFFFFFFF);
  static const Color mutedDark = Color(0xFFA1A1AA);
  static const Color textGradientStartDark = Color(0xFFFFFFFF);
  static const Color textGradientEndDark = Color(0xFFA1A1AA);
  static const Color cardShadowDark = Color(0x66000000); // 40% alpha black (rgba(0, 0, 0, 0.4))
  static const Color inputBgDark = Color(0x66000000); // 40% alpha black

  // Light Palette (matching react_app/src/styles/global.css)
  static const Color bgPrimaryLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xB3FFFFFF); // 70% alpha white (rgba(255, 255, 255, 0.70))
  static const Color surfaceSolidLight = Color(0xFFFFFFFF);
  static const Color surfaceHoverLight = Color(0xF2FFFFFF); // 95% alpha white (rgba(255, 255, 255, 0.95))
  static const Color glassBorderLight = Color(0x0D000000); // 5% alpha black (rgba(0, 0, 0, 0.05))
  static const Color ruleLight = Color(0x0F000000); // 6% alpha black (rgba(0, 0, 0, 0.06))
  static const Color ruleBrightLight = Color(0x1F000000); // 12% alpha black (rgba(0, 0, 0, 0.12))
  static const Color paperLight = Color(0xFF0F172A); // slate-900
  static const Color mutedLight = Color(0xFF64748B); // slate-500
  static const Color textGradientStartLight = Color(0xFF0F172A);
  static const Color textGradientEndLight = Color(0xFF475569);
  static const Color cardShadowLight = Color(0x0D000000); // 5% alpha black (rgba(0, 0, 0, 0.05))
  static const Color inputBgLight = Color(0x80FFFFFF); // 50% alpha white

  // Functional Universal Accents
  static const Color inkGreen = Color(0xFF10B981); // Emerald-500
  static const Color inkGreenSoft = Color(0x2610B981); // 15% alpha
  static const Color penRed = Color(0xFFF43F5E); // Rose-500
  static const Color penRedSoft = Color(0x26F43F5E); // 15% alpha
  static const Color amber = Color(0xFFF59E0B); // Amber-500
  static const Color amberSoft = Color(0x26F59E0B); // 15% alpha
  static const Color blueMesh = Color(0x263B82F6); // 15% alpha blue (#3B82F6)
}
