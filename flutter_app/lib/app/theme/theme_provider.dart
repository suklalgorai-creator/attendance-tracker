import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod state notifier managing Light / Dark theme preference.
///
/// Ownership: App Theme
// ==========================================
// THEME PROVIDER - Dark/Light Mode State
// Defaults to dark mode matching the React reference implementation.
// ==========================================
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier([super.state = ThemeMode.dark]);

  void toggleTheme() {
    state = (state == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// Riverpod provider for application theme mode.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ThemeMode.dark);
});
