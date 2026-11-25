import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shared hex color parsing utilities across subjects, notes, and timetable UI.
///
/// Ownership: Core Utilities
// ==========================================
// CORE UTILS - Hex Color Parsing
// Parses 6-digit or 8-digit hex strings safely with configurable fallback.
// ==========================================

/// Parses a `#RRGGBB`, `RRGGBB`, `#AARRGGBB`, or `AARRGGBB` string into a [Color].
///
/// Returns [fallback] when [hex] is empty or malformed.
Color parseHexColor(String hex, {Color fallback = AppColors.inkGreen}) {
  try {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
  } catch (_) {}
  return fallback;
}
