import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_radius.dart';
import 'package:flutter_app/core/constants/app_spacing.dart';
import 'package:flutter_app/core/constants/app_typography.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Design System Tokens Unit Tests', () {
    test('AppColors matches CSS custom properties in global.css', () {
      // Dark Mode Tokens
      expect(AppColors.bgPrimaryDark, const Color(0xFF050505));
      expect(AppColors.surfaceDark, const Color(0xA618181B));
      expect(AppColors.surfaceSolidDark, const Color(0xFF18181B));
      expect(AppColors.glassBorderDark, const Color(0x14FFFFFF));
      expect(AppColors.paperDark, const Color(0xFFFFFFFF));
      expect(AppColors.mutedDark, const Color(0xFFA1A1AA));

      // Light Mode Tokens
      expect(AppColors.bgPrimaryLight, const Color(0xFFF8FAFC));
      expect(AppColors.surfaceLight, const Color(0xB3FFFFFF));
      expect(AppColors.surfaceSolidLight, const Color(0xFFFFFFFF));
      expect(AppColors.glassBorderLight, const Color(0x0D000000));
      expect(AppColors.paperLight, const Color(0xFF0F172A));
      expect(AppColors.mutedLight, const Color(0xFF64748B));

      // Functional Universal Accents
      expect(AppColors.inkGreen, const Color(0xFF10B981));
      expect(AppColors.penRed, const Color(0xFFF43F5E));
      expect(AppColors.amber, const Color(0xFFF59E0B));
      expect(AppColors.blueMesh, const Color(0x263B82F6));
    });

    test('AppSpacing metrics match layout standards', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);
      expect(AppSpacing.xxxl, 32.0);
    });

    test('AppRadius metrics match layout standards', () {
      expect(AppRadius.xs, 4.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 10.0);
      expect(AppRadius.card, 16.0);
      expect(AppRadius.lg, 20.0);
      expect(AppRadius.full, 999.0);
    });

    testWidgets('AppTypography hierarchy defines expected font weights and sizes', (tester) async {
      final eyebrow = AppTypography.eyebrow(Colors.white);
      expect(eyebrow.fontSize, 12.0);
      expect(eyebrow.fontWeight, FontWeight.w700);
      expect(eyebrow.letterSpacing, 1.0);

      final courseTitle = AppTypography.courseTitle(Colors.white);
      expect(courseTitle.fontSize, 26.0);
      expect(courseTitle.fontWeight, FontWeight.w800);
      expect(courseTitle.letterSpacing, -0.5);

      final statValue = AppTypography.statValue(Colors.white);
      expect(statValue.fontSize, 22.0);
      expect(statValue.fontWeight, FontWeight.w800);

      final statLabel = AppTypography.statLabel(Colors.white);
      expect(statLabel.fontSize, 14.0);
      expect(statLabel.fontWeight, FontWeight.w500);

      final cardTitle = AppTypography.cardTitle(Colors.white);
      expect(cardTitle.fontSize, 18.0);
      expect(cardTitle.fontWeight, FontWeight.w800);
    });
  });
}
