import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/features/splash/presentation/pages/splash_page.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createSplashRouterApp() {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Home Target'))),
        ),
      ],
    );

    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }

  group('SplashPage Widget Tests', () {
    testWidgets(
      'Renders logo, title, tagline and navigates to / after animation',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createSplashRouterApp());
        await tester.pump();

        expect(find.text('My Attendance'), findsOneWidget);
        expect(find.text('Track · Plan · Succeed'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance past 200ms + 400ms + 1200ms splash delays
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();

        expect(find.text('Home Target'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders cleanly on compact 320x568 viewport without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createSplashRouterApp());
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        expect(find.text('My Attendance'), findsOneWidget);

        // Drain remaining timer
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();
      },
    );
  });
}
