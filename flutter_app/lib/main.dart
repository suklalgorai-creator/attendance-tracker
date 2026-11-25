import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';

void main() async {
  try {
    debugPrint('[MAIN] Starting bootstrap...');
    await bootstrap();
    debugPrint('[MAIN] Bootstrap complete, launching app...');
    runApp(const ProviderScope(child: AttendanceApp()));
    debugPrint('[MAIN] runApp called successfully');
  } catch (e, stack) {
    debugPrint('[MAIN] FATAL ERROR: $e');
    debugPrint('[MAIN] STACK: $stack');
    // Show a minimal error app so the window is visible
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Startup Error: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
