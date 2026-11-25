import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/empty_dashboard_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('EmptyDashboardView Widget Tests', () {
    testWidgets('Renders empty state copy and school icon', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyDashboardView()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.text('No subjects added yet'), findsOneWidget);
      expect(
        find.text(
          'Add your enrolled subjects to start logging attendance and tracking safe bunks.',
        ),
        findsOneWidget,
      );
      expect(find.text('+ Add Subject'), findsNothing);
    });

    testWidgets(
      'Renders + Add Subject button when onAddSubject is supplied and handles tap',
      (tester) async {
        var addTapped = false;
        await tester.pumpWidget(
          _wrap(EmptyDashboardView(onAddSubject: () => addTapped = true)),
        );
        await tester.pumpAndSettle();

        expect(find.text('+ Add Subject'), findsOneWidget);

        await tester.tap(find.text('+ Add Subject'));
        await tester.pumpAndSettle();

        expect(addTapped, isTrue);
      },
    );
  });
}
