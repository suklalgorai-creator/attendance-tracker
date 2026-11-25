import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/shared/widgets/app_text_field.dart';

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

  group('AppTextField Widget Tests', () {
    testWidgets('Renders label and hint text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppTextField(label: 'Subject Name', hint: 'e.g. Mathematics'),
        ),
      );

      expect(find.text('Subject Name'), findsOneWidget);
      expect(find.text('e.g. Mathematics'), findsOneWidget);
    });

    testWidgets('Entering text triggers onChanged callback', (tester) async {
      String changedValue = '';
      await tester.pumpWidget(
        _wrap(
          AppTextField(label: 'Course', onChanged: (val) => changedValue = val),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Physics 101');
      await tester.pump();
      expect(changedValue, 'Physics 101');
    });

    testWidgets('Submitting text triggers onSubmitted callback', (
      tester,
    ) async {
      String submittedValue = '';
      await tester.pumpWidget(
        _wrap(
          AppTextField(
            label: 'Goal',
            onSubmitted: (val) => submittedValue = val,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Target 80%');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submittedValue, 'Target 80%');
    });

    testWidgets('Displays errorText with red error styling when present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppTextField(
            label: 'Attendance',
            errorText: 'Attendance cannot be negative',
          ),
        ),
      );

      expect(find.text('Attendance cannot be negative'), findsOneWidget);
      final animatedContainerFinder = find.byType(AnimatedContainer);
      final AnimatedContainer container = tester.widget(
        animatedContainerFinder,
      );
      final boxDeco = container.decoration as BoxDecoration;
      final border = boxDeco.border as Border;
      expect(border.top.color, AppColors.penRed);
    });

    testWidgets('Focusing input applies amber border and halo', (tester) async {
      final focusNode = FocusNode();
      await tester.pumpWidget(
        _wrap(AppTextField(label: 'Email', focusNode: focusNode)),
      );

      // Initial unfocused state
      var container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      var boxDeco = container.decoration as BoxDecoration;
      expect(boxDeco.boxShadow, isNull);

      // Focus the field
      focusNode.requestFocus();
      await tester.pump();

      container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      boxDeco = container.decoration as BoxDecoration;
      expect(boxDeco.boxShadow, isNotNull);
      expect(boxDeco.boxShadow!.first.color, AppColors.amberSoft);
      final border = boxDeco.border as Border;
      expect(border.top.color, AppColors.amber);

      focusNode.dispose();
    });

    testWidgets('Displays helperText when provided without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppTextField(
            label: 'Minimum Percent',
            helperText: 'Recommended is 75%',
          ),
        ),
      );

      expect(find.text('Recommended is 75%'), findsOneWidget);
    });

    testWidgets('Prefix and suffix icons are rendered', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppTextField(
            label: 'Search',
            prefixIcon: Icon(Icons.search, key: Key('prefix_search')),
            suffixIcon: Icon(Icons.clear, key: Key('suffix_clear')),
          ),
        ),
      );

      expect(find.byKey(const Key('prefix_search')), findsOneWidget);
      expect(find.byKey(const Key('suffix_clear')), findsOneWidget);
    });
  });
}
