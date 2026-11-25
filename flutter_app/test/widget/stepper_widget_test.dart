import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/shared/widgets/stepper_widget.dart';

void main() {
  Widget buildTestableWidget({
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
    int max = 99,
    bool enabled = true,
    Brightness brightness = Brightness.dark,
  }) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Center(
          child: StepperWidget(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  group('StepperWidget', () {
    testWidgets('renders initial value and buttons', (tester) async {
      await tester.pumpWidget(buildTestableWidget(value: 5, onChanged: (_) {}));

      expect(find.text('5'), findsOneWidget);
      expect(find.text('−'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
    });

    testWidgets('tapping increase calls onChanged with value + 1', (
      tester,
    ) async {
      int? updatedValue;
      await tester.pumpWidget(
        buildTestableWidget(value: 5, onChanged: (val) => updatedValue = val),
      );

      await tester.tap(find.text('+'));
      await tester.pump();

      expect(updatedValue, equals(6));
    });

    testWidgets('tapping decrease calls onChanged with value - 1', (
      tester,
    ) async {
      int? updatedValue;
      await tester.pumpWidget(
        buildTestableWidget(value: 5, onChanged: (val) => updatedValue = val),
      );

      await tester.tap(find.text('−'));
      await tester.pump();

      expect(updatedValue, equals(4));
    });

    testWidgets('tapping decrease at min does not decrease below min', (
      tester,
    ) async {
      int? updatedValue;
      await tester.pumpWidget(
        buildTestableWidget(
          value: 0,
          min: 0,
          onChanged: (val) => updatedValue = val,
        ),
      );

      await tester.tap(find.text('−'));
      await tester.pump();

      expect(updatedValue, anyOf(isNull, equals(0)));
    });

    testWidgets('tapping increase at max does not increase above max', (
      tester,
    ) async {
      int? updatedValue;
      await tester.pumpWidget(
        buildTestableWidget(
          value: 99,
          max: 99,
          onChanged: (val) => updatedValue = val,
        ),
      );

      await tester.tap(find.text('+'));
      await tester.pump();

      expect(updatedValue, anyOf(isNull, equals(99)));
    });

    testWidgets('when enabled=false, buttons do not fire callbacks', (
      tester,
    ) async {
      int? updatedValue;
      await tester.pumpWidget(
        buildTestableWidget(
          value: 5,
          enabled: false,
          onChanged: (val) => updatedValue = val,
        ),
      );

      await tester.tap(find.text('+'));
      await tester.pump();
      expect(updatedValue, isNull);

      await tester.tap(find.text('−'));
      await tester.pump();
      expect(updatedValue, isNull);
    });

    testWidgets('renders correctly in light and dark themes without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          value: 12,
          onChanged: (_) {},
          brightness: Brightness.light,
        ),
      );
      expect(find.text('12'), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          value: 12,
          onChanged: (_) {},
          brightness: Brightness.dark,
        ),
      );
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('does not overflow on narrow 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(value: 42, onChanged: (_) {}),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('42'), findsOneWidget);
    });
  });
}
