import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

/// Central application theme configuration providing Dark and Light ThemeData
/// using Google Fonts Outfit and exact design tokens.
abstract final class AppTheme {
  /// Dark Theme (Default)
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final outfitTextTheme = GoogleFonts.outfitTextTheme(baseTextTheme).apply(
      bodyColor: AppColors.paperDark,
      displayColor: AppColors.paperDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimaryDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.inkGreen,
        onPrimary: Colors.white,
        secondary: AppColors.amber,
        onSecondary: Colors.black,
        error: AppColors.penRed,
        onError: Colors.white,
        surface: AppColors.surfaceSolidDark,
        onSurface: AppColors.paperDark,
      ),
      textTheme: outfitTextTheme,
      cardTheme: CardThemeData(
        color: AppColors.surfaceSolidDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.glassBorderDark, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.paperDark),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceSolidDark,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.ruleBrightDark,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Light Theme
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final outfitTextTheme = GoogleFonts.outfitTextTheme(baseTextTheme).apply(
      bodyColor: AppColors.paperLight,
      displayColor: AppColors.paperLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgPrimaryLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.inkGreen,
        onPrimary: Colors.white,
        secondary: AppColors.amber,
        onSecondary: Colors.black,
        error: AppColors.penRed,
        onError: Colors.white,
        surface: AppColors.surfaceSolidLight,
        onSurface: AppColors.paperLight,
      ),
      textTheme: outfitTextTheme,
      cardTheme: CardThemeData(
        color: AppColors.surfaceSolidLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.glassBorderLight, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.paperLight),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceSolidLight,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.ruleBrightLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
