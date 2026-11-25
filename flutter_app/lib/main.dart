import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';

/// Application entrypoint bootstrapping core services and launching [AttendanceApp].
///
/// Ownership: App Root
// ==========================================
// APP ROOT - Entry Point
// ==========================================
void main() async {
  try {
    if (kDebugMode) debugPrint('[MAIN] Starting bootstrap...');
    await bootstrap();
    if (kDebugMode) debugPrint('[MAIN] Bootstrap complete, launching app...');
    runApp(const ProviderScope(child: AttendanceApp()));
    if (kDebugMode) debugPrint('[MAIN] runApp called successfully');
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('[MAIN] FATAL ERROR: $e');
      debugPrint('[MAIN] STACK: $stack');
    }
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
