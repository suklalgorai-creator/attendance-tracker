import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/shared/widgets/streak_popup_dialog.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('StreakPopupDialog Tests', () {
    testWidgets(
      'Renders 🔥 emoji, title with streak count, desc, and Awesome button',
      (tester) async {
        await tester.pumpWidget(_wrap(const StreakPopupDialog(streak: 7)));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('🔥'), findsOneWidget);
        expect(find.text('7 Day Streak!'), findsOneWidget);
        expect(
          find.text(
            "You're on fire! Keep attending classes to maintain your streak.",
          ),
          findsOneWidget,
        );
        expect(find.text('Awesome'), findsOneWidget);
      },
    );

    testWidgets('Tapping Awesome button invokes onClose callback', (
      tester,
    ) async {
      bool closed = false;
      await tester.pumpWidget(
        _wrap(StreakPopupDialog(streak: 5, onClose: () => closed = true)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Awesome'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(closed, isTrue);
    });

    testWidgets(
      'showStreakDialog helper launches dialog in overlay and closes on button tap',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showStreakDialog(context, streak: 12),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump(
          const Duration(milliseconds: 450),
        ); // Advance transition

        expect(find.text('12 Day Streak!'), findsOneWidget);
        expect(find.text('Awesome'), findsOneWidget);

        await tester.tap(find.text('Awesome'));
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('12 Day Streak!'), findsNothing);
      },
    );
  });
}
