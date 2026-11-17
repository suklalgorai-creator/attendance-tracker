import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/shared/widgets/app_banner.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) {
  return MaterialApp(
    themeMode: mode,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppBanner Widget Tests', () {
    testWidgets('Renders all four variants with respective messages', (tester) async {
      await tester.pumpWidget(_wrap(
        const Column(
          children: [
            AppBanner.safe(message: 'Attendance is above target!'),
            AppBanner.danger(message: 'Attendance is below target!'),
            AppBanner.neutral(message: 'Neutral info message'),
            AppBanner.reminder(message: 'Reminder to mark attendance'),
          ],
        ),
      ));

      expect(find.text('Attendance is above target!'), findsOneWidget);
      expect(find.text('Attendance is below target!'), findsOneWidget);
      expect(find.text('Neutral info message'), findsOneWidget);
      expect(find.text('Reminder to mark attendance'), findsOneWidget);
    });

    testWidgets('Renders title, leading, and action widgets', (tester) async {
      bool actionClicked = false;
      await tester.pumpWidget(_wrap(
        AppBanner.danger(
          title: 'Pending attendance',
          message: '3 scheduled past sessions need marking.',
          leading: const Text('⏰', key: Key('banner_alarm')),
          action: ElevatedButton(
            key: const Key('banner_action'),
            onPressed: () => actionClicked = true,
            child: const Text('Review'),
          ),
        ),
      ));

      expect(find.text('Pending attendance'), findsOneWidget);
      expect(find.text('3 scheduled past sessions need marking.'), findsOneWidget);
      expect(find.byKey(const Key('banner_alarm')), findsOneWidget);
      expect(find.byKey(const Key('banner_action')), findsOneWidget);

      await tester.tap(find.byKey(const Key('banner_action')));
      await tester.pump();
      expect(actionClicked, isTrue);
    });

    testWidgets('Tapping interactive banner fires onTap callback', (tester) async {
      bool bannerTapped = false;
      await tester.pumpWidget(_wrap(
        AppBanner(
          type: AppBannerType.reminder,
          message: 'Tap here to Sign in',
          onTap: () => bannerTapped = true,
        ),
      ));

      await tester.tap(find.text('Tap here to Sign in'));
      await tester.pump();
      expect(bannerTapped, isTrue);
    });

    testWidgets('Renders custom child widget', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppBanner(
          child: Text('Custom Content Child', key: Key('custom_child')),
        ),
      ));

      expect(find.byKey(const Key('custom_child')), findsOneWidget);
      expect(find.text('Custom Content Child'), findsOneWidget);
    });
  });
}
