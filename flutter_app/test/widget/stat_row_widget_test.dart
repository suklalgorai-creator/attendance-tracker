import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/shared/widgets/stat_row_widget.dart';

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

  group('StatRowWidget Tests', () {
    testWidgets('Renders uppercase label and normal value', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatRowWidget(label: 'Conducted', value: '42')),
      );
      expect(find.text('CONDUCTED'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('Renders safe and danger colored values', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              StatRowWidget.safe(label: 'Present', value: '38'),
              StatRowWidget.danger(label: 'Status', value: 'Danger Zone'),
            ],
          ),
        ),
      );

      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('38'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('Danger Zone'), findsOneWidget);

      final Text presentText = tester.widget(find.text('38'));
      expect(presentText.style?.color, AppColors.inkGreen);

      final Text dangerText = tester.widget(find.text('Danger Zone'));
      expect(dangerText.style?.color, AppColors.penRed);
    });

    testWidgets('Applies status-text 15px font size when isStatus is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StatRowWidget(
            label: 'Status',
            value: 'Can miss 3 classes',
            isStatus: true,
          ),
        ),
      );
      final Text statusText = tester.widget(find.text('Can miss 3 classes'));
      expect(statusText.style?.fontSize, 15.0);
    });

    testWidgets('Omit dashed divider when isLast is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StatRowWidget(label: 'Last Stat', value: '100%', isLast: true),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(StatRowWidget),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('Renders dashed divider when isLast is false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StatRowWidget(
            label: 'Middle Stat',
            value: '50%',
            isLast: false,
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(StatRowWidget),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StatRowWidget(
            label: 'Rank',
            value: '#1',
            trailing: Icon(Icons.star, key: Key('star_icon')),
          ),
        ),
      );
      expect(find.byKey(const Key('star_icon')), findsOneWidget);
    });

    testWidgets(
      'Renders descriptive label with 30+ characters in 360px width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: StatRowWidget(
                  label: 'Minimum Attendance Requirement',
                  value: '75%',
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('MINIMUM ATTENDANCE REQUIREMENT'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
      },
    );
  });
}
