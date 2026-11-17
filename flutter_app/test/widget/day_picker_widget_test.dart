import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/shared/widgets/day_picker_widget.dart';

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

  group('DayPickerWidget Tests', () {
    testWidgets('Renders all 7 day chips', (tester) async {
      await tester.pumpWidget(_wrap(
        DayPickerWidget(
          selectedDays: const [1, 2, 3, 4, 5],
          onDaysChanged: (_) {},
        ),
      ));

      expect(find.byType(DayPickerWidget), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(7));
      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('Tapping unselected chip adds day index and triggers onDaysChanged with sorted list', (tester) async {
      List<int>? updatedDays;
      await tester.pumpWidget(_wrap(
        DayPickerWidget(
          selectedDays: const [1, 2, 3, 4, 5], // Mon-Fri
          onDaysChanged: (days) => updatedDays = days,
        ),
      ));

      // Sun is index 0 (first chip)
      final sunChip = find.byType(InkWell).first;
      await tester.tap(sunChip);
      await tester.pump();

      expect(updatedDays, [0, 1, 2, 3, 4, 5]);
    });

    testWidgets('Tapping selected chip removes day index and triggers onDaysChanged', (tester) async {
      List<int>? updatedDays;
      await tester.pumpWidget(_wrap(
        DayPickerWidget(
          selectedDays: const [1, 2, 3, 4, 5], // Mon-Fri
          onDaysChanged: (days) => updatedDays = days,
        ),
      ));

      // Monday is index 1 (second chip)
      final monChip = find.byType(InkWell).at(1);
      await tester.tap(monChip);
      await tester.pump();

      expect(updatedDays, [2, 3, 4, 5]);
    });

    testWidgets('Disabled state prevents any selection changes', (tester) async {
      List<int>? updatedDays;
      await tester.pumpWidget(_wrap(
        DayPickerWidget(
          selectedDays: const [1, 2, 3, 4, 5],
          enabled: false,
          onDaysChanged: (days) => updatedDays = days,
        ),
      ));

      final monChip = find.byType(InkWell).at(1);
      await tester.tap(monChip);
      await tester.pump();

      expect(updatedDays, isNull);
    });

    testWidgets('Renders responsively without overflow in narrow constraints', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 250, // narrow screen constraint
          child: DayPickerWidget(
            selectedDays: const [1, 2, 3, 4, 5],
            onDaysChanged: (_) {},
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.byType(FittedBox), findsOneWidget);
    });
  });
}
