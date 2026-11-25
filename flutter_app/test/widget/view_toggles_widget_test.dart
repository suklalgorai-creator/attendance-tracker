import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/shared/widgets/view_toggles_widget.dart';

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

  group('ViewTogglesWidget Tests', () {
    testWidgets('Renders all three modes: WEEK, MONTH, ALL', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ViewTogglesWidget(
            currentMode: RegisterViewMode.week,
            onModeChanged: (_) {},
          ),
        ),
      );

      expect(find.text('WEEK'), findsOneWidget);
      expect(find.text('MONTH'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
    });

    testWidgets('Tapping segment invokes onModeChanged callback', (
      tester,
    ) async {
      RegisterViewMode? selected;
      await tester.pumpWidget(
        _wrap(
          ViewTogglesWidget(
            currentMode: RegisterViewMode.week,
            onModeChanged: (mode) => selected = mode,
          ),
        ),
      );

      await tester.tap(find.text('MONTH'));
      await tester.pump();
      expect(selected, RegisterViewMode.month);

      await tester.tap(find.text('ALL'));
      await tester.pump();
      expect(selected, RegisterViewMode.all);
    });

    testWidgets('Active mode renders with distinct surface shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ViewTogglesWidget(
            currentMode: RegisterViewMode.month,
            onModeChanged: (_) {},
          ),
        ),
      );

      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      // Second container corresponds to 'Month'
      final activeContainer = containers[1];
      final deco = activeContainer.decoration as BoxDecoration;
      expect(deco.boxShadow, isNotNull);
      expect(deco.boxShadow!.isNotEmpty, isTrue);

      // Inactive container (Week) has no box shadow
      final inactiveContainer = containers[0];
      final inactiveDeco = inactiveContainer.decoration as BoxDecoration;
      expect(inactiveDeco.boxShadow, isNull);
    });
  });
}
