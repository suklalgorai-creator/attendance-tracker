import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier managing the application's active theme mode.
/// Defaults to [ThemeMode.dark] matching the React reference application.
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
