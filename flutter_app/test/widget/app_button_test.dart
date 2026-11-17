import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/shared/widgets/app_button.dart';

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

  group('AppButton Widget Tests', () {
    testWidgets('Renders label and triggers onPressed on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Submit',
          onPressed: () => tapped = true,
        ),
      ));

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('Renders icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Add Class',
          icon: const Icon(Icons.add, key: Key('add_icon')),
          onPressed: () {},
        ),
      ));

      expect(find.text('Add Class'), findsOneWidget);
      expect(find.byKey(const Key('add_icon')), findsOneWidget);
    });

    testWidgets('Disabled state prevents tap when onPressed is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppButton(
          label: 'Disabled',
          onPressed: null,
        ),
      ));

      expect(find.text('Disabled'), findsOneWidget);
      final inkWellFinder = find.byType(InkWell);
      final InkWell inkWell = tester.widget(inkWellFinder);
      expect(inkWell.onTap, isNull);
    });

    testWidgets('Loading state displays CircularProgressIndicator and disables tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Saving...',
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving...'), findsNothing);

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('Renders all 4 button variants', (tester) async {
      await tester.pumpWidget(_wrap(
        Column(
          children: [
            AppButton.present(label: 'Present', onPressed: () {}),
            AppButton.absent(label: 'Absent', onPressed: () {}),
            AppButton.ghost(label: 'Ghost', onPressed: () {}),
            AppButton.clear(label: 'Clear', onPressed: () {}),
          ],
        ),
      ));

      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('isWide expands button to parent constraints', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 300,
          child: AppButton(
            label: 'Full Width',
            isWide: true,
            onPressed: () {},
          ),
        ),
      ));

      final size = tester.getSize(find.byType(AppButton));
      expect(size.width, 300.0);
    });
  });
}
