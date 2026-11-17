import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/app/theme/theme_provider.dart';

void main() {
  group('ThemeModeNotifier Unit Tests', () {
    test('Initial theme mode is ThemeMode.dark matching React default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialMode = container.read(themeModeProvider);
      expect(initialMode, ThemeMode.dark);
    });

    test('toggleTheme switches state from dark to light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.toggleTheme();

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('toggleTheme twice returns state to dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.toggleTheme();
      notifier.toggleTheme();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setThemeMode explicitly updates state to ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      notifier.setThemeMode(ThemeMode.system);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });
}
