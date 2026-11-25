import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for typography using Google Fonts Outfit
abstract final class AppTypography {
  static TextStyle get outfitBase => GoogleFonts.outfit();

  static TextStyle get displayMedium =>
      GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700);

  static TextStyle get headlineSmall =>
      GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700);

  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  static TextStyle get labelLarge =>
      GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700);

  static TextStyle inputLabel(Color color) => GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle inputText(Color color) => GoogleFonts.outfit(
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle inputHint(Color color) => GoogleFonts.outfit(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle helperText(Color color) => GoogleFonts.outfit(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.45,
  );

  static TextStyle eyebrow(Color color) => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: color,
  );

  static TextStyle courseTitle(Color color) => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
    color: color,
  );

  static TextStyle cardTitle(Color color) => GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: color,
  );

  static TextStyle statValue(Color color) => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: color,
  );

  static TextStyle statLabel(Color color) => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle bodyLarge(Color color) => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: color,
  );

  static TextStyle bodyMedium(Color color) => GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color,
  );

  static TextStyle bodySmall(Color color) => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle navLabel(Color color) => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: color,
  );
}
