import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for typography using Google Fonts Outfit
abstract final class AppTypography {
  static TextStyle get outfitBase => GoogleFonts.outfit();

  static TextStyle eyebrow(Color color) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color,
      );

  static TextStyle courseTitle(Color color) => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle cardTitle(Color color) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle statValue(Color color) => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle statLabel(Color color) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodyLarge(Color color) => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall(Color color) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle navLabel(Color color) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
